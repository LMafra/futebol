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

  it 'lets the message name the toast and offers a 40px close button' do
    page = render_inline(described_class.new(message: 'Salvo', variant: :notice))

    toast = page.at_css('[data-role="admin-toast"]')
    expect(toast['aria-label']).to be_nil
    expect(toast['data-controller']).to eq('dismiss')
    close = page.at_css('button[data-role="toast-close"]')
    expect([close['aria-label'], close['data-action']]).to eq(['Fechar aviso', 'dismiss#close'])
    expect(close['class']).to include('h-10', 'w-10')
  end
end
