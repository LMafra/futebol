Rails.application.config.to_prepare do
  Bolao.scorer = Scoring::Engine
end
