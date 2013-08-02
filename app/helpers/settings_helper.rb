module SettingsHelper

  def setting_input_tag setting
    name = 'settings[][value]'
    disabled = setting.new_record?
    data = {disabledtext: setting.default_value}
    "<div class=\"input-append setting-input\">".tap do |html|
      if (pattern = Setting::VALUES_SET[setting.name.to_sym])
        case pattern
        when Array
          html << select_tag(name, options_for_select(pattern, setting.value), class: 'setting-field select', data: data, disabled: disabled)
        when Symbol
          case pattern
          when :numericality
            html << number_field_tag(name, setting.value, class: "setting-field numeric", data: data, disabled: disabled)
          else
            html << text_field_tag(name, setting.value, class: "setting-field string", data: data, disabled: disabled)
          end
        else
          html << text_field_tag(name, setting.value, class: "setting-field string", data: data, disabled: disabled, pattern: pattern)
        end
      else
        html << text_field_tag(name, setting.value, class: "setting-field string", data: data, disabled: disabled)
      end
      html << content_tag(:span, class: 'add-on') do
          check_box_tag('settings[][enabled]', true, !disabled)
      end
      html << "</div>"
    end.html_safe
  end
end
