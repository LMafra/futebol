# "Casa × Fora" as a link to the public match page (/partidas/:id); plain text for a match not saved yet (previews).
module MatchLinksHelper
  def match_title(match)
    title = safe_join([match.home_team.name, ' ', tag.span('×', class: 'text-graphite'), ' ', match.away_team.name])
    return title unless match.persisted?

    link_to title, public_match_path(match), class: title_link_classes
  end
end
