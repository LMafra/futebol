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

    matching_names(scope, attribute, term)
  end

  def self.matching_names(scope, attribute, term)
    column = scope.klass.arel_table[attribute]
    like = "%#{ActiveRecord::Base.sanitize_sql_like(term)}%"
    scope.unscope(:includes, :order).where(column.matches(like))
         .group(attribute).order(collated_name_order(scope, attribute)).limit(LIMIT).pluck(attribute)
  end

  def self.collated_name_order(scope, attribute)
    quoted = scope.klass.connection.quote_column_name(attribute.to_s)
    Arel.sql("#{quoted} COLLATE \"C\"")
  end
  private_class_method :matching_names, :collated_name_order
end
