module Simulador
  # Headless (authorize [:simulador, :simulation]): the Simulador is public, visitors included (ADR 0003 §5).
  class SimulationPolicy < ApplicationPolicy
    def index? = true
    def show? = true
    def preview? = true

    # Championships that can be simulated: visitors only see public ones; signed-in users every published one.
    class Scope < ApplicationPolicy::Scope
      def resolve = user.present? ? scope.published : scope.publicly_visible
    end
  end
end
