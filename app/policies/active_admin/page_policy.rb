module ActiveAdmin
  # Custom admin pages (ActiveAdmin.register_page). PunditAdapter authorizes the page itself as show? and each
  # page_action by its name; the actions also authorize their record (e.g. Core::MatchPolicy#revert?).
  class PagePolicy < ApplicationPolicy
    def finalize? = admin?
    def revert? = admin?
  end
end
