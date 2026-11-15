require 'rails_helper'

RSpec.describe Core::ImageAttachment do
  include ActiveJob::TestHelper

  let(:team) { create(:team) }
  let(:png) { { io: file_fixture('crest.png').open, filename: 'crest.png', content_type: 'image/png' } }

  it 'accepts a PNG crest and a championship logo' do
    team.crest.attach(png)
    championship = create(:championship)
    championship.logo.attach(png.merge(io: file_fixture('crest.png').open))

    expect(team.reload.crest).to be_attached
    expect(championship.reload.logo).to be_attached
  end

  it 'refuses files that are not PNG, JPEG, WebP or SVG' do
    team.crest = { io: StringIO.new('texto'), filename: 'escudo.txt', content_type: 'text/plain' }

    expect(team).not_to be_valid
    expect(team.errors[:crest]).to include('deve ser PNG, JPEG, WebP ou SVG')
  end

  it 'refuses images over 2 MB' do
    team.crest = { io: StringIO.new('x' * (2.megabytes + 1)), filename: 'grande.png', content_type: 'image/png' }

    expect(team).not_to be_valid
    expect(team.errors[:crest]).to include('deve ter até 2 MB')
  end

  it 'removes the crest when asked' do
    team.crest.attach(png)

    perform_enqueued_jobs { team.update!(remove_crest: true) }

    expect(team.reload.crest).not_to be_attached
  end
end
