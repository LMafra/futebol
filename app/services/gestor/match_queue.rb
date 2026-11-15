module Gestor
  # Work queue of the /gestor dashboard: open matches (earliest kickoff first) and the latest scored ones, each with
  # the single next step for its state. Which matches already have scouts comes from one pluck on PlayerScore.
  class MatchQueue
    OPEN_STATUSES = %w[scheduled live finished reverted].freeze
    LIMIT = 10
    RECENT_SCORED = 3

    Item = Data.define(:match, :step)

    def self.call(matches, now: Time.current) = new(matches, now:)

    def initialize(matches, now: Time.current)
      @matches = matches
      @now = now
    end

    def items
      @items ||= begin
        scoped = @matches.includes(:home_team, :away_team)
        open = scoped.where(status: OPEN_STATUSES).order(:match_date).limit(LIMIT).to_a
        scored = scoped.where(status: 'scored').order(scores_calculated_at: :desc).limit(RECENT_SCORED).to_a
        (open + scored).map { |match| Item.new(match:, step: step_for(match)) }
      end
    end

    def kpis
      due = @matches.where(status: %w[scheduled live]).where(match_date: ..@now).pluck(:id, :status)
      steps = due.map { |id, status| step_for_due(id, status) }
      {
        today: @matches.where(match_date: @now.all_day).count,
        awaiting_scouts: steps.count(:scouts),
        awaiting_finalization: steps.count(:finalize),
        next_round_hours: next_round_hours,
        inconsistencies: inconsistencies_count
      }
    end

    # Finished (scored by a queue before) and reverted matches are finalized again, scored in the same request.
    def step_for(match)
      case match.status
      when 'scheduled' then match.match_date > @now ? :edit : :scouts
      when 'live' then step_for_due(match.id, 'live')
      when 'scored' then :scored
      else :finalize
      end
    end

    private

    def step_for_due(id, status) = status == 'live' && scouted.include?(id) ? :finalize : :scouts

    def scouted
      @scouted ||= ::Cartola::PlayerScore.kept.where(match_id: @matches.select(:id)).distinct.pluck(:match_id).to_set
    end

    def next_round_hours
      next_at = @matches.where(status: 'scheduled').where('match_date > ?', @now).minimum(:match_date)
      return nil if next_at.blank?

      [((next_at - @now) / 1.hour).ceil, 0].max
    end

    def inconsistencies_count
      @matches.where(status: %w[finished reverted], scores_calculated_at: nil).count
    end
  end
end
