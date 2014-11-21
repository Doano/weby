module DateHelper
  def print_date_end(date, format = :short)
    return  t('infinite') if date.nil?
    l(date, format: format)
  end

  # Receives an object (Page, Banner) and verifies if the publication's date has expired
  # Returns toggle_field if not expired otherwise returns "Expired"
  def publication_status(obj, _options = {})
    case obj
    when Page
      publication_status_page(obj, options = {})
    when Journal::News
      publication_status_news(obj, options = {})
    end
  end

  def publication_status_page(page, options = {})
    ''.tap do |html|
      html << toggle_field(page, 'publish', 'toggle', options)
    end.html_safe
  end
  private :publication_status_page

  def publication_status_news(news, options = {})
    ''.tap do |html|
      html << toggle_field(news, 'publish', 'toggle', options)
      html << "<span class=\"label label-warning publish-warning\" title=\"#{t('scheduled', date: l(news.date_begin_at, format: :short))}\">!</span>" if news.date_begin_at and Time.now < news.date_begin_at and news.publish
    end.html_safe
  end
  private :publication_status_news

  def front_status(page, options = {})
    ''.tap do |html|
      html << toggle_field(page, 'front', 'toggle', options)
      html << "<span class=\"label label-important publish-warning\" title=\"#{t('expired')}\">!</span>" if page.date_end_at and page.front and page.date_end_at <= Time.now
    end.html_safe
  end

  def map_months_from_date(end_date)
    end_date ||= Time.now
    months, curr_date = [], Time.now
    while curr_date.beginning_of_month >= end_date.beginning_of_month
      months << [l(curr_date.to_date, format: :monthly), curr_date.strftime('%m/%Y')] # TODO use a block for cutsom format
      curr_date -= 1.month
    end
    [Time.now.year.downto(end_date.year).to_a, months]
  end
end
