module Users
  # Escalação closes 15 minutes before the earliest scheduled kickoff of the round.
  class LineupDeadline
    OFFSET = 15.minutes

    def self.for(championship:, round:, now: Time.current)
      new(championship:, round:, now:).tap(&:compute)
    end

    attr_reader :closes_at, :championship, :round

    def initialize(championship:, round:, now: Time.current)
      @championship = championship
      @round = round
      @now = now
    end

    def compute
      kickoff = championship.matches.where(round:, status: 'scheduled').minimum(:match_date)
      @closes_at = kickoff && (kickoff - OFFSET)
      self
    end

    def closed? = closes_at.present? && now >= closes_at

    def open? = !closed?

    def badge_text
      return if closes_at.blank?
      return 'Escalação fechada' if closed?

      "Escalação fecha em #{distance}"
    end

    private

    attr_reader :now

    def distance
      seconds = (closes_at - now).to_i
      return 'menos de 1 min' if seconds < 60

      hours, rem = seconds.divmod(1.hour)
      minutes = rem / 1.minute
      return "#{hours}h #{minutes}min" if hours.positive?

      "#{minutes} min"
    end
  end
end
