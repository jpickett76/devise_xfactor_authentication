module DeviseXfactorAuthenticatable
  module Generators
    class DeviseXfactorAuthenticationGenerator < Rails::Generators::NamedBase
      namespace "devise_xfactor_authentication"

      desc "Adds :devise_xfactor_authenticable directive in the given model. It also generates an active record migration."

      def inject_devise_xfactor_authentication_content
        path = File.join("app", "models", "#{file_path}.rb")
        inject_into_file(path, "devise_xfactor_authenticatable, :", :after => "devise :") if File.exists?(path)
      end

      hook_for :orm

    end
  end
end
