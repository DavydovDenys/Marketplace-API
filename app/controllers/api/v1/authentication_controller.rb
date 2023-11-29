# frozen_string_literal: true

module Api
  module V1
    class AuthenticationController < ApplicationController
      def registry
        user = User.new(email: user_params[:email], password: user_params[:password])
        if user.valid?
          user.save!
          payload = { user_id: user.id, user_email: user.email }
          access_token, refresh_token = generate_tokens(payload)
          cookie(refresh_token)
          redis.set(user.id, { jwt: refresh_token, exp: expires.to_i }.to_json)

          render json: { result: 'OK', access_token: access_token }, status: :ok
        else
          render json: { result: 'Bad Credentials', errors: user.errors.full_messages }, status: :bad_request
        end
      end

      def refresh
        begin
          user = decoded_user
          exp_time = JSON.parse(redis.get(user.id))['exp']
        rescue JWT::DecodeError => e
          return render json: { result: 'Unauthorized', errors: [e.message] }, status: :unauthorized
        rescue ActiveRecord::RecordNotFound => e
          return render json: { result: 'Not Found', errors: [e.message] }, status: :not_found
        rescue JWT::IncorrectAlgorithm => e
          return render json: { result: 'Unauthorized', errors: [e.message] }, status: :unauthorized
        rescue TypeError => e
          return render json: { result: 'Unauthorized', errors: [e.message, 'Token doesn\'t exist'] },
                        status: :unauthorized
        end

        if exp_time < Time.now.to_i
          return render json: { result: 'Unauthorized', errors: ['Signature has expired'] }, status: :unauthorized
        end

        db_rt = JSON.parse(redis.get(user.id))['jwt']
        if db_rt == request.cookies['jwt']
          payload = payload(user)
          access_token, refresh_token = generate_tokens(payload)
          redis.set(user.id, { jwt: refresh_token, exp: exp_time }.to_json)
          cookie(refresh_token)
          render json: { result: 'OK', access_token: access_token }, status: :ok
        else
          redis.set(user.id, { jwt: '', exp: '' }.to_json)
          render json: { result: 'Unauthorized', errors: ['Token mismatch'] }, status: :unauthorized
        end
      end

      def login
        begin
          user = User.find_by!(email: user_params[:email])
        rescue ActiveRecord::RecordNotFound => e
          return render json: { result: 'Not Found', errors: [e.message] }, status: :not_found
        end

        unless user.authenticate(user_params[:password])
          return render json: { result: 'Bad Credentials', errors: ['Invalid email or password'] }, status: :bad_request
        end

        payload = { user_id: user.id, user_email: user.email }
        access_token, refresh_token = generate_tokens(payload)
        cookie(refresh_token)
        redis.set(user.id, { jwt: refresh_token, exp: expires.to_i }.to_json)
        render json: { result: 'OK', access_token: access_token }, status: :ok
      end

      private

      def user_params
        params.require(:user).permit(:email, :password)
      end

      def decoded_user
        decoded = JsonWebToken.decode_without_expiration(access_token_from_header)
        User.find(decoded['user_id'])
      end

      def generate_tokens(payload)
        access_token = JsonWebToken.encode(payload)
        token = SecureRandom.hex
        refresh_token = Digest::SHA256.hexdigest(token)
        refresh_token[-10..-1] = access_token.last(10)
        [access_token, refresh_token]
      end

      def payload(user)
        { user_id: user.id, user_email: user.email }
      end

      def cookie(refresh_token)
        response.set_cookie(
          :jwt,
          {
            value: refresh_token,
            expires: expires,
            path: '/api/v1/auth/',
            httponly: true,
            secure: true
          }
        )
      end

      def expires
        7.days.from_now
      end

      def redis
        @redis ||= Redis.new
      end

      def access_token_from_header
        header = request.headers['Authorization']
        header&.split&.last
      end
    end
  end
end
