class AddPublicProfileConsentedAtToCoreUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :core_users, :public_profile_consented_at, :datetime
  end
end
