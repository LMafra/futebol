require 'rails_helper'

RSpec.describe 'Championship wizard (TICKET-0092)', type: :request do
  def page_html = Nokogiri::HTML(response.body)

  def step_labels = page_html.css('[data-role="wizard-nav"] li').map { _1.text.strip }

  def current_step = page_html.at_css('[data-role="wizard-nav"] [aria-current="step"]')&.text&.strip

  shared_examples 'staged wizard' do
    it 'creates a draft on the first step, saves each step and publishes on Revisão' do
      get "#{collection_path}/new"
      expect(step_labels).to eq(['1. Dados', '2. Modalidade', '3. Esquadrão', '4. Premiação', '5. Revisão'])
      expect(current_step).to eq('1. Dados')
      expect(page_html.at_css('[data-role="wizard-why"]').text).to include('nome e pela temporada')

      post collection_path, params: { championship: { name: 'Copa Várzea', season: 2026, **dados }, step: 'dados' }
      championship = Core::Championship.find_by!(name: 'Copa Várzea')
      expect(championship).to be_draft
      expect(response).to redirect_to("#{collection_path}/#{championship.id}/edit?step=modalidade")

      patch "#{collection_path}/#{championship.id}",
            params: { championship: { kind: 'society', gender: 'feminino' }, step: 'modalidade' }
      expect(response).to redirect_to("#{collection_path}/#{championship.id}/edit?step=esquadrao")
      expect(championship.reload.cartola_forward_limit).to eq(2)

      get "#{collection_path}/#{championship.id}/edit?step=esquadrao"
      expect(current_step).to eq('3. Esquadrão')
      expect(page_html.at_css('[data-role="squad-suggestion"]').text)
        .to eq('Sugestão para Society: 1 goleiro, 2 defensores, 2 meio-campistas e 2 atacantes.')
      expect(page_html.at_css('form details summary').text).to include('Opções avançadas')

      get "#{collection_path}/#{championship.id}/edit?step=revisao"
      review = page_html.at_css('[data-role="wizard-review"]').text
      expect(review).to include('Society · Feminino · Adulto · Amador', 'Sem premiação')
      expect(page_html.at_css('input[type="submit"]')['value']).to eq('Publicar campeonato')

      patch "#{collection_path}/#{championship.id}", params: { step: 'revisao' }
      expect(response).to redirect_to("#{collection_path}/#{championship.id}")
      expect(championship.reload).to be_published
    end

    it 're-renders the step with errors when it does not validate' do
      post collection_path, params: { championship: { name: '', season: '' }, step: 'dados' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(current_step).to eq('1. Dados')
      expect(Core::Championship.where(name: '')).to be_empty
    end

    it 'keeps a single page without the wizard once published' do
      get "#{collection_path}/#{published.id}/edit"

      expect(page_html.at_css('[data-role="wizard-nav"]')).to be_nil
      expect(page_html.css('fieldset legend').map { _1.text.strip }).to include('Dados', 'Modalidade', 'Esquadrão')
    end
  end

  context 'as admin' do
    let(:collection_path) { '/admin/championships' }
    let(:published) { create(:championship) }
    let(:dados) { { external_id: 'copa-varzea' } }

    before { sign_in(create(:user, :admin)) }

    it_behaves_like 'staged wizard'
  end

  context 'as gestor' do
    let(:manager) { create(:user, :manager) }
    let(:collection_path) { '/gestor/championships' }
    let(:published) { create(:championship, manager:) }
    let(:dados) { {} }

    before { sign_in(manager) }

    it_behaves_like 'staged wizard'

    it 'creates the draft under the signed-in gestor' do
      post collection_path, params: { championship: { name: 'Copa do Bairro', season: 2026 }, step: 'dados' }

      expect(Core::Championship.find_by!(name: 'Copa do Bairro').manager).to eq(manager)
    end
  end
end
