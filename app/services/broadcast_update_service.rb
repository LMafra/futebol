# Live update of the public match page (/partidas/:id): replaces its scoreboard and timeline (matches/_live) for
# everyone subscribed to the match stream. At most one broadcast per match every THROTTLE_WINDOW; the calls
# inside the window schedule one trailing broadcast at its end (MatchBroadcastJob), so the page always ends up
# with the last lance.
class BroadcastUpdateService
  THROTTLE_WINDOW = 5.seconds

  def self.call(match:) = new(match).call

  def self.cache_key(match) = "broadcast:match:#{match.id}"

  def self.trailing_key(match) = "#{cache_key(match)}:trailing"

  def initialize(match)
    @match = match
  end

  # Only the caller whose atomic write wins broadcasts; the rest of the window schedules the trailing one.
  def call
    unless Rails.cache.write(self.class.cache_key(@match), 1, unless_exist: true, expires_in: THROTTLE_WINDOW)
      schedule_trailing
      return false
    end

    broadcast!
    true
  end

  def broadcast!
    match = Core::Match.includes(home_team: { crest_attachment: :blob }, away_team: { crest_attachment: :blob })
                       .find(@match.id)
    Turbo::StreamsChannel.broadcast_replace_to(
      match,
      target: ActionView::RecordIdentifier.dom_id(match, :live),
      partial: 'matches/live',
      locals: { match:, events: Cartola::ScoutEvent.timeline(match) }
    )
  end

  private

  def schedule_trailing
    return unless Rails.cache.write(self.class.trailing_key(@match), 1, unless_exist: true,
                                                                        expires_in: THROTTLE_WINDOW)

    MatchBroadcastJob.set(wait: THROTTLE_WINDOW).perform_later(@match.id)
  end
end
