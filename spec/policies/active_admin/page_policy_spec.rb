require 'rails_helper'

RSpec.describe ActiveAdmin::PagePolicy do
  it_behaves_like 'an admin-only policy', extra_admin_actions: %i[finalize? revert?]
end
