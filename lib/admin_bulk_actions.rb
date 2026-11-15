# Bulk actions of the Admin and Gestor listings, posted by the selection bar of Ui::CollectionComponent
# (docs/ux/listagens.md). The policy scope picks the records the user may touch; the Bulk services keep the others
# and the flash says why. Authorized as bulk_<action>? on the resource class.
#
#   AdminBulkActions.register(self, :destroy, :enroll)
module AdminBulkActions
  SHIFT_UNITS = %w[days hours].freeze
  MAX_SHIFT = 365

  CONTROLLER = proc do
    controller do
      private

      def with_bulk_records(*includes)
        records = bulk_records(includes)
        return bulk_refuse('Selecione pelo menos um item.') if records.empty?

        report = yield(records)
        redirect_back_or_to collection_path, (report.done.any? ? :notice : :alert) => report.message
      end

      def bulk_records(includes)
        ids = Array(params[:ids]).compact_blank
        scope = active_admin_authorization.scope_collection(resource_class.where(id: ids).order(:id))
        (includes.any? ? scope.includes(*includes) : scope).to_a
      end

      def bulk_refuse(message) = redirect_back_or_to(collection_path, alert: message)
      def bulk_target(klass, id) = active_admin_authorization.scope_collection(klass.all).find_by(id:)
      def bulk_context = { actor: current_user, ip_address: request.remote_ip }

      def bulk_shift
        amount = params[:shift_amount].to_i
        unit = params[:shift_unit].presence_in(AdminBulkActions::SHIFT_UNITS)
        amount.public_send(unit) if unit && amount.nonzero? && amount.abs <= AdminBulkActions::MAX_SHIFT
      end
    end
  end

  DESTROY = proc do
    collection_action :bulk_destroy, method: :post do
      includes = resource_class == Core::Match ? %i[home_team away_team] : []
      with_bulk_records(*includes) { Bulk::DestroyRecords.call(_1, **bulk_context) }
    end
  end

  ENROLL = proc do
    %i[enroll unenroll].each do |direction|
      collection_action :"bulk_#{direction}", method: :post do
        championship = bulk_target(Core::Championship, params[:championship_id])
        next bulk_refuse('Escolha um campeonato seu.') unless championship && authorized?(:enroll, championship)

        with_bulk_records { Bulk::Enrollment.public_send(direction, _1, championship:) }
      end
    end
  end

  MOVE = proc do
    collection_action :bulk_move, method: :post do
      team = bulk_target(Core::Team, params[:team_id])
      next bulk_refuse('Escolha o time de destino.') unless team && authorized?(:update, team)

      with_bulk_records(:team) { Bulk::MovePlayers.call(_1, team:, **bulk_context) }
    end
  end

  RESCHEDULE = proc do
    collection_action :bulk_reschedule, method: :post do
      shift = bulk_shift
      next bulk_refuse("Informe de quantos dias ou horas (até #{AdminBulkActions::MAX_SHIFT}).") unless shift
      next bulk_refuse('Informe o motivo do reagendamento.') if params[:reason].blank?

      with_bulk_records(:home_team, :away_team) do |matches|
        Bulk::RescheduleMatches.call(matches, shift:, reason: params[:reason].strip, **bulk_context)
      end
    end
  end

  APPROVE_MANAGER = proc do
    collection_action :bulk_approve_manager, method: :post do
      with_bulk_records { Bulk::ApproveManagers.call(_1, **bulk_context) }
    end
  end

  def self.register(dsl, *actions)
    dsl.instance_exec(&CONTROLLER)
    actions.each { dsl.instance_exec(&const_get(_1.to_s.upcase)) }
  end
end
