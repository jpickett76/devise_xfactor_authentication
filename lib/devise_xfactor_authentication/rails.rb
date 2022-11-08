module DeviseXfactorAuthentication
  class Engine < ::Rails::Engine
    ActiveSupport.on_load(:action_controller) do
      include DeviseXfactorAuthentication::Controllers::Helpers
    end
  end
end
