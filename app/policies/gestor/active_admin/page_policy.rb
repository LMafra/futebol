module Gestor
  module ActiveAdmin
    class PagePolicy < ::ActiveAdmin::PagePolicy
      def show? = admin? || manager?

      # Custom page actions (parent is admin-only; gestor scoring pages authorize the match as well).
      def record? = admin? || manager?
      def finalize? = admin? || manager?
      def revert? = admin? || manager?
    end
  end
end
