module Simulador
  # Headless (authorize [:simulador, :simulation]): the Simulador is public, visitors included (ADR 0003 §5).
  class SimulationPolicy < ApplicationPolicy
    def show? = true
    def preview? = true
  end
end
