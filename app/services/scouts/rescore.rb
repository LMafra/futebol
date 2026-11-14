module Scouts
  # A change to the lances or to "Jogou"/"Destaque" of a scored match: the score follows the lances and the Bolão
  # points and Esquadrão values are calculated again under a new scoring_token, inside the caller's lock. The
  # AuditLog keeps the score and the token from before. Does nothing for a match that is not scored.
  module Rescore
    def self.call(match, actor:, ip_address:)
      return unless match.scored?

      before = { home_score: match.home_score, away_score: match.away_score, scoring_token: match.scoring_token }
      MatchPoints.unscore!(match)
      home_score, away_score = Cartola::PlayerScore.score_for(match) || [0, 0]
      match.update!(home_score:, away_score:)
      scoring_token = MatchPoints.score!(match)
      Core::AuditLog.create!(action: 'rescore', user: actor, auditable: match, ip_address:,
                             metadata: { home_score:, away_score:, scoring_token:, before: })
    end
  end
end
