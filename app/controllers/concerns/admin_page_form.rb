# For ActiveAdmin register_page controllers whose page_action re-renders the page (e.g. with validation errors):
# ActiveAdmin looks the page presenter up by action name, which would render an empty page for a page_action.
module AdminPageForm
  private

  def page_presenter = active_admin_config.get_page_presenter(:index)

  def render_page(status:)
    render 'active_admin/page/index', status:
  end
end
