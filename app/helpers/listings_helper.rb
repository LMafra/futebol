# Admin and Gestor listings (app/views/admin/listings): one grouped query per count instead of one per row.
module ListingsHelper
  def listing_counts(model, foreign_key, records)
    model.where(foreign_key => records.map(&:id)).group(foreign_key).count
  end

  # The chosen view when it is one of the listing's views, else the first.
  def listing_view(views) = params[:view].to_s.presence_in(views.keys.map(&:to_s))&.to_sym || views.keys.first

  def listing_sort_options = { sort: params[:sort], direction: params[:dir] }
end
