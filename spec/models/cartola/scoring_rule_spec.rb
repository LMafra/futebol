require 'rails_helper'

RSpec.describe Cartola::ScoringRule do
  it 'stores goal_points, assist_points, yellow_card_penalty and red_card_penalty' do
    rule = create(:cartola_scoring_rule, goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)

    expect(rule.reload).to have_attributes(goal_points: 8, assist_points: 5, yellow_card_penalty: 1,
                                           red_card_penalty: 3)
  end

  it 'requires every point column to be present and non-negative' do
    %i[goal_points assist_points yellow_card_penalty red_card_penalty].each do |column|
      expect(build(:cartola_scoring_rule, column => nil)).not_to be_valid
      expect(build(:cartola_scoring_rule, column => -1)).not_to be_valid
    end
  end

  it 'requires a unique name' do
    create(:cartola_scoring_rule, name: 'padrao')

    expect(build(:cartola_scoring_rule, name: 'padrao')).not_to be_valid
  end

  describe 'database constraints' do
    %w[goal_points assist_points yellow_card_penalty red_card_penalty].each do |column|
      it "raises StatementInvalid for a negative #{column}" do
        rule = create(:cartola_scoring_rule)

        expect { rule.update_columns(column => -1) }
          .to raise_error(ActiveRecord::StatementInvalid, /cartola_scoring_rules_#{column}_non_negative/)
      end
    end

    it 'raises RecordNotUnique for a duplicated name' do
      create(:cartola_scoring_rule, name: 'padrao')

      expect { build(:cartola_scoring_rule, name: 'padrao').save!(validate: false) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '.default' do
    it 'returns the rule named padrao' do
      rule = create(:cartola_scoring_rule, name: described_class::DEFAULT_NAME)
      create(:cartola_scoring_rule, name: 'liga-amigos')

      expect(described_class.default).to eq(rule)
    end
  end
end
