# Inscrição of teams on the championship page, shared by /admin and /gestor (ADR 0006): a panel listing the
# enrolled teams and member actions to enroll and unenroll them, authorized as enroll?/unenroll?.
module AdminChampionshipEnrollment
  ENROLL = proc do
    controller { include ModalFormRedirects }

    member_action :enroll, method: :post do
      enrollment = resource.championship_teams.build(team: Core::Team.find_by(id: params[:team_id]))
      if enrollment.save
        redirect_to resource_path, notice: "#{enrollment.team} inscrito no campeonato"
      elsif modal_return_path
        redirect_back_to_modal(enrollment.errors, values: { 'team_id' => params[:team_id].to_s })
      else
        redirect_to resource_path, alert: "Não foi possível inscrever: #{enrollment.errors.full_messages.to_sentence}"
      end
    end
  end

  UNENROLL = proc do
    member_action :unenroll, method: :delete do
      enrollment = resource.championship_teams.includes(:team).find_by!(team_id: params[:team_id])
      if enrollment.destroy
        redirect_to resource_path, notice: "#{enrollment.team} saiu do campeonato"
      else
        redirect_to resource_path, alert: enrollment.errors.full_messages.to_sentence
      end
    end
  end

  def self.register(dsl)
    dsl.instance_exec(&ENROLL)
    dsl.instance_exec(&UNENROLL)
  end

  def self.panel(context, championship, namespace)
    context.instance_exec do
      panel "Times inscritos (#{championship.championship_teams.size})" do
        render partial: 'admin/shared/enrollments', locals: { championship:, namespace: }
      end
    end
  end
end
