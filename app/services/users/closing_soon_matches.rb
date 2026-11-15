module Users
  # App-layer query for scheduled matches whose kickoff falls within a window (no Core::Match scope).
  class ClosingSoonMatches
    def self.call(relation: Core::Match.all, within: 24.hours, now: Time.current)
      new(relation:, within:, now:).matches
    end

    def initialize(relation:, within:, now:)
      @relation = relation
      @within = within
      @now = now
    end

    def matches
      relation.where(status: 'scheduled')
              .where(match_date: now..(now + within))
              .order(:match_date)
    end

    private

    attr_reader :relation, :within, :now
  end
end
