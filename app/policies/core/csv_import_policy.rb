module Core
  # An import is an upload plus a background job; its result is never edited afterwards.
  class CsvImportPolicy < ApplicationPolicy
    def update? = false
    def destroy? = false

    def import? = create?
  end
end
