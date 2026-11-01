module Ui
  class ScoreboardComponent < BaseComponent
    include Turbo::FramesHelper

    STATUS_LABELS = {
      'scheduled' => 'Agendado', 'live' => 'Ao vivo', 'finished' => 'Encerrado', 'scored' => 'Pontuado'
    }.freeze

    attr_reader :match, :retry_path

    def initialize(match: nil, state: :default, retry_path: nil)
      super(state:)
      @match = match
      @retry_path = retry_path
      require_in_default_state!(:match, match)
    end

    private

    def frame_id = match&.persisted? ? dom_id(match, :scoreboard) : 'scoreboard'

    def live? = match.status == 'live'

    def status_label = STATUS_LABELS.fetch(match.status, match.status)

    def score(value) = value.nil? ? '–' : value

    def kickoff = match.match_date&.strftime('%d/%m · %H:%M')

    def crest(team)
      return image_tag(team.crest_url, alt: team.name, class: 'size-8 object-contain') if team.crest_url.present?

      tag.span(team.short_name, class: 'inline-flex size-8 items-center justify-center rounded-sm border ' \
                                       'border-rule text-xs font-bold tracking-wide')
    end
  end
end
