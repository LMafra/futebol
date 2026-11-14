# Cenários de teste (demo local): the "Copa dos Testes" of gestor@demo.local, with a match in every situation
# (scenario_matches.rb), and the platform cases the other seeds leave out (scenario_platform.rb). Built through the
# app's services, so the points, the auditoria and the Histórico da partida come out as from the screens. Runs
# once: a database that already has the Copa dos Testes is left alone, so its dates stay relative to the first load.
module Seeds
  def self.scenarios_ip = '127.0.0.1'

  def self.scenarios(manager)
    return if Core::Championship.exists?(external_id: 'copa-testes-2026')

    scenario_copa(scenario_championship(manager), manager)
    scenario_platform(manager)
  end

  def self.scenario_copa(championship, manager)
    matches = scenario_fixtures(championship, scenario_teams(manager))
    pool = scenario_pool(championship, manager, [*demo_users, scenario_user('anonimo@demo.local', 'Olga Anônima')])
    scenario_matches(matches, manager)
    scenario_bolao(pool, matches.first, manager)
    scenario_standings(championship, manager)
  end

  def self.scenario_championship(manager)
    championship = Core::Championship.create!(
      external_id: 'copa-testes-2026', name: 'Copa dos Testes', season: 2026, manager:, kind: 'society',
      prize_description: 'Premiação entregue na final, no campo do Vila Nova.',
      prize_rules: { first_place: 'R$ 500 e troféu', second_place: 'Medalhas', third_place: 'Bola oficial' }
    )
    scenario_image(championship.logo)
    championship
  end

  def self.scenario_team_names
    { 'VNT' => 'Vila Nova do Teste', 'ATC' => 'Atlético Cenário', 'ECE' => 'Esporte Clube Ensaio',
      'UDP' => 'Unidos do Protótipo' }
  end

  # Squads after the small championships' (20 + 12 per championship, 5 of them).
  def self.scenario_teams(manager)
    teams = scenario_team_names.each_with_index.map do |(short_name, name), index|
      team = Core::Team.create!(external_id: "team-#{short_name.downcase}", name:, short_name:, manager:,
                                captain_name: "Capitão do #{name}", captain_phone: "1198765432#{index}")
      scenario_image(team.crest)
      team
    end
    players(teams, offset: 80)
    teams
  end

  def self.scenario_image(attachment)
    attachment.attach(scenario_blob(Rails.root.join('db/seeds/files/escudo.png').binread, 'escudo.png', 'image/png'))
  end

  # Uploaded at once: attach(io:) uploads only after the seeds' transaction commits, too late for the CSV job.
  def self.scenario_blob(content, filename, content_type)
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new(content), filename:, content_type:)
  end

  # [round, home, away, kickoff from now], in the order scenario_matches reads them.
  def self.scenario_calendar
    [[1, 'VNT', 'ATC', -8.days], [1, 'ECE', 'UDP', -8.days + 2.hours], [2, 'VNT', 'ECE', -1.day],
     [2, 'ATC', 'UDP', -1.hour], [3, 'VNT', 'UDP', -20.minutes], [3, 'ATC', 'ECE', 3.days]]
  end

  def self.scenario_fixtures(championship, teams)
    enroll(championship, teams)
    by_code = teams.index_by(&:short_name)
    now = Time.current.change(sec: 0)
    scenario_calendar.map do |round, home, away, offset|
      Core::Match.create!(external_id: "testes-r#{round}-#{home.downcase}-#{away.downcase}", championship:, round:,
                          home_team: by_code.fetch(home), away_team: by_code.fetch(away), match_date: now + offset)
    end
  end

  # Its own rule (12/6), and every member's guesses in before the matches close.
  def self.scenario_pool(championship, manager, members)
    pool = Bolao::Pool.create!(championship:, owner: manager, name: 'Bolão dos Testes', code: 'TESTES')
    Bolao::ScoringRule.create!(pool:, exact_score_points: 12, winner_points: 6)
    members.each { |user| pool.memberships.create!(user:) }
    championship.matches.order(:round, :match_date).each_with_index do |match, index|
      members.each.with_index(1) do |user, number|
        demo_predict(pool, user, match, demo_guess(number, match.round, index))
      end
    end
    pool
  end

  # demo2's guess fixed by the organizer after the match was scored; demo5 leaves the pool.
  def self.scenario_bolao(pool, scored_match, manager)
    users = pool.members.where('email_address LIKE ?', 'demo%').order(:email_address).to_a
    prediction = pool.predictions.kept.find_by!(user: users.second, match: scored_match)
    Bolao::PredictionCorrection.call(prediction:, guess: [2, 2], reason: 'Palpite enviado pelo WhatsApp antes do jogo',
                                     actor: manager, ip_address: scenarios_ip)
    Bolao::MemberRemoval.call(membership: pool.memberships.find_by!(user: users.last), reason: 'Pediu para sair',
                              actor: manager, ip_address: scenarios_ip)
  end

  def self.scenario_standings(championship, manager)
    teams = championship.teams.index_by(&:short_name)
    PointDeductions.deduct(championship:, actor: manager, ip_address: scenarios_ip,
                           attributes: { team_id: teams.fetch('ECE').id, points: 3, reason: 'W.O. na 1ª rodada' })
    revoked = PointDeductions.deduct(championship:, actor: manager, ip_address: scenarios_ip,
                                     attributes: { team_id: teams.fetch('UDP').id, points: 1,
                                                   reason: 'Atraso na entrega da súmula' })
    PointDeductions.revoke(revoked, actor: manager, ip_address: scenarios_ip)
  end

  def self.scenario_user(email_address, name) = Core::User.create!(email_address:, name:, password: demo_password)
end
