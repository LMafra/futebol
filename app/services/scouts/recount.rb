module Scouts
  # After a lance is recorded or undone (ADR 0006): the player's counters become the sum of the kept lances, SG and
  # points of the match are scored again with the rule in force, and the score follows the scouts while the match
  # is live. Runs inside the caller's transaction.
  module Recount
    def self.call(match, player, team_id)
      counts = Cartola::ScoutEvent.kept.where(match:, player:).group(:stat).count
      score = Cartola::PlayerScore.kept.find_or_initialize_by(match:, player:)
      score.assign_attributes(Cartola::PlayerScore::SCOUTS.to_h { [_1, counts.fetch(_1.to_s, 0)] })
      score.played = true
      score.team_id ||= team_id
      score.points ||= 0
      score.save!
      Cartola::RecordScoutsService.rescore!(match)
      update_score!(match)
    end

    def self.update_score!(match)
      return unless match.live?

      home_score, away_score = Cartola::PlayerScore.score_for(match) || [0, 0]
      match.update!(home_score:, away_score:)
    end
  end
end
