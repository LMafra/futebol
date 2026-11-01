require 'bolao/version'
require 'bolao/engine'

module Bolao
  # Scoring lives in the host app (Scoring::Engine), which this engine may not reference (packwerk);
  # the host wires it in config/initializers/bolao.rb. Must respond to points_for(prediction:, home:, away:, rules:).
  mattr_accessor :scorer
end
