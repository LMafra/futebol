# Product names shown to users. Internal names (engines, tables, classes) stay as they are; see docs/glossary.md.
module BrandHelper
  def brand(attribute) = I18n.t("brand.#{attribute}")

  def brand_title(*parts) = [*parts, brand(:name)].join(' · ')

  def module_label(key, attribute = :name) = I18n.t("modules.#{key}.#{attribute}")
end
