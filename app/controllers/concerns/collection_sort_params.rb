# Ui::CollectionComponent links ?sort=name&dir=desc; ActiveAdmin sorts by ?order=name_desc. Only real columns
# pass: an unknown one would reach the SQL.
module CollectionSortParams
  extend ActiveSupport::Concern

  included do
    before_action :collection_sort_to_order, only: :index
  end

  private

  def collection_sort_to_order
    return if params[:order].present? || !resource_class.column_names.include?(params[:sort].to_s)

    params[:order] = "#{params[:sort]}_#{params[:dir] == 'desc' ? 'desc' : 'asc'}"
  end
end
