require 'rails_helper'

RSpec.describe Ui::KpiCardComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::KpiCardComponentPreview

  it 'renders normal, zero and alert states' do
    normal = render_inline(described_class.new(value: 3, label: 'Pendentes', action_text: 'Ver fila',
                                               action_path: '/admin?urgency=high', status: :normal))
    expect(normal.at_css('[data-kpi-status="normal"]').text).to include('3', 'Pendentes', 'Ver fila')
    expect(normal.at_css('a[href="/admin?urgency=high"]')).to be_present

    zero = render_inline(described_class.new(value: 0, label: 'Pendentes', status: :zero))
    expect(zero.at_css('[data-kpi-status="zero"]').text).to include('0', 'Tudo em dia')
    expect(zero.at_css('svg')).to be_present

    alert = render_inline(described_class.new(value: 2, label: 'Ao vivo', status: :alert, action_path: '/admin'))
    expect(alert.at_css('[data-kpi-status="alert"]')).to be_present
    expect(alert.at_css('.border-l-cartola')).to be_present
  end
end
