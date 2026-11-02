module Seeds
  # Scouts of a finished demo match, so the athletes ranking and the prices have data. The 11 of each side play;
  # the side's goals go to its attackers and midfielders in turn, every other goal assisted by the next one; the
  # goalkeeper makes saves and one outfield player gets a yellow card. The best score of the match is the
  # highlight. Points come from Cartola::Scorer with the rule in force, as Cartola::RecordScoutsService would give.
  # Written directly because that service refuses scored matches, and databases seeded before these scouts
  # existed only have scored ones.
  def self.demo_scouts(match)
    return if match.home_score.nil? || Cartola::PlayerScore.kept.exists?(match:)

    rule = Cartola::ScoringRule.default
    Cartola::PlayerScore.insert_all!(demo_highlight(demo_scout_rows(match).map { |row| demo_scored(row, rule) }, rule))
  end

  def self.demo_scored(row, rule) = row.merge(points: Cartola::Scorer.points(stats: row, rules: rule))

  def self.demo_highlight(rows, rule)
    best = rows.index(rows.max_by { |row| [row[:points], -row[:player_id]] })
    rows.each_with_index.map { |row, index| index == best ? demo_scored(row.merge(highlight: true), rule) : row }
  end

  # { team_id => [goals scored, goals conceded] }
  def self.demo_sides(match)
    { match.home_team_id => [match.home_score, match.away_score],
      match.away_team_id => [match.away_score, match.home_score] }
  end

  def self.demo_scout_rows(match)
    sides = demo_sides(match)
    Core::Player.where(team_id: sides.keys).order(:shirt_number).map do |player|
      scored, conceded = sides.fetch(player.team_id)
      { player_id: player.id, team_id: player.team_id, match_id: match.id, played: true, highlight: false,
        clean_sheet: conceded.zero?, **demo_scout_stats(match, player, scored) }
    end
  end

  def self.demo_scout_stats(match, player, scored)
    goals, assists = demo_goal_shares(match.id, player.shirt_number, scored)
    { goals:, assists:, saves: player.position == 'GOL' ? (match.id % 4) + 1 : 0,
      yellow_cards: player.shirt_number == (match.id % 6) + 2 ? 1 : 0 }
  end

  # Goal i goes to the attacking shirt at (match id + i); even goals are assisted by the next shirt in the list.
  def self.demo_goal_shares(match_id, shirt_number, scored)
    shirts = scored.times.map { |goal| [demo_attack_shirt(match_id + goal), goal.even?] }
    [shirts.count { |scorer, _| scorer == shirt_number },
     shirts.each_index.count { |goal| shirts[goal].last && demo_attack_shirt(match_id + goal + 1) == shirt_number }]
  end

  def self.demo_attack_shirt(index) = [9, 11, 7, 10, 8][index % 5]
end
