module ActionDispatch::Routing
  class Mapper
    protected

      def devise_devise_xfactor_authentication(mapping, controllers)
        resource :devise_xfactor_authentication, 
        :only => [:show, :update, :resend_code], 
        :path => mapping.path_names[:devise_xfactor_authentication], 
        :controller => controllers[:devise_xfactor_authentication] do
          collection { get "resend_code" }  
        end
      end
  end
end
