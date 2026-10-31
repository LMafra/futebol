module Seeds
  def self.players(teams)
    teams.each_with_index do |team, team_index|
      squad.each do |shirt_number, position|
        Core::Player.find_or_create_by!(external_id: "#{team.external_id}-#{shirt_number}") do |player|
          player.team = team
          player.name = player_name((team_index * squad.size) + shirt_number)
          player.position = position
          player.shirt_number = shirt_number
        end
      end
    end
  end

  # Fictional demo squads: shirt number => position (4-3-3).
  def self.squad
    { 1 => 'GOL', 2 => 'LAT', 3 => 'ZAG', 4 => 'ZAG', 5 => 'MEI', 6 => 'LAT',
      7 => 'ATA', 8 => 'MEI', 9 => 'ATA', 10 => 'MEI', 11 => 'ATA' }
  end

  def self.player_name(seed)
    first_names = %w[Gabriel Lucas Pedro Matheus Rafael Bruno Thiago Felipe Gustavo Diego Vitor Caio André Renan
                     Igor Júlio Danilo Samuel Wesley Everton Henrique Marcos Luan]
    last_names = %w[Silva Souza Oliveira Santos Pereira Lima Carvalho Ribeiro Almeida Ferreira Rocha Gomes Martins
                    Barbosa Araújo Cardoso Teixeira Moreira Nunes Correia Mendes Castro Pinto]

    "#{first_names[seed % first_names.size]} #{last_names[(seed * 7) % last_names.size]}"
  end
end
