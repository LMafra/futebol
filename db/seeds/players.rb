module Seeds
  def self.players(teams)
    teams.each_with_index do |team, team_index|
      squad.each do |shirt_number, position|
        Core::Player.find_or_create_by!(external_id: "#{team.external_id}-#{shirt_number}") do |player|
          player.assign_attributes(team:, position:, shirt_number:,
                                   **player_traits((team_index * squad.size) + shirt_number, position))
        end
      end
    end
  end

  # Fictional demo squads: shirt number => position (4-3-3).
  def self.squad
    { 1 => 'GOL', 2 => 'LAT', 3 => 'ZAG', 4 => 'ZAG', 5 => 'MEI', 6 => 'LAT',
      7 => 'ATA', 8 => 'MEI', 9 => 'ATA', 10 => 'MEI', 11 => 'ATA' }
  end

  def self.player_traits(seed, position) = { name: player_name(seed), base_value: player_base_value(position, seed) }

  # C$ 4-13: a full lineup at the default limits (9 players) costs about C$ 75 of the C$ 100 wallet, so the
  # budget is a real constraint.
  def self.player_base_value(position, seed)
    { 'GOL' => 5, 'LAT' => 4, 'ZAG' => 4, 'MEI' => 6, 'ATA' => 7 }.fetch(position) + (seed % 7)
  end

  def self.player_name(seed)
    first_names = %w[Gabriel Lucas Pedro Matheus Rafael Bruno Thiago Felipe Gustavo Diego Vitor Caio André Renan
                     Igor Júlio Danilo Samuel Wesley Everton Henrique Marcos Luan]
    last_names = %w[Silva Souza Oliveira Santos Pereira Lima Carvalho Ribeiro Almeida Ferreira Rocha Gomes Martins
                    Barbosa Araújo Cardoso Teixeira Moreira Nunes Correia Mendes Castro Pinto]

    "#{first_names[seed % first_names.size]} #{last_names[(seed * 7) % last_names.size]}"
  end
end
