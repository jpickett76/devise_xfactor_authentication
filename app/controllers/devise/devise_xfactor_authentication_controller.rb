require 'devise/version'

class Devise::DeviseXfactorAuthenticationController < DeviseController
  prepend_before_action :authenticate_scope!
  before_action :prepare_and_validate, :handle_devise_xfactor_authentication

  def show
    unless resource.uses_two_factor?
      after_devise_xfactor_success_for(resource)
    end
  end

  def update
    render :show and return if params[:code].nil?

    if resource.authenticate_otp(params[:code])
      after_devise_xfactor_success_for(resource)
    else
      after_devise_xfactor_fail_for(resource)
    end
  end

  def resend_code
    resource.send_new_otp
    redirect_to send("#{resource_name}_devise_xfactor_authentication_path"), notice: I18n.t('devise.devise_xfactor_authentication.code_has_been_sent')
  end

  private

  def after_devise_xfactor_success_for(resource)
    set_remember_devise_xfactor_cookie(resource)

    warden.session(resource_name)[DeviseXfactorAuthentication::NEED_AUTHENTICATION] = false
    # For compatability with devise versions below v4.2.0
    # https://github.com/plataformatec/devise/commit/2044fffa25d781fcbaf090e7728b48b65c854ccb
    if respond_to?(:bypass_sign_in)
      bypass_sign_in(resource, scope: resource_name)
    else
      sign_in(resource_name, resource, bypass: true)
    end
    set_flash_message!(:notice, :success)
    resource.update(second_factor_attempts_count: 0)

    redirect_to after_devise_xfactor_success_path_for(resource)
  end

  def set_remember_devise_xfactor_cookie(resource)
    expires_seconds = resource.class.remember_otp_session_for_seconds

    if expires_seconds && expires_seconds > 0
      cookies.signed[DeviseXfactorAuthentication::REMEMBER_TFA_COOKIE_NAME] = {
          value: "#{resource.class}-#{resource.public_send(Devise.second_factor_resource_id)}",
          expires: expires_seconds.seconds.from_now
      }
    end
  end

  def after_devise_xfactor_success_path_for(resource)
    stored_location_for(resource_name) || :root
  end

  def after_devise_xfactor_fail_for(resource)
    resource.second_factor_attempts_count += 1
    resource.save
    set_flash_message :alert, :attempt_failed, now: true

    if resource.max_login_attempts?
      sign_out(resource)
      render :max_login_attempts_reached
    else
      render :show
    end
  end

  def authenticate_scope!
    self.resource = send("current_#{resource_name}")
  end

  def prepare_and_validate
    redirect_to :root and return if resource.nil?
    @limit = resource.max_login_attempts
    if resource.max_login_attempts?
      sign_out(resource)
      render :max_login_attempts_reached and return
    end
  end
end
