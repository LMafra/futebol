# ActiveAdmin index renderer for Ui::CollectionComponent (docs/ux/listagens.md). Filters, scopes, pagination and
# download links stay ActiveAdmin's; the page of records goes to the listing partial with the namespace.
#
#   AdminCollectionIndex.register(self, 'admin/listings/teams')
#
# ActiveAdmin batch actions are off: their form would wrap the component, which has its own selection.
class AdminCollectionIndex < ActiveAdmin::Component
  def self.index_name = 'collection'

  def self.register(dsl, partial)
    renderer = self
    dsl.instance_exec do
      config.batch_actions = false
      controller { include CollectionSortParams }
      index(as: renderer) { |records| render partial, records:, namespace: active_admin_namespace.name }
    end
  end

  def build(page_presenter, collection)
    super(class: 'index-as-collection')
    instance_exec(collection.to_a, &page_presenter.block)
  end
end
