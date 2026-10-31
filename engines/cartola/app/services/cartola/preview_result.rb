module Cartola
  # player_points: { player_id => points } (frozen); total: sum of player_points.
  PreviewResult = Data.define(:player_points, :total)
end
