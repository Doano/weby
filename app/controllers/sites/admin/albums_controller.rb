class Sites::Admin::AlbumsController < ApplicationController
  include ActsToToggle

  before_action :require_user
  before_action :check_authorization
  before_action :find_album, only: [:show, :edit, :update, :destroy, :photos]

  helper_method :sort_column

  respond_to :html, :js, :json, :rss

  def index
    @albums = (params[:album_tag].present? ? current_site.album_tags.find(params[:album_tag]) : current_site).albums.
      with_search(params[:search], 1).
      order(sort_column + ' ' + sort_direction).
      page(params[:page]).per(params[:per_page])

    if params[:begin_at].present? || params[:end_at].present?
      begin_at = Time.zone.parse(params[:begin_at].present? ? params[:begin_at] : '2000-01-01')
      end_at = params[:end_at].present? ? Time.zone.parse(params[:end_at]) : Time.current
      @albums = @albums.where("albums.created_at BETWEEN ? AND ?",
        begin_at.beginning_of_day,
        end_at.end_of_day)
    end

    respond_with(:site_admin, @albums) do |format|
      if params[:template]
        format.js { render "#{params[:template]}" }
        format.html { render partial: "#{params[:template]}", layout: false }
      end
    end
  end

  def sort_column
    params[:sort] || 'pages.id'
  end
  private :sort_column

  def show
    @album = @album.in(params[:show_locale])
  end

  def new
    @album = current_site.albums.new(publish: true)
    @album.build_cover_photo
  end

  def edit
    @album.build_cover_photo if !@album.cover_photo
  end

  def photos
    @album_photo = AlbumPhoto.new
  end

  def create
    @album = current_site.albums.new(album_params)
    @album.user = current_user
    @album.cover_photo.user = current_user if @album.cover_photo.present?
    if @album.save
      record_activity('created_album', @album)
      respond_with(:photos, :site_admin, @album)
    else
      @album.build_cover_photo
      respond_with(:site_admin, @album)
    end
  end

  def update
    if @album.update(album_params)
      record_activity('updated_album', @album)
    end
    respond_with(:site_admin, @album)
  end

  def destroy
    if @album.destroy
      record_activity('destroyed_album', @album)
      flash[:success] = t('successfully_deleted')
    else
      flash[:error] = @album.errors.full_messages.join(', ')
    end

    redirect_to site_admin_albums_path
  end

  def destroy_many
    albums = current_site.albums.where(id: params[:ids].split(',')).each do |album|
      if album.destroy
        record_activity('destroyed_album', album)
        flash[:success] = t('successfully_deleted')
      end
    end
    redirect_back(fallback_location: site_admin_albums_path)
  end

  def generate
    require 'zip/zip'
    require 'find'
    require 'fileutils'

    s = current_site
    h = { include: {} }
    h[:include][:pages] = { include: [:i18ns, :related_files] } if params[:pages]
    h[:include][:own_news] = { include: { i18ns: {}, related_files: {}, own_news_site: {include: :categories} } } if params[:news]
    #h[:include][:news_sites] = { include: [:categories ] } if params[:news]
    h[:include][:events] = { include: [:categories, :i18ns, :related_files] } if params[:events]
    h[:include][:repositories] = {}  if params[:repositories]
    h[:include][:own_banners] = { include: { own_banner_site: {include: :categories} } } if params[:banners]
    h[:include][:menus] = { include: :root_menu_items } if params[:menus]
    #h[:include][:styles] = {}  if params[:styles]
    #h[:include][:root_components] = {}  if params[:root_components]
    h[:include][:skins] = { include: [:styles, :root_components] } if params[:themes]
    h[:include][:extensions] = {}  if params[:extensions]
    h[:include][:locales] = {}  if params[:locales]
    h[:include][:messages] = {} if params[:messages]

    dir = "tmp/#{s.id}"
    Dir.mkdir("#{dir}") unless Dir.exist?("#{dir}")

    FileUtils.rm_r Dir.glob("#{dir}/*")

    if params[:type] == 'JSON'
      File.open(Rails.root.join(dir, "#{s.name}.json"), 'wb') do |file|
        file.write s.to_json(h)
      end
      filename = "#{dir}/#{s.name}.json"
    else
      File.open(Rails.root.join(dir, "#{s.name}.xml"), 'wb') do |file|
        file.write s.to_xml(h)
      end
      filename = "#{dir}/#{s.name}.xml"
    end

    zipname = "#{s.name}_#{params[:type].downcase}.zip"
    zip_dir = Rails.root.join(dir, zipname)
    Zip::ZipFile.open(zip_dir, Zip::ZipFile::CREATE) do |zipfile|
      read_files_for_zip(s).each do |file, entry_path|
        begin
          if file.is_a?(String)
            zipfile.add(entry_path, file) if entry_path
          elsif file.is_a?(Aws::S3::Object)
            zipfile.get_output_stream(entry_path) do |f|
              f.write(file.get.body.read)
            end
          end
        rescue Zip::ZipEntryExistsError
        end
      end if params[:repositories] && params[:files]
      dest = /#{dir}\/(\w.*)/.match(filename)
      zipfile.add(dest[1], filename) if dest
    end

    zip_data = File.read("#{dir}/#{zipname}")
    send_data(zip_data, type: 'application/zip', filename: zipname)
  end

  # def recover
  #   @page = current_site.pages.trashed.find(params[:id])
  #   if @page.untrash
  #     flash[:success] = t('successfully_restored')
  #   end
  #   record_activity('restored_page', @page)
  #   redirect_back(fallback_location: recycle_bin_site_admin_pages_path)
  # end

  # def empty_bin
  #   if current_site.pages.trashed.destroy_all
  #     flash[:success] = t('successfully_deleted')
  #   end
  #   redirect_to main_app.recycle_bin_site_admin_pages_path
  # end

  private

  def sort_column
    params[:sort] || 'albums.id'
  end

  def album_params
    params.require(:album).permit(:publish, :slug, :category_list, :video_url,
                                 { i18ns_attributes: [:id, :locale_id, :title, :text, :_destroy], album_tag_ids: [], cover_photo_attributes: [:id, :image]})
  end
end
