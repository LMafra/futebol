# The single match page of /admin and /gestor (TICKET-0097): the show page is the scoreboard, the lances by team,
# the timeline and "Finalizar"; these member actions record and undo lances, mark "Jogou"/"Destaque" and finalize.
# Authorized as record_event?/undo_event?/participation?/finalize? on the match policy.
module AdminMatchBoard
  RECORD_EVENT = proc do
    member_action :record_event, method: :post do
      lance = params.expect(lance: %i[player_id stat period minute])
      event = Cartola::ScoutEvent.new(match: resource, player: Core::Player.find(lance[:player_id]),
                                      stat: lance[:stat], period: lance[:period].presence,
                                      minute: lance[:minute].presence)
      result = Scouts::RecordEvent.call(event:, actor: current_user, ip_address: request.remote_ip)
      next redirect_to(resource_path, notice: helpers.lance_notice(event), status: :see_other) if result.success?

      result.errors.each { event.errors.add(:base, _1) unless event.errors.full_messages.include?(_1) }
      redirect_back_to_modal(event.errors, values: lance.to_h, fallback: resource_path)
    end
  end

  UNDO_EVENT = proc do
    member_action :undo_event, method: :post do
      result = Scouts::UndoLast.call(match: resource, player: Core::Player.find(params[:player_id]),
                                     stat: params[:stat], actor: current_user, ip_address: request.remote_ip)
      if result.success?
        redirect_to resource_path, notice: "Desfeito: #{helpers.lance_text(result.event)}.", status: :see_other
      else
        redirect_to resource_path, alert: result.errors.to_sentence, status: :see_other
      end
    end
  end

  PARTICIPATION = proc do
    member_action :participation, method: :post do
      flags = params.expect(flags: %i[played highlight]).to_h.transform_values { ActiveModel::Type::Boolean.new.cast(_1) }
      result = Scouts::MarkParticipation.call(match: resource, player: Core::Player.find(params[:player_id]),
                                              flags: flags.symbolize_keys, actor: current_user,
                                              ip_address: request.remote_ip)
      flash_message = result.success? ? {} : { alert: result.errors.to_sentence }
      redirect_to resource_path, **flash_message, status: :see_other
    end
  end

  FINALIZE = proc do
    member_action :finalize, method: :post do
      form = MatchFinalizationForm.new(score_confirmation: params.dig(:finalize, :score_confirmation),
                                       match: resource, actor: current_user, ip_address: request.remote_ip)
      if form.save
        redirect_to resource_path, status: :see_other,
                                   notice: "Partida finalizada em #{form.home_score} × #{form.away_score}; " \
                                           'pontuação enfileirada.'
      else
        redirect_back_to_modal(form.errors, values: { 'score_confirmation' => form.score_confirmation.to_s },
                                            fallback: resource_path)
      end
    end
  end

  # `extra`: more content below the board, run in the show context.
  def self.register(dsl, &extra)
    dsl.controller { include ModalFormRedirects }
    [RECORD_EVENT, UNDO_EVENT, PARTICIPATION, FINALIZE].each { dsl.instance_exec(&_1) }
    dsl.instance_exec(extra) do |more|
      show(title: :to_s) do
        render partial: 'admin/match_board/page', locals: { board: MatchBoard.new(resource) }
        instance_exec(&more) if more
      end
    end
  end
end
