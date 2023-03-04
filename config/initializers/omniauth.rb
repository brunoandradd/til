# frozen_string_literal:true

OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer
  provider :google_oauth2,
           ENV['GOOGLE_CLIENT_ID'],
           ENV['GOOGLE_CLIENT_SECRET'],
           { scope: 'email', hd: ENV.fetch('PERMITTED_DOMAINS', 'rarolabs.com.br') }
end

OmniAuth.config.allowed_request_methods = %i[post get]
