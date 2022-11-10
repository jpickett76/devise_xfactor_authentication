# Two factor authentication for Devise
## This is a fork of the orignal two_factor_authentication by plugin for devise forked from Houdini/two_factor_authentication
## It is currently under reconfiguration, so a some of the below documentation is incorrect. 
## I will attept to have the readme redone on some level by 11/12/2022 - JP
<!---
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/Houdini/two_factor_authentication?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build Status](https://travis-ci.org/Houdini/two_factor_authentication.svg?branch=master)](https://travis-ci.org/Houdini/two_factor_authentication)
[![Code Climate](https://codeclimate.com/github/Houdini/two_factor_authentication.svg)](https://codeclimate.com/github/Houdini/two_factor_authentication)
--->



## Features

* Support for 2 types of OTP codes
 1. Codes delivered directly to the user
 2. TOTP (Google Authenticator) codes based on a shared secret (HMAC)
* Configurable OTP code digit length
* Configurable max login attempts
* Customizable logic to determine if a user needs two factor authentication
* Configurable period where users won't be asked for 2FA again
* Option to encrypt the TOTP secret in the database, with iv and salt

## Configuration

### Initial Setup

In a Rails environment, require the gem in your Gemfile:

    gem 'two_factor_authentication'

Once that's done, run:

    bundle install

Note that Ruby 2.1 or greater is required.

### Installation

#### Automatic initial setup

To set up the model and database migration file automatically, run the
following command:

    bundle exec rails g two_factor_authentication MODEL

Where MODEL is your model name (e.g. User or Admin). This generator will add
`:two_factor_authenticatable` to your model's Devise options and create a
migration in `db/migrate/`, which will add the following columns to your table:

- `:second_factor_attempts_count`
- `:encrypted_otp_secret_key`
- `:encrypted_otp_secret_key_iv`
- `:encrypted_otp_secret_key_salt`
- `:direct_otp`
- `:direct_otp_sent_at`
- `:totp_timestamp`

#### Manual initial setup

If you prefer to set up the model and migration manually, add the
`:two_factor_authenticatable` option to your existing devise options, such as:

```ruby
devise :database_authenticatable, :registerable, :recoverable, :rememberable,
       :trackable, :validatable, :two_factor_authenticatable
```

Then create your migration file using the Rails generator, such as:

```
rails g migration AddTwoFactorFieldsToUsers second_factor_attempts_count:integer encrypted_otp_secret_key:string:index encrypted_otp_secret_key_iv:string encrypted_otp_secret_key_salt:string direct_otp:string direct_otp_sent_at:datetime totp_timestamp:timestamp
```

Open your migration file (it will be in the `db/migrate` directory and will be
named something like `20151230163930_add_two_factor_fields_to_users.rb`), and
add `unique: true` to the `add_index` line so that it looks like this:

```ruby
add_index :users, :encrypted_otp_secret_key, unique: true
```
Save the file.

#### Complete the setup

Run the migration with:

    bundle exec rake db:migrate

Add the following line to your model to fully enable two-factor auth:

    has_one_time_password(encrypted: true)

Set config values in `config/initializers/devise.rb`:

```ruby
config.max_login_attempts = 3  # Maximum second factor attempts count.
config.allowed_otp_drift_seconds = 30  # Allowed TOTP time drift between client and server.
config.otp_length = 6  # TOTP code length
config.direct_otp_valid_for = 5.minutes  # Time before direct OTP becomes invalid
config.direct_otp_length = 6  # Direct OTP code length
config.remember_otp_session_for_seconds = 30.days  # Time before browser has to perform 2fA again. Default is 0.
config.otp_secret_encryption_key = ENV['OTP_SECRET_ENCRYPTION_KEY']
config.second_factor_resource_id = 'id' # Field or method name used to set value for 2fA remember cookie
config.delete_cookie_on_logout = false # Delete cookie when user signs out, to force 2fA again on login
```
The `otp_secret_encryption_key` must be a random key that is not stored in the
DB, and is not checked in to your repo. It is recommended to store it in an
environment variable, and you can generate it with `bundle exec rake secret`.

Override the method in your model in order to send direct OTP codes. This is
automatically called when a user logs in unless they have TOTP enabled (see
below):

```ruby
def send_two_factor_authentication_code(code)
  # Send code via SMS, etc.
end
```

### Customisation and Usage

By default, second factor authentication is required for each user. You can
change that by overriding the following method in your model:

```ruby
def need_two_factor_authentication?(request)
  request.ip != '127.0.0.1'
end
```

In the example above, two factor authentication will not be required for local
users.

This gem is compatible with [Google Authenticator](https://support.google.com/accounts/answer/1066447?hl=en).
To enable this a shared secret must be generated by invoking the following
method on your model:

```ruby
user.generate_totp_secret
```

This must then be shared via a provisioning uri:

```ruby
user.provisioning_uri # This assumes a user model with an email attribute
```

This provisioning uri can then be turned in to a QR code if desired so that
users may add the app to Google Authenticator easily.  Once this is done, they
may retrieve a one-time password directly from the Google Authenticator app.

#### Overriding the view

The default view that shows the form can be overridden by adding a
file named `show.html.erb` (or `show.html.haml` if you prefer HAML)
inside `app/views/devise/two_factor_authentication/` and customizing it.
Below is an example using ERB:


```html
<h2>Hi, you received a code by email, please enter it below, thanks!</h2>

<%= form_tag([resource_name, :two_factor_authentication], :method => :put) do %>
  <%= text_field_tag :code %>
  <%= submit_tag "Log in!" %>
<% end %>

<%= link_to "Sign out", destroy_user_session_path, :method => :delete %>
```

#### Upgrading from version 1.X to 2.X

The following database fields are new in version 2.

- `direct_otp`
- `direct_otp_sent_at`
- `totp_timestamp`

To add them, generate a migration such as:

    $ rails g migration AddTwoFactorFieldsToUsers direct_otp:string direct_otp_sent_at:datetime totp_timestamp:timestamp

The `otp_secret_key` is only required for users who use TOTP (Google Authenticator) codes,
so unless it has been shared with the user it should be set to `nil`.  The
following pseudo-code is an example of how this might be done:

```ruby
User.find_each do |user| do
  if !uses_authenticator_app(user)
    user.otp_secret_key = nil
    user.save!
  end
end
```

#### Adding the TOTP encryption option to an existing app

If you've already been using this gem, and want to start encrypting the OTP
secret key in the database (recommended), you'll need to perform the following
steps:

1. Generate a migration to add the necessary columns to your model's table:

   ```
   rails g migration AddEncryptionFieldsToUsers encrypted_otp_secret_key:string:index encrypted_otp_secret_key_iv:string encrypted_otp_secret_key_salt:string
   ```

   Open your migration file (it will be in the `db/migrate` directory and will be
   named something like `20151230163930_add_encryption_fields_to_users.rb`), and
   add `unique: true` to the `add_index` line so that it looks like this:

   ```ruby
   add_index :users, :encrypted_otp_secret_key, unique: true
   ```
   Save the file.

2. Run the migration: `bundle exec rake db:migrate`

2. Update the gem: `bundle update two_factor_authentication`

3. Add `encrypted: true` to `has_one_time_password` in your model.
   For example: `has_one_time_password(encrypted: true)`

4. Generate a migration to populate the new encryption fields:
   ```
   rails g migration PopulateEncryptedOtpFields
   ```

   Open the generated file, and replace its contents with the following:
   ```ruby
   class PopulateEncryptedOtpFields < ActiveRecord::Migration
     def up
       User.reset_column_information

       User.find_each do |user|
         user.otp_secret_key = user.read_attribute('otp_secret_key')
         user.save!
       end
     end

     def down
       User.reset_column_information

       User.find_each do |user|
         user.otp_secret_key = ROTP::Base32.random_base32
         user.save!
       end
     end
   end
   ```

5. Generate a migration to remove the `:otp_secret_key` column:
   ```
   rails g migration RemoveOtpSecretKeyFromUsers otp_secret_key:string
   ```

6. Run the migrations: `bundle exec rake db:migrate`

If, for some reason, you want to switch back to the old non-encrypted version,
use these steps:

1. Remove `(encrypted: true)` from `has_one_time_password`

2. Roll back the last 3 migrations (assuming you haven't added any new ones
after them):
   ```
   bundle exec rake db:rollback STEP=3
   ```

#### Critical Security Note! Add before_action to your user registration controllers

You should have a file registrations_controller.rb in your controllers folder
to overwrite/customize user registrations. It should include the lines below, for 2FA protection of user model updates, meaning that users can only access the users/edit page after confirming 2FA fully, not simply by logging in. Otherwise the entire 2FA system can be bypassed!

   ```ruby
   class RegistrationsController < Devise::RegistrationsController
     before_action :confirm_two_factor_authenticated, except: [:new, :create, :cancel]
   
     protected
   
     def confirm_two_factor_authenticated
       return if is_fully_authenticated?

       flash[:error] = t('devise.errors.messages.user_not_authenticated')
       redirect_to user_two_factor_authentication_url
     end
   end
   ```

#### Critical Security Note! Add 2FA validation to your custom user actions

Make sure you are passing the 2FA secret codes securely and checking for them upon critical user actions, such as API key updates, user email or pgp pubkey updates, or any other changess to private/secure account-related details. Validate the secret during the initial 2FA key/secret verification by the user also, of course.

 For example, a simple account_controller.rb may look something like this:

   ```
   require 'json'

   class AccountController < ApplicationController
     before_action :require_signed_in!
     before_action :authenticate_user!
     respond_to :html, :json
     
     def account_API
       resp = {}
       begin       
         if(account_params["twoFAKey"] && account_params["twoFASecret"])
           current_user.otp_secret_key = account_params["twoFAKey"]
           if(current_user.authenticate_totp(account_params["twoFASecret"]))
             # user has validated their temporary 2FA code, save it to their account, enable 2FA on this account
             current_user.save!
             resp['success'] = "passed 2FA validation!"
           else
             resp['error'] = "failed 2FA validation!"
           end
         elsif(param[:userAccountStuff] && param[:userAccountWidget])
           #before updating important user account stuff and widgets,
           #check to see that the 2FA secret has also been passed in, and verify it...
           if(account_params["twoFASecret"] && current_user.totp_enabled? && current_user.authenticate_totp(account_params["twoFASecret"]))
             # user has passed 2FA checks, do cool user account stuff here
             ...
           else 
             # user failed 2FA check! No cool user stuff happens!             
              resp[error] = 'You failed 2FA validation!'
           end
           
             ...
           end
         else
           resp['error'] = 'unknown format error, not saved!'  
         end
       rescue Exception => e
         puts "WARNING: account api threw error : '#{e}' for user #{current_user.username}"
         #print "error trace: #{e.backtrace}\n"
         resp['error'] = "unanticipated server response"
       end
       render json: resp.to_json
     end
   
     def account_params
       params.require(:twoFA).permit(:userAccountStuff, :userAcountWidget, :twoFAKey, :twoFASecret)
     end
   end   
   ```


### Example App

[TwoFactorAuthenticationExample](https://github.com/Houdini/TwoFactorAuthenticationExample)


### Example user actions

to use an ENV VAR for the 2FA encryption key:

config.otp_secret_encryption_key = ENV['OTP_SECRET_ENCRYPTION_KEY']

to set up TOTP for Google Authenticator for user:

   ```
   current_user.otp_secret_key =  current_user.generate_totp_secret
   current_user.save!
   ```
   
( encrypted db fields are set upon user model save action,
rails c access relies on setting env var: OTP_SECRET_ENCRYPTION_KEY )

to check if user has input the correct code (from the QR display page)
before saving the user model:

   ```
   current_user.authenticate_totp('123456')
   ```

additional note:
 
   ```
   current_user.otp_secret_key
   ```
   
This returns the OTP secret key in plaintext for the user (if you have set the env var) in the console
the string used for generating the QR given to the user for their Google Auth is something like:

otpauth://totp/LABEL?secret=p6wwetjnkjnrcmpd    (example secret used here)

where LABEL should be something like "example.com (Username)", which shows up in their GA app to remind them the code is for example.com

this returns true or false with an allowed_otp_drift_seconds 'grace period'

to set TOTP to DISABLED for a user account:

   ```
   current_user.second_factor_attempts_count=nil
   current_user.encrypted_otp_secret_key=nil
   current_user.encrypted_otp_secret_key_iv=nil
   current_user.encrypted_otp_secret_key_salt=nil
   current_user.direct_otp=nil
   current_user.direct_otp_sent_at=nil
   current_user.totp_timestamp=nil
   current_user.direct_otp=nil
   current_user.otp_secret_key=nil
   current_user.otp_confirmed=nil
   current_user.save! (if in ruby code instead of console)
   current_user.direct_otp? => false
   current_user.totp_enabled? => false
   ```
   


