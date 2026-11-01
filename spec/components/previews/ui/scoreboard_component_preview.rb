module Ui
  # @label Scoreboard
  class ScoreboardComponentPreview < ViewComponent::Preview
    def default
      render ScoreboardComponent.new(match: sample_match)
    end

    def loading
      render ScoreboardComponent.new(state: :loading)
    end

    def empty
      render ScoreboardComponent.new(state: :empty)
    end

    def error
      render ScoreboardComponent.new(state: :error, retry_path: '#')
    end

    private

    def sample_match
      Core::Match.new(
        home_team: Core::Team.new(name: 'Flamengo', short_name: 'FLA'),
        away_team: Core::Team.new(name: 'Palmeiras', short_name: 'PAL'),
        match_date: Time.zone.parse('2026-11-08 16:00'),
        home_score: 2, away_score: 1, status: 'live'
      )
    end
  end
end
