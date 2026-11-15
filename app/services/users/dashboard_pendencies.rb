module Users
  # Builds Action Center groups (open bets + missing lineup) for /minha-area.
  class DashboardPendencies
    PendingItem = Data.define(:title, :context, :action_text, :action_path, :urgency, :id)

    def initialize(dashboard)
      @dashboard = dashboard
    end

    def groups
      items.group_by(&:urgency).transform_values { |group| group.map { |item| item_hash(item) } }
    end

    private

    attr_reader :dashboard

    def items
      bet_items + Array(lineup_item)
    end

    def bet_items
      dashboard.open_prediction_slots.first(8).map { |slot| bet_item(slot) }
    end

    def bet_item(slot)
      match = slot.fetch(:match)
      pool = slot.fetch(:pool)
      hours = hours_until(match.match_date)
      PendingItem.new(**bet_item_attrs(match, pool, hours))
    end

    def bet_item_attrs(match, pool, hours)
      {
        title: "Palpite: #{match.home_team.name} × #{match.away_team.name}",
        context: deadline_context(hours, pool_name: pool.name),
        action_text: 'Palpitar',
        action_path: helpers.pool_bets_path(pool),
        urgency: urgency_for_hours(hours),
        id: "bet-#{pool.id}-#{match.id}"
      }
    end

    def lineup_item
      return if dashboard.lineup_ready?

      PendingItem.new(
        title: 'Escalação da rodada',
        context: 'Monte sua escalação no Esquadrão',
        action_text: 'Montar escalação',
        action_path: helpers.esquadrao_path,
        urgency: :high,
        id: 'lineup-missing'
      )
    end

    def item_hash(item)
      {
        title: item.title,
        context: item.context,
        action_text: item.action_text,
        action_path: item.action_path,
        id: item.id
      }
    end

    def helpers = Rails.application.routes.url_helpers

    def hours_until(time)
      return if time.blank?

      ((time - Time.current) / 1.hour).ceil
    end

    def deadline_context(hours, pool_name:)
      return "#{pool_name} · prazo indisponível" if hours.nil?
      return "#{pool_name} · fecha em menos de 1 hora" if hours <= 0
      return "#{pool_name} · fecha em #{hours} hora#{'s' unless hours == 1}" if hours < 48

      "#{pool_name} · fecha em #{(hours / 24.0).ceil} dias"
    end

    def urgency_for_hours(hours)
      return :critical if hours.nil? || hours <= 3
      return :high if hours <= 24

      :medium
    end
  end
end
