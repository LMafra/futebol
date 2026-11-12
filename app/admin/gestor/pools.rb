ActiveAdmin.register Bolao::Pool, as: 'Pool', namespace: :gestor do
  menu parent: 'Bolão', label: 'Bolões', priority: 1

  actions :index, :show
  includes :championship, :owner

  filter :name
  filter :championship, collection: -> { gestor_championships }

  index do
    id_column
    column :name
    column :championship
    column :owner
    actions defaults: false do |pool|
      item 'Ver', gestor_pool_path(pool)
    end
  end

  show do
    attributes_table do
      row :name
      row :championship
      row :owner
    end
  end
end
