# Server side of the championship wizard (ADR 0006), for the /admin and /gestor resources: the first step creates a
# draft, each later step saves before the next one opens, and Revisão publishes. Published championships keep the
# single-page edit.
module ChampionshipWizardActions
  STEP_KEYS = ChampionshipWizardHelper::STEP_KEYS

  def create
    build_resource
    resource.status = 'draft'
    if resource.save
      redirect_to edit_resource_path(resource, step: STEP_KEYS.second), notice: 'Rascunho salvo. Agora a modalidade.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    return update_published unless resource.draft?

    step = params[:step].presence_in(STEP_KEYS) || STEP_KEYS.first
    assign_step_attributes
    resource.status = 'published' if step == STEP_KEYS.last
    save_step(step)
  end

  private

  def assign_step_attributes
    resource.assign_attributes(*resource_params) if params.key?(resource_request_name)
    authorize_resource!(resource)
  end

  def save_step(step)
    if resource.save
      redirect_after_step(step)
    else
      resource.status = 'draft'
      render :edit, status: :unprocessable_content
    end
  end

  def redirect_after_step(step)
    return redirect_to(resource_path, notice: 'Campeonato publicado. Agora inscreva os times.') if resource.published?

    redirect_to edit_resource_path(resource, step: STEP_KEYS[STEP_KEYS.index(step) + 1]), notice: 'Etapa salva.'
  end

  def update_published
    update! do |success, failure|
      success.html { redirect_to resource_path, notice: 'Campeonato atualizado' }
      failure.html { render :edit, status: :unprocessable_content }
    end
  end
end
