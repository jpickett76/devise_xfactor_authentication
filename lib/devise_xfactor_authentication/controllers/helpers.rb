module DeviseXfactorAuthentication
  module Controllers
    module Helpers
      extend ActiveSupport::Concern

      included do
        before_action :handle_devise_xfactor_authentication
      end

      private

      def handle_devise_xfactor_authentication
        unless devise_controller?
          Devise.mappings.keys.flatten.any? do |scope|
            if signed_in?(scope) and warden.session(scope)[DeviseXfactorAuthentication::NEED_AUTHENTICATION]
              handle_failed_second_factor(scope)
            end
          end
        end
      end

      def handle_failed_second_factor(scope)
        if request.format.present? and request.format.html?
          session["#{scope}_return_to"] = request.original_fullpath if request.get?
          redirect_to devise_xfactor_authentication_path_for(scope)
        else
          head :unauthorized
        end
      end

      def devise_xfactor_authentication_path_for(resource_or_scope = nil)
        scope = Devise::Mapping.find_scope!(resource_or_scope)
        change_path = "#{scope}_devise_xfactor_authentication_path"
        send(change_path)
      end

    end
  end
end

module Devise
  module Controllers
    module Helpers
      def is_fully_authenticated?
        !session["warden.user.user.session"].try(:[], DeviseXfactorAuthentication::NEED_AUTHENTICATION)
      end
    end
  end
end
