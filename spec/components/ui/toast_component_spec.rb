require 'rails_helper'

RSpec.describe Ui::ToastComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::ToastComponentPreview

  it 'renders a pitch success toast with the message' do
    page = render_inline(described_class.new(message: 'Campeonato atualizado', variant: :success))

    toast = page.at_css('[data-role="admin-toast"]')
    expect(toast['data-variant']).to eq('success')
    expect(toast['class']).to include('bg-pitch/10', 'border-pitch/30')
    expect(toast.text).to include('Campeonato atualizado')
  end

  it 'renders an error toast on the loss tint' do
    page = render_inline(described_class.new(message: 'Falhou', variant: :error))

    toast = page.at_css('[data-role="admin-toast"]')
    expect(toast['role']).to eq('alert')
    expect(toast['class']).to include('bg-loss')
  end

  it 'renders the alert toast as an alert with ink text on a cartola tint' do
    page = render_inline(described_class.new(message: 'Atenção', variant: :alert))

    toast = page.at_css('[data-role="admin-toast"]')
    expect(toast['role']).to eq('alert')
    expect(toast['class']).to include('bg-cartola/15', 'border-cartola')
    expect(page.to_html).not_to include('text-cartola')
  end
end
