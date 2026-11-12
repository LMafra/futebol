ActiveAdmin.register Bolao::Pool, as: 'Pool' do
  menu parent: 'Configurações', label: 'Bolões'

  permit_params :name, :championship_id, :owner_id,
                scoring_rule_attributes: %i[id exact_score_points winner_points _destroy]
  includes :championship, :owner

  filter :name
  filter :championship

  index do
    selectable_column
    id_column
    column :name
    column :championship
    column :owner
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :championship
      f.input :owner, collection: Core::User.active.order(:email_address)
    end
    rule = f.object.scoring_rule || Bolao::ScoringRule.new(exact_score_points: nil, winner_points: nil)
    f.inputs 'Pontuação própria (opcional; em branco usa a regra do campeonato)', for: [:scoring_rule, rule] do |r|
      r.input :exact_score_points, label: 'Pontos por placar exato', input_html: { min: 0 }
      r.input :winner_points, label: 'Pontos por vencedor', input_html: { min: 0 }
      r.input :_destroy, as: :boolean, label: 'Remover pontuação própria' if rule.persisted?
    end
    f.actions
  end
end
