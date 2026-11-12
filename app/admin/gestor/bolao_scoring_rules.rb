ActiveAdmin.register Bolao::ScoringRule, as: 'BolaoScoringRule', namespace: :gestor do
  menu parent: 'Configurações', label: 'Regras do Bolão', priority: 2

  permit_params :championship_id, :exact_score_points, :winner_points
  includes :championship

  actions :index, :show, :new, :create, :edit, :update

  controller do
    include GestorResource

    before_build do |rule|
      rule.championship ||= helpers.gestor_championships.first unless current_user.admin?
    end
  end

  filter :championship, collection: -> { gestor_championships }

  index do
    id_column
    column :championship
    column 'Pontos por placar exato', :exact_score_points
    column 'Pontos por vencedor', :winner_points
    actions defaults: false do |rule|
      item 'Ver', gestor_bolao_scoring_rule_path(rule)
      item 'Editar', edit_gestor_bolao_scoring_rule_path(rule) if authorized?(:update, rule)
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs 'Campeonato (regra do bolão para o campeonato; não afeta bolões individuais)' do
      f.input :championship, collection: gestor_championships, include_blank: false
    end
    f.inputs 'Pontuação' do
      f.input :exact_score_points, label: 'Pontos por placar exato', input_html: { min: 0 }
      f.input :winner_points, label: 'Pontos por vencedor', hint: 'vencedor ou empate certo com placar errado',
                              input_html: { min: 0 }
    end
    f.actions if f.object.new_record? || authorized?(:update, f.object)
  end
end
