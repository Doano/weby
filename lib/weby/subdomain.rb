module Weby
  class Subdomain
    include ActionDispatch::Http::URL

    def self.matches?(request)
      settings = Weby::Settings::Weby
      @site_domain = nil
      subdomain = request.subdomain.gsub(/www\./, '')

      @@tld_length = settings.tld_length.to_i

      if request.subdomain.present? && request.subdomain != 'www'
        if settings.sites_index.present?
          return false if subdomain == settings.sites_index
        end
        @site_domain = subdomain and return true
      else
        @site_domain = Weby::Settings::Weby.root_site and return true if Weby::Settings::Weby.root_site.present?
      end
    end

    def self.site_id
      @site_domain
    end

    def self.find_site(domain = nil)
      domain = @site_domain unless domain
      domain = domain.gsub(/www\./, '')
      sites = domain.split('.')
      site = Site.where(parent_id: nil).find_by_name(sites[-1])
      if sites.length == 2
        site = site.subsites.find_by_name(sites[-2]) if site
      end
      site if [1, 2].include? sites.length
    end
  end
end
