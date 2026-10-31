require 'view_component/test_helpers'

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/components/}) { |metadata| metadata[:type] ||= :component }
  config.include ViewComponent::TestHelpers, type: :component
end

RSpec.shared_examples 'a ui component with four states' do |preview:|
  it 'declares default, loading, empty and error' do
    expect(described_class::STATES).to eq(%i[default loading empty error])
  end

  it 'raises ArgumentError for an unknown state' do
    expect { described_class.new(state: :broken) }.to raise_error(ArgumentError, /invalid state :broken/)
  end

  it 'has exactly one Lookbook preview per state' do
    expect(preview.public_instance_methods(false)).to match_array(described_class::STATES)
  end

  it 'renders every state with a matching data-ui-state root and no default-only arguments' do
    (described_class::STATES - [:default]).each do |state|
      expect(render_inline(described_class.new(state:)).css("[data-ui-state='#{state}']")).to be_present
    end
  end
end
