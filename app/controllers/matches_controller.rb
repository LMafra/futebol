# Public page of a match (/partidas/:id): big scoreboard and the timeline of lances, updated live through Turbo
# Streams (BroadcastUpdateService). A match the visitor cannot see is a 404 (Core::MatchPolicy#public_show?).
class MatchesController < ApplicationController
  allow_unauthenticated_access

  def show
    @match = Core::Match.includes(:championship, home_team: { crest_attachment: :blob },
                                                 away_team: { crest_attachment: :blob }).find(params[:id])
    raise ActiveRecord::RecordNotFound unless policy(@match).public_show?

    authorize @match, :public_show?
    @events = Cartola::ScoutEvent.timeline(@match)
  end
end
