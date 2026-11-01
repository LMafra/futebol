ActiveAdmin.register Bolao::ScoringRule, as: 'BolaoScoringRule' do
  menu parent: 'Pontuação', label: 'Regras do Bolão'

  permit_params :pool_id, :kind, :points
  includes :pool

  filter :kind, as: :select, collection: -> { Bolao::ScoringRule::KINDS }
  filter :pool

  index do
    selectable_column
    id_column
    column :kind
    column :points
    column(:pool) { |rule| rule.pool || 'global' }
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :pool, include_blank: 'global'
      f.input :kind, as: :select, collection: Bolao::ScoringRule::KINDS
      f.input :points
    end
    f.actions
  end
end
