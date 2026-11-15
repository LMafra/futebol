module Bulk
  # Outcome of a bulk action for the flash: what was done and what was kept, grouped by reason, naming the kept ones
  # ("3 excluídos, 2 mantidos porque têm partidas (Azul FC, Verde FC)"). Words are [singular, plural] pairs.
  class Report
    attr_reader :done, :kept

    def initialize(done:, kept: %w[mantido mantidos])
      @done_words = done
      @kept_words = kept
      @done = []
      @kept = Hash.new { |hash, reason| hash[reason] = [] }
    end

    def done!(record) = @done << record
    def keep!(record, reason) = @kept[reason] << record

    def message
      [phrase(done.size, @done_words), *kept.map { |reason, records| kept_phrase(reason, records) }].join(', ')
    end

    private

    def kept_phrase(reason, records)
      "#{phrase(records.size, @kept_words)} porque #{word(records.size, reason)} (#{records.join(', ')})"
    end

    def phrase(count, words) = "#{count} #{word(count, words)}"
    def word(count, words) = count == 1 ? words.first : words.last
  end
end
