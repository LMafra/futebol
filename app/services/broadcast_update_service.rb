class BroadcastUpdateService
  THROTTLE_WINDOW = 5.seconds

  def self.call(match:) = new(match).call

  def self.cache_key(match) = "broadcast:match:#{match.id}"

  def initialize(match)
    @match = match
  end

  # Only the caller whose atomic write wins broadcasts; the rest of the window is a no-op.
  def call
    return false unless Rails.cache.write(self.class.cache_key(@match), 1, unless_exist: true,
                                                                           expires_in: THROTTLE_WINDOW)

    Turbo::StreamsChannel.broadcast_replace_to(
      @match,
      target: ActionView::RecordIdentifier.dom_id(@match, :scoreboard),
      renderable: Ui::ScoreboardComponent.new(match: @match),
      layout: false
    )
    true
  end
end
