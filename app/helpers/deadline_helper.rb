module DeadlineHelper
  # Human countdown label for a scheduled match kickoff (server-side companion to Stimulus countdown).
  def match_deadline_badge(match, now: Time.current)
    return unless match.status == 'scheduled' && match.match_date

    remaining = match.match_date - now
    return 'Palpites encerrados' if remaining <= 0

    "Fecha em #{format_deadline_remaining(remaining)}"
  end

  def format_deadline_remaining(seconds)
    total = seconds.to_i
    return 'menos de 1 min' if total < 60

    hours, rem = total.divmod(1.hour)
    minutes = rem / 1.minute
    return "#{hours}h #{minutes}min" if hours.positive?
    return "#{minutes} min" if minutes.positive?

    'menos de 1 min'
  end
end
