ActiveAdmin.register Cartola::ScoringRule, as: 'CartolaScoringRule' do
  menu parent: 'Pontuação', label: 'Regras do Cartola'

  permit_params :name, *Cartola::ScoringRule::POINT_COLUMNS

  filter :name

  index do
    selectable_column
    id_column
    column :name
    Cartola::ScoringRule::POINT_COLUMNS.each { |points| column points }
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      Cartola::ScoringRule::POINT_COLUMNS.each { |points| f.input points }
    end
    f.actions
  end
end
