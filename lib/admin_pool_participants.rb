# Participantes › Bolão (/admin and /gestor pool page): ranking, the members with their predictions (?membro=ID)
# and the organizer's fixes, each with a reason in the AuditLog. Authorized as correct_prediction? and
# remove_member? on the pool policy.
module AdminPoolParticipants
  CORRECT_PREDICTION = proc do
    member_action :correct_prediction, method: :post do
      fields = params.expect(correction: %i[prediction_id home_guess away_guess reason]).to_h.symbolize_keys
      form = PredictionCorrectionForm.new(**fields, pool: resource, actor: current_user,
                                                    ip_address: request.remote_ip)
      if form.save
        redirect_to modal_return_path || resource_path, notice: 'Palpite corrigido.', status: :see_other
      else
        redirect_back_to_modal(form.errors, values: fields.transform_values(&:to_s), fallback: resource_path)
      end
    end
  end

  REMOVE_MEMBER = proc do
    member_action :remove_member, method: :post do
      fields = params.expect(removal: %i[user_id reason]).to_h.symbolize_keys
      form = MemberRemovalForm.new(**fields, pool: resource, actor: current_user, ip_address: request.remote_ip)
      if form.save
        redirect_to resource_path, notice: "#{form.membership.user.name.presence || form.membership.user} " \
                                           'saiu do bolão.', status: :see_other
      else
        redirect_back_to_modal(form.errors, values: fields.transform_values(&:to_s), fallback: resource_path)
      end
    end
  end

  SHOW = proc do
    show do |pool|
      attributes_table do
        row :championship
        row :owner
        row('Código') { tag.span(pool.code, class: 'font-numeric text-xl tracking-widest') }
      end
      render partial: 'admin/pool_participants/page', locals: { participants: PoolParticipants.new(pool) }
    end
  end

  def self.register(dsl)
    dsl.controller { include ModalFormRedirects }
    [CORRECT_PREDICTION, REMOVE_MEMBER, SHOW].each { dsl.instance_exec(&_1) }
  end
end
