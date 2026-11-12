# Deny-all for regular users and visitors; admins may do everything a subclass does not narrow down.
# Championship managers only get what a subclass grants them, on the championships they manage.
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
  def destroy_all? = destroy?

  private

  def admin? = user.present? && user.admin?
  def manager? = user.present? && user.manager?
  def manages?(championship) = user.present? && championship.present? && user.can_manage?(championship)
  def record_instance? = !record.is_a?(Class)

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.present? && user.admin?
      return managed_scope if user.present? && user.manager?

      scope.none
    end

    private

    def managed_scope = scope.none
    def managed_championships = Core::Championship.managed_by(user)
  end
end
