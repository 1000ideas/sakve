require 'sakve/token_auth'
require 'sakve/form_helper'

Sakve::Application.configure do
  config.middleware.insert_after Warden::Manager, Sakve::TokenAuth
end
