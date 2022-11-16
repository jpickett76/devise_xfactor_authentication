require 'devise_xfactor_authentication/version'
require 'devise'
require 'active_support/concern'
require "active_model"
require "active_support/core_ext/class/attribute_accessors"
require "cgi"

module Devise
  mattr_accessor :max_login_attempts
  @@max_login_attempts = 3

  mattr_accessor :allowed_otp_drift_seconds
  @@allowed_otp_drift_seconds = 30

  mattr_accessor :otp_length
  @@otp_length = 6

  mattr_accessor :direct_otp_length
  @@direct_otp_length = 6

  mattr_accessor :direct_otp_valid_for
  @@direct_otp_valid_for = 5.minutes

  mattr_accessor :remember_otp_session_for_seconds
  @@remember_otp_session_for_seconds = 0

  mattr_accessor :otp_secret_encryption_key
  @@otp_secret_encryption_key = ''

  mattr_accessor :second_factor_resource_id
  @@second_factor_resource_id = 'id'

  mattr_accessor :delete_cookie_on_logout
  @@delete_cookie_on_logout = false

  mattr_accessor :twilio_account_sid
  @@twilio_account_sid = ''

  mattr_accessor :twilio_auth_token
  @@twilio_auth_token = ''
end

module DeviseXfactorAuthentication
  NEED_AUTHENTICATION = 'need_devise_xfactor_authentication'
  REMEMBER_TFA_COOKIE_NAME = "remember_tfa"

  autoload :Schema, 'devise_xfactor_authentication/schema'
  module Controllers
    autoload :Helpers, 'devise_xfactor_authentication/controllers/helpers'
  end
end

Devise.add_module :devise_xfactor_authenticatable, :model => 'devise_xfactor_authentication/models/devise_xfactor_authenticatable', :controller => :devise_xfactor_authentication, :route => :devise_xfactor_authentication

require 'devise_xfactor_authentication/orm/active_record' if defined?(ActiveRecord::Base)
require 'devise_xfactor_authentication/routes'
require 'devise_xfactor_authentication/models/devise_xfactor_authenticatable'
require 'devise_xfactor_authentication/rails'
