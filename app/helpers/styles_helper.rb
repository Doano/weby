module StylesHelper
  def style_menu(style)
    ''.tap do |html|
      copy_link = link_to(icon('hdd', text: t('copy')), copy_site_admin_skin_style_path(style.skin_id, style), method: :put)
      if style.site == current_site
        if style.style_id
          html << link_to(icon('star', text: t('unfollow')), unfollow_site_admin_skin_style_path(style.skin_id, style), method: :put) if test_permission(controller_name, 'unfollow')
          html << copy_link if test_permission(controller_name, 'copy')
        else
          html << make_menu(style, except: 'show', controller: Sites::Admin::StylesController, params: {skin_id: style.skin_id})
        end
      else
        html << link_to(icon('star', text: t('follow')), follow_site_admin_skin_style_path(style.skin_id, style), method: :put) if test_permission(controller_name, 'follow')
        html << copy_link if test_permission(controller_name, 'copy')
      end
    end.html_safe
  end
end
