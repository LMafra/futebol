module AdminHelper
  def admin_score(match)
    [match.home_score, match.away_score].map { |goals| goals.nil? ? '–' : goals }.join(' × ')
  end
end
