module AdminMatchActionsHelper
  # One primary action per match page: Finalizar once scouts exist, Scouts before that.
  def admin_match_step_classes(match, step)
    primary = Cartola::PlayerScore.kept.exists?(match_id: match.id) ? :finalize : :scouts
    step == primary ? AdminHelper::ADMIN_BUTTON_CLASSES : AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES
  end
end
