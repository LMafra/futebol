module Seeds
  def self.matches(championship, teams)
    enroll(championship, teams)
    double_round_robin(teams).each.with_index(1) do |pairings, round|
      pairings.each_with_index do |(home, away), index|
        Core::Match.find_or_create_by!(external_id: match_external_id(round, home, away)) do |match|
          match.assign_attributes(home_team: home, away_team: away, championship:, round:,
                                  match_date: match_date(round, index))
        end
      end
    end
  end

  # Matches only take teams enrolled in their championship (ADR 0006).
  def self.enroll(championship, teams)
    teams.each { |team| championship.championship_teams.find_or_create_by!(team:) }
  end

  # Circle method: one team stays put while the others rotate; the return leg mirrors the first.
  def self.double_round_robin(teams)
    anchor, *others = teams
    first_leg = others.size.times.map { |round| round_pairings([anchor, *others.rotate(-round)], round) }
    first_leg + first_leg.map { |pairings| pairings.map(&:reverse) }
  end

  def self.round_pairings(circle, round)
    (circle.size / 2).times.map do |index|
      pairing = [circle[index], circle[-1 - index]]
      (round + index).even? ? pairing : pairing.reverse
    end
  end

  # Weekly rounds on Sundays from 2026-04-05, kickoffs at 16:00, 18:30 and 20:30 (Brasília).
  def self.match_date(round, index)
    kickoffs = [16.hours, 18.hours + 30.minutes, 20.hours + 30.minutes]
    Time.find_zone!('America/Sao_Paulo').local(2026, 4, 5) + (round - 1).weeks + kickoffs[index % kickoffs.size]
  end

  def self.match_external_id(round, home, away)
    format('br26-r%<round>02d-%<home>s-%<away>s',
           round:, home: home.short_name.downcase, away: away.short_name.downcase)
  end
end
