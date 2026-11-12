ActiveAdmin.register Bolao::ScoringRule, as: 'BolaoScoringRule' do
  menu parent: 'Configurações', label: 'Regras do Bolão'

  permit_params :championship_id, :pool_id, :exact_score_points, :winner_points
  includes :pool, :championship

  filter :championship
  filter :pool

  index do
    selectable_column
    id_column
    column('Escopo', &:scope_label)
    column 'Pontos por placar exato', :exact_score_points
    column 'Pontos por vencedor', :winner_points
    actions
  end

  form do |f|
    f.semantic_errors
    f.inputs 'Escopo (deixe os dois em branco para a regra global; o bolão sobrepõe o campeonato)' do
      f.input :championship, include_blank: 'todos'
      f.input :pool, include_blank: 'nenhum'
    end
    f.inputs 'Pontuação' do
      f.input :exact_score_points, label: 'Pontos por placar exato', input_html: { min: 0 }
      f.input :winner_points, label: 'Pontos por vencedor', hint: 'vencedor ou empate certo com placar errado',
                              input_html: { min: 0 }
    end
    f.actions
  end
end
