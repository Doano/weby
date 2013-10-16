module Feedback::Admin
  class GroupsController < Feedback::ApplicationController
    before_filter :require_user
    before_filter :check_authorization
    respond_to :html, :js

    helper_method :sort_column

    def index
      @groups = Feedback::Group.where(site_id: current_site.id).scoped.not_deleted.order(sort_column + ' ' + sort_direction).
        page(params[:page]).per(params[:per_page])
    end

    def show
      @group = Feedback::Group.find(params[:id])
    end

    def new
      @group = Feedback::Group.new
      #@users = User.by_site(@site)
    end

    def edit
      @group = Feedback::Group.find(params[:id])
      #@users = User.by_site(@site)
    end

    def create
      @group = Feedback::Group.new(params[:group])

      if @group.save
        redirect_to({:site_id => @group.site.name, :controller => 'groups'},
                    flash: {success: t('successfully_created')})
      else
        respond_with(:site_admin, @group)
      end
    end

    def update
      @group = Feedback::Group.find(params[:id])
      if @group.update_attributes(params[:group])
        redirect_to({:site_id => @group.site.name, :controller => 'groups', :action => 'index'},
                    flash: {success: t("successfully_updated")})
      else
        respond_with(:site_admin, @group)
      end
    end

    def destroy
      @group = Feedback::Group.find(params[:id])
      @group.destroy

      redirect_to(admin_groups_url)
    end

    def remove                                 
      @group = Feedback::Group.find(params[:id])
      @group.update_attributes(deleted: true)
                                                     
      redirect_to(admin_groups_url)
    end                                        
                                               
    def recover                                
      @group = Feedback::Group.find(params[:id])
      @group.update_attributes(deleted: false)
                                                     
      redirect_to(admin_groups_url)
    end

    private
    def sort_column
      Feedback::Group.column_names.include?(params[:sort]) ? params[:sort] : 'id'
    end
  end
end
