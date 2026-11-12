# Inject Placar de Domingo classes into Formtastic inputs/actions used by ActiveAdmin.
module FormtasticPlacar
  module InputHtml
    def input_html_options
      options = super
      options[:class] = Array(options[:class]) + AdminHelper::ADMIN_INPUT_CLASSES.split
      options
    end
  end

  module LabelHtml
    def label_html_options
      options = super
      options[:class] = Array(options[:class]) + AdminHelper::ADMIN_LABEL_CLASSES.split
      options
    end
  end

  module ButtonHtml
    def default_button_html
      super.merge(class: AdminHelper::ADMIN_BUTTON_CLASSES.split)
    end
  end
end

Rails.application.config.to_prepare do
  Formtastic::Inputs::Base::Html.prepend(FormtasticPlacar::InputHtml)
  Formtastic::Inputs::Base::Labelling.prepend(FormtasticPlacar::LabelHtml)
  Formtastic::Actions::Base.prepend(FormtasticPlacar::ButtonHtml)
end
