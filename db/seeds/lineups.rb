module Seeds
  # Bought through the wallet, so the demo user's balance reflects it.
  def self.demo_lineup(user, championship, round: 7, pick: 0)
    squad = Cartola::Squad.find_or_create_by!(user:) { |new_squad| new_squad.name = "Time de #{user.name}" }
    lineup = squad.lineups.find_or_initialize_by(championship:, round:)
    return if lineup.persisted?

    lineup.formation = '4-3-3'
    assign_demo_players(lineup, demo_lineup_players(championship, pick))
    Cartola::WalletService.save(lineup) || raise("demo lineup: #{lineup.errors.full_messages.to_sentence}")
  end

  def self.assign_demo_players(lineup, players)
    lineup.assign_players(players)
    lineup.assign_captain(players.last&.id)
  end

  # Per position, the championship's cheapest players up to the default limits (1 / 2 / 3 / 3). pick shifts
  # the choice along the next cheapest ones, so each demo user fields a different side within the budget.
  def self.demo_lineup_players(championship, pick)
    players = Core::Player.where(team: championship.teams).order(:base_value, :external_id)
    { 'GOL' => 1, 'LAT' => 1, 'ZAG' => 1, 'MEI' => 3, 'ATA' => 3 }.flat_map do |position, count|
      players.where(position:).first(count + 4).rotate(pick).first(count)
    end
  end
end
