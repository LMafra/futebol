require 'rails_helper'

RSpec.describe LinkClassesHelper, type: :helper do
  it 'underlines every text link at rest' do
    %i[inline_link_classes title_link_classes support_link_classes].each do |role|
      expect(helper.public_send(role).split).to include('underline', 'underline-offset-2')
    end
  end

  it 'gives inline links weight and a tone, and accepts extra classes' do
    expect(helper.inline_link_classes('mt-2').split).to include('font-semibold', 'text-pitch', 'mt-2')
    expect(helper.inline_link_classes(tone: :ink).split).to include('text-ink')
  end

  it 'keeps support links quiet and title links in the heading font' do
    expect(helper.support_link_classes.split).to include('text-graphite', 'hover:text-ink')
    expect(helper.title_link_classes.split).not_to include('font-semibold', 'text-pitch')
  end
end
