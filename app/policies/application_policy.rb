# Deny-all for regular users and visitors; admins may do everything a subclass does not narrow down.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = admin?
  def show? = admin?
  def create? = admin?
  def new? = create?
  def update? = admin?
  def edit? = update?
  def destroy? = admin?
  # ActiveAdmin batch destroy (PunditAdapter maps DESTROY on a class to destroy_all?).
  def destroy_all? = destroy?

  private

  def admin? = user.present? && user.admin?

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.present? && user.admin?

      scope.none
    end
  end
end
