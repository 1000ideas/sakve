module Sakve::FormHelper
  def custom_check_box(object_name, method, options = {}, cvalue = '1', ucvalue = '0')
    label(object_name, method) do
      [
        check_box(object_name, method, options, cvalue, ucvalue),
        content_tag(:i)
      ].join.html_safe
    end
  end

  module FormBuilder
    def select_box(method, item, options = {})
      plural_name = method.to_s.pluralize
      options.merge!(multiple: true)
      label("#{plural_name}_#{item.send(method)}", class: :'custom-check-box') do
        [
          check_box(plural_name, options, item.send(method), nil),
          @template.content_tag(:i)
        ].join.html_safe
      end
    end
  end

end

ActionView::Helpers::FormBuilder.send(:include, Sakve::FormHelper::FormBuilder)
ActionView::Helpers::FormHelper.send(:include, Sakve::FormHelper)
