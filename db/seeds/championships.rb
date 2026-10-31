module Seeds
  def self.championship
    Core::Championship.find_or_create_by!(external_id: 'brasileirao-2026') do |championship|
      championship.name = 'Brasileirão Série A'
      championship.season = 2026
    end
  end
end
