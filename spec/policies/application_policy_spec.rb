require 'rails_helper'

RSpec.describe ApplicationPolicy do
  it_behaves_like 'an admin-only policy'
end
