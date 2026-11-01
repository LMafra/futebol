class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('RESEND_FROM', 'onboarding@resend.dev')
  layout 'mailer'
end
