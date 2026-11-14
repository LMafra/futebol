# Name search for ActiveAdmin indexes: one plain "Nome" field (no contains/equals/starts/ends operators) with
# suggestions from GET <index>/autocomplete?q=, limited to what the current user may list.
module AdminNameSearch
  LIMIT = 8
  MIN_LENGTH = 2

  def self.register(dsl, attribute = :name, label: 'Nome')
    dsl.instance_exec do
      filter :"#{attribute}_cont", label:, as: :string,
                                   input_html: { autocomplete: 'off', placeholder: 'Digite parte do nome',
                                                 data: { controller: 'autocomplete' } }
      collection_action :autocomplete, method: :get do
        render json: AdminNameSearch.suggestions(apply_authorization_scope(scoped_collection), attribute, params[:q])
      end
    end
  end

  def self.suggestions(scope, attribute, term)
    term = term.to_s.strip
    return [] if term.length < MIN_LENGTH

    column = scope.klass.arel_table[attribute]
    scope.unscope(:includes, :order).where(column.matches("%#{ActiveRecord::Base.sanitize_sql_like(term)}%"))
         .distinct.order(attribute).limit(LIMIT).pluck(attribute)
  end
end
