# Product names shown to users. Internal names (engines, tables, classes) stay as they are; see docs/glossary.md.
module BrandHelper
  def module_label(key, attribute = :name) = I18n.t("modules.#{key}.#{attribute}", locale: :'pt-BR')
end
