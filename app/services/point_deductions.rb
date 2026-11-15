# Dedução de pontos on the championship standings, from the Classificação tab of /admin and /gestor. Each change
# writes a Core::AuditLog on the championship in the same transaction; revoking keeps the deduction.
module PointDeductions
  # attributes: team_id, points and reason. Returns the deduction, with errors when it was not saved.
  def self.deduct(championship:, attributes:, actor:, ip_address:)
    deduction = championship.point_deductions.build(**attributes, created_by: actor)
    Core::PointDeduction.transaction do
      audit!('championship.points_deducted', deduction, actor, ip_address) if deduction.save
    end
    deduction
  end

  def self.revoke(deduction, actor:, ip_address:)
    Core::PointDeduction.transaction do
      deduction.revoke!(actor)
      audit!('championship.points_deduction_revoked', deduction, actor, ip_address)
    end
  end

  def self.audit!(action, deduction, actor, ip_address)
    Core::AuditLog.create!(action:, user: actor, auditable: deduction.championship, ip_address:,
                           metadata: deduction.slice(:id, :team_id, :points, :reason))
  end
end
