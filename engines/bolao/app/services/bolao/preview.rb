module Bolao
  # rows: frozen array of Row, one per kept prediction of the match; total: sum of the rows points.
  Preview = Data.define(:rows, :total) do
    const_set(:Row, Data.define(:prediction_id, :pool_id, :user_id, :home_guess, :away_guess, :points))
  end
end
