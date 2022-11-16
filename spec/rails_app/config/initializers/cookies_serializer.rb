if Rails::VERSION::MAJOR >= 4
  Rails.application.config.action_dispatch.cookies_serializer = :json
end
