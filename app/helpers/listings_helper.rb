# Admin and Gestor listings (app/views/admin/listings): one grouped query per count instead of one per row.
module ListingsHelper
  def listing_counts(model, foreign_key, records)
    model.where(foreign_key => records.map(&:id)).group(foreign_key).count
  end

  # The chosen view when it is one of the listing's views, else the first.
  def listing_view(views) = params[:view].to_s.presence_in(views.keys.map(&:to_s))&.to_sym || views.keys.first

  def listing_sort_options = { sort: params[:sort], direction: params[:dir] }

  # Week shown by the matches agenda: the ActiveAdmin date filter (?q[match_date_gteq]), Monday to Sunday.
  def agenda_week
    Date.iso8601(params.dig(:q, :match_date_gteq).to_s).beginning_of_week
  rescue Date::Error
    nil
  end

  def agenda_week_path(week)
    filters = request.query_parameters['q']
    filters = (filters.is_a?(Hash) ? filters : {}).merge('match_date_gteq' => week.iso8601,
                                                         'match_date_lt' => (week + 7).iso8601)
    query = request.query_parameters.except('page', 'sort', 'dir')
                   .merge('view' => 'agenda', 'order' => 'match_date_asc', 'q' => filters)
    "#{request.path}?#{query.to_query}"
  end
end
