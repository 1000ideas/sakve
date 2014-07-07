module Sakve
  class TokenAuth
    def initialize(app)
      @app = app
    end

    def call(env)
      proxy = env['warden']
      token = env['HTTP_X_AUTH_TOKEN']
      if proxy and token
        user = User.find_by_auth_token(token)
        unless user.nil?
          current = catch(:warden) { proxy.user(:user) }
          unless User === current and current == user
            proxy.set_user(user, scope: :user)
          end
        end
      end

      @app.call(env)
    end
  end
end
