# Classificação tab of the championship page, shared by /admin and /gestor: the real table with the Dedução column,
# the deductions with their history and member actions to deduct points and revoke a deduction, authorized as
# deduct_points?/revoke_deduction? (a gestor only reaches his own championships).
module AdminChampionshipStandings
  TAB = 'classificacao'.freeze
  TABS = { nil => 'Dados', TAB => 'Classificação' }.freeze

  ACTIONS = proc do
    controller { include ModalFormRedirects }

    member_action :deduct_points, method: :post do
      attributes = params.expect(deduction: %i[team_id points reason])
      deduction = PointDeductions.deduct(championship: resource, attributes:, actor: current_user,
                                         ip_address: request.remote_ip)
      if deduction.persisted?
        notice = "#{deduction.team} perdeu #{deduction.points} #{'ponto'.pluralize(deduction.points)}"
        redirect_to resource_path(aba: TAB), notice:, status: :see_other
      else
        redirect_back_to_modal(deduction.errors, values: attributes.to_h, fallback: resource_path(aba: TAB))
      end
    end

    member_action :revoke_deduction, method: :patch do
      deduction = resource.point_deductions.active.includes(:team).find(params[:deduction_id])
      PointDeductions.revoke(deduction, actor: current_user, ip_address: request.remote_ip)
      redirect_to resource_path(aba: TAB), notice: "Dedução de #{deduction.team} revogada", status: :see_other
    end
  end

  def self.register(dsl) = dsl.instance_exec(&ACTIONS)

  # Section links over the page; the Classificação tab replaces the panels below them.
  def self.tabs(context, championship, namespace)
    context.instance_exec do
      render partial: 'admin/shared/championship_tabs', locals: { championship:, namespace:, current: params[:aba] }
    end
  end

  def self.standings?(params) = params[:aba] == TAB

  def self.panel(context, championship, namespace)
    context.instance_exec do
      panel 'Classificação' do
        render partial: 'admin/shared/championship_standings', locals: { championship:, namespace: }
      end
    end
  end
end
