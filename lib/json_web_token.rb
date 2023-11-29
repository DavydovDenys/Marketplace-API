# frozen_string_literal: true

class JsonWebToken
  SECRET_KEY = Rails.application.secrets.secret_key_base.to_s

  def self.encode(payload, exp = 1.hour.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, 'HS256')[0]
    ActiveSupport::HashWithIndifferentAccess.new decoded
  end

  def self.decode_without_expiration(token)
    JWT.decode(token, SECRET_KEY, true, { verify_expiration: false, algorithm: 'HS256' }).first
  end
end
