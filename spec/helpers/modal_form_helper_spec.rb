require 'rails_helper'

RSpec.describe ModalFormHelper, type: :helper do
  it 'renders FormErrorSummary for modal validation messages' do
    flash[:modal] = { 'id' => 'player', 'messages' => ['Nome é obrigatório', 'Posição é obrigatória'] }
    allow(helper).to receive(:params).and_return(ActionController::Parameters.new(modal: 'player'))

    html = helper.send(:modal_error_summary, :player)

    expect(html).to include('data-role="form-error-summary"')
    expect(html).to include('2 campos precisam de atenção')
    expect(html).not_to include('data-role="admin-toast"')
  end
end
