module Core
  class ChampionshipPolicy < ApplicationPolicy
    # /campeonatos/:id is open to visitors; private championships never reach it (404).
    def public_show? = !record.private?
  end
end
