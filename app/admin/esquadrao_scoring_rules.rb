ActiveAdmin.register Cartola::ScoringRule, as: 'EsquadraoScoringRule' do
  menu parent: 'Configurações', label: 'Regras do Esquadrão'

  permit_params :name, *Cartola::ScoringRule::POINT_COLUMNS

  AdminNameSearch.register(self)

  index do
    selectable_column
    id_column
    column :name
    Cartola::ScoringRule::POINT_COLUMNS.each { |points| column points, class: 'text-right tabular-nums' }
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
