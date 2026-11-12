module Gestor
  class PunditAdapter < ::ActiveAdmin::PunditAdapter
    def default_policy_namespace = :gestor
  end
end
