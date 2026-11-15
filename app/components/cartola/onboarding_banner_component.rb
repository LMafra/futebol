module Cartola
  # First-visit banner explaining formation, wallet and captain for the Esquadrão.
  class OnboardingBannerComponent < Ui::BaseComponent
    STEPS = [
      {
        title: 'Escolha a formação',
        body: 'A formação organiza o campo. Os limites por posição (GOL, ZAG, LAT, MEI, ATA) vêm do campeonato.'
      },
      {
        title: 'Compre jogadores com sua carteira',
        body: 'Cada atleta tem um preço em E$. A barra de orçamento mostra gasto, saldo e o que ainda resta.'
      },
      {
        title: 'Escolha o capitão',
        body: 'O capitão pontua em dobro — inclusive nos Lances negativos. Marque o C ao lado do jogador.'
      }
    ].freeze

    attr_reader :dismiss_path

    def initialize(dismiss_path:, state: :default)
      super(state:)
      @dismiss_path = dismiss_path
      require_in_default_state!(:dismiss_path, dismiss_path)
    end
  end
end
