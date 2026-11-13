ActiveAdmin.register Bolao::Pool, as: 'Pool', namespace: :gestor do
  menu parent: 'Participantes', label: 'Bolões', priority: 1

  permit_params :name, :championship_id

  actions :index, :show, :new, :create
  includes :championship, :owner

  AdminNameSearch.register(self)
  filter :championship, collection: -> { gestor_championships }

  index do
    id_column
    column :name
    column :championship
    column('Código', &:code)
    actions defaults: false do |pool|
      text_node admin_icon_action_link('Abrir', gestor_pool_path(pool), :view, subject: pool.name)
    end
  end

  show do
    attributes_table do
      row :name
      row :championship
      row('Código') { |pool| tag.span(pool.code, class: 'font-numeric text-xl tracking-widest') }
      row('Participantes') { |pool| pool.memberships.size }
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs 'Bolão' do
      f.input :name, hint: 'É o nome que os participantes veem.'
      f.input :championship, collection: gestor_championships, include_blank: false
      li class: 'input optional' do
        para 'Depois de criar, compartilhe o código do bolão: é com ele que os participantes entram.',
             class: 'inline-hints'
      end
    end
    f.actions
  end

  controller do
    before_build { |pool| pool.owner = current_user }

    def create
      create! do |success, _failure|
        success.html { redirect_to resource_path, notice: "Bolão criado. Compartilhe o código #{resource.code}." }
      end
    end
  end
end
