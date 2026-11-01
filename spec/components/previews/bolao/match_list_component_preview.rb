module Bolao
  # @label Bolão match list
  class MatchListComponentPreview < ViewComponent::Preview
    def default
      render MatchListComponent.new(pool: Bolao::Pool.new(id: 1), matches: sample_matches)
    end

    def loading
      render MatchListComponent.new(state: :loading)
    end

    def empty
      render MatchListComponent.new(state: :empty)
    end

    def error
      render MatchListComponent.new(state: :error)
    end

    private

    def sample_matches
      [
        sample_match(1, 'Flamengo', 'Palmeiras', 2.days.from_now + 3.hours, 'scheduled'),
        sample_match(2, 'Grêmio', 'Internacional', 20.minutes.ago, 'live')
      ]
    end

    def sample_match(id, home, away, match_date, status)
      Core::Match.new(id:, match_date:, status:, home_team: Core::Team.new(name: home),
                      away_team: Core::Team.new(name: away))
    end
  end
end
