require 'rails_helper'

RSpec.describe 'Championship create wizard (TICKET-0077)', type: :request do
  def page_html = Nokogiri::HTML(response.body)

  def form = page_html.at_css('form[data-controller="form-wizard"]')

  shared_examples 'staged create' do
    it 'renders the step nav hidden (no-JS safe) with the four sections as steps' do
      get new_path

      nav = form.at_css('[data-role="wizard-nav"]')
      expect(nav['hidden']).not_to be_nil
      expect(nav.css('[data-form-wizard-target="stepLink"]').map(&:text))
        .to eq(['1. Dados', '2. Esquadrão', '3. Bolão', '4. Premiação'])
      expect(form.css('fieldset[data-form-wizard-target="step"] legend').map { _1.text.strip })
        .to eq(%w[Dados Esquadrão Bolão Premiação])
      expect(form.css('[data-role="wizard-controls"] button').map(&:text)).to eq(%w[Voltar Continuar])
      expect(form['data-action']).to eq('keydown->form-wizard#submitOrAdvance')
    end

    it 'keeps a single page with sections on edit' do
      get edit_path

      expect(form.css('fieldset[data-form-wizard-target="step"]').size).to eq(4)
      expect(form.at_css('[data-role="wizard-nav"]')).to be_nil
      expect(form.at_css('[data-role="wizard-controls"]')).to be_nil
    end
  end

  context 'as admin' do
    let(:championship) { create(:championship) }
    let(:new_path) { '/admin/championships/new' }
    let(:edit_path) { "/admin/championships/#{championship.id}/edit" }

    before { sign_in(create(:user, :admin)) }

    it_behaves_like 'staged create'

    it 're-renders the wizard with the failing section flagged after a single POST' do
      post '/admin/championships', params: { championship: { name: '', season: '' } }

      expect(form.at_css('[data-role="wizard-nav"]')).to be_present
      failing = form.css('fieldset[data-form-wizard-target="step"]').find { _1.at_css('.error, .inline-errors') }
      expect(failing.at_css('legend').text.strip).to eq('Dados')
    end
  end

  context 'as gestor' do
    let(:manager) { create(:user, :manager) }
    let(:championship) { create(:championship, manager:) }
    let(:new_path) { '/gestor/championships/new' }
    let(:edit_path) { "/gestor/championships/#{championship.id}/edit" }

    before { sign_in(manager) }

    it_behaves_like 'staged create'
  end
end
