class User < ActiveRecord::Base
  devise :devise_xfactor_authenticatable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one_time_password

  def send_devise_xfactor_authentication_code(code)
    SMSProvider.send_message(to: phone_number, body: code)
  end

  def phone_number
    '14159341234'
  end
end
