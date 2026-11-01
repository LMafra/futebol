# strong_migrations is a development-only gem: it checks migrations while they are written, not when deploys run them.
return unless defined?(StrongMigrations)

# Migrations use sequential versions (20261031000NNN), not wall-clock ones: start right after the last existing one.
StrongMigrations.start_after = 20_261_031_000_030

StrongMigrations.target_version = 18
StrongMigrations.lock_timeout = 10.seconds
StrongMigrations.statement_timeout = 1.hour
StrongMigrations.auto_analyze = true
