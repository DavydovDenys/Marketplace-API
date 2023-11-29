# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Authentications' do
  let(:redis) { Redis.new }
  let(:email) { 'claris@metz.test' }
  let(:password) { 'kEh2rwbs8vC+gcNHDiQ\#$' }
  let(:user) { create(:user, email: email, password: password) }
  let(:payload) { { user_id: user.id, email: user.email } }
  let(:access_token) { JsonWebToken.encode(payload) }
  let(:refresh_token) { 'a994da7ac938e91f2d1b7301033fb16b1d51d13b4cb2b862a233c2jZ5dvIWrB8' }

  describe 'POST auth/registry' do
    path '/api/v1/auth/registry' do
      post 'create user' do
        tags 'Authentication'
        produces 'application/json'
        consumes 'application/json'

        parameter name: 'fields', in: :body, required: true, schema: {
          type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                email: { type: :string },
                password: { type: :string }
              }
            }
          },
          example: {
            user: {
              email: 'claris@metz.test',
              password: '1e0ff691a8a88f92#A'
            }
          }
        }

        let(:double) { instance_double(User, { email: email, id: 1 }) }
        let(:fields) do
          {
            user: {
              email: 'claris@metz.test',
              password: '1e0ff691a8a88f92#A'
            }
          }
        end

        response '200', 'Success' do
          before do
            allow(User).to receive(:new).and_return(double)
            allow(double).to receive(:valid?).and_return(true)
            allow(double).to receive(:save!)
          end

          schema(
            type: :object,
            properties: {
              result: { type: :string },
              access_token: { type: :string },
              refresh_token: { type: :string }
            },
            example: {
              result: 'OK',
              access_token: %(eyJhbGciOiJIUzI1NiJ9.
                eyJ1c2VyX2lkIjoxLCJ1c2VyX2VtYWlsIjoidGVzdEBtYWlsLmNvbSIsImV4cCI6MTcwMDkyNDAyOH0.
                nuJ-2HFN0IK5mRFaaPsRnxGmPROmJ70nciGgNKQML4M).squish,
              refresh_token: '6c4ac53ebb510e001237b4bb536728593f1b1ea6453e91a5509e98iGgNKQML4M'
            }
          )

          run_test!

          it 'returns status ok' do
            expect(response).to have_http_status(:ok)
          end

          it 'creates access and refresh tokens' do
            expect(response.cookies).to have_key('jwt')
            expect(response.parsed_body).to have_key('access_token')
          end

          it 'saves user id and refresh token' do
            response
            expect(User).to have_received(:new)
            expect(double).to have_received(:valid?)
            expect(double).to have_received(:save!)
            expect(JSON.parse(redis.get(double.id))).to have_key('jwt')
          end
        end

        response '400', 'Bad Request' do
          examples 'application/json' => [
            {
              result: 'Bad Credentials',
              errors: ['Email has already been taken']
            },
            {
              result: 'Bad Credentials',
              errors: ['Email is invalid']
            },
            {
              result: 'Bad Credentials',
              errors: ['Password is invalid']
            }
          ]
          before do
            allow(User).to receive(:new).and_return(double)
            allow(double).to receive(:valid?).and_return(false)
            allow(double).to receive_message_chain(:errors, full_messages: message)
          end

          schema(
            type: :object,
            properties: {
              result: { type: :string },
              errors: {
                type: :aray,
                items: { type: :string }
              }
            }
          )

          context 'when email has already been taken' do
            let(:message) { ['Email has already been taken'] }

            run_test!

            it 'returns status 400 Bad Request' do
              expect(response).to have_http_status(:bad_request)
            end
          end

          context 'when email is invalid' do
            let(:message) { ['Email is invalid'] }

            run_test!

            it 'returns status 400 Bad Request' do
              expect(response).to have_http_status(:bad_request)
            end
          end

          context 'when password is invalid' do
            let(:message) { ['Password is invalid'] }

            run_test!

            it 'returns status 400 Bad Request' do
              expect(response).to have_http_status(:bad_request)
            end
          end
        end
      end
    end
  end

  describe 'POST auth/refresh' do
    path '/api/v1/auth/refresh' do
      post 'recreate access and refresh tokens' do
        tags 'Authentication'
        security [Bearer: {}]
        produces 'application/json'

        parameter name: :cookie, in: :header, type: :string, required: true

        let(:Authorization) { "Bearer #{access_token}" }
        let(:cookie) { "jwt=#{refresh_token}" }

        response '200', 'Success' do
          before do
            allow(Redis.new).to receive(:get).with(user.id).and_return(
              { jwt: refresh_token, exp: 10.minutes.from_now.to_i }.to_json
            )
          end

          schema(
            type: :object,
            properties: {
              result: { type: :string },
              access_token: { type: :string },
              refresh_token: { type: :string }
            },
            example: {
              result: 'OK',
              access_token: %(eyJhbGciOiJIUzI1NiJ9.
                eyJ1c2VyX2lkIjoxLCJ1c2VyX2VtYWlsIjoidGVzdEBtYWlsLmNvbSIsImV4cCI6MTcwMDkyNDAyOH0.
                nuJ-2HFN0IK5mRFaaPsRnxGmPROmJ70nciGgNKQML4M).squish,
              refresh_token: '6c4ac53ebb510e001237b4bb536728593f1b1ea6453e91a5509e98iGgNKQML4M'
            }
          )

          run_test!

          it 'returns status ok' do
            expect(response).to have_http_status(:ok)
          end

          it 'saves user id, refresh token, expired time' do
            expect(JSON.parse(redis.get(user.id))['jwt']).to eq(refresh_token)
          end
        end

        response '401', 'Unauthorized' do
          examples 'application/json' => [
            {
              result: 'Unauthorized',
              errors: ['Token doesn\'t exist']
            },
            {
              result: 'Unauthorized',
              errors: ['Signature has expired']
            },
            {
              result: 'Unauthorized',
              errors: ['Token mismatch']
            }
          ]
          schema(
            type: :object,
            properties: {
              result: { type: :string },
              errors: {
                type: :aray,
                items: { type: :string }
              }
            }
          )
          context 'when token doesn\'t exist' do
            before do
              allow(Redis.new).to receive(:get).and_return(nil)
            end

            run_test!

            it 'returns status 401' do
              expect(response).to have_http_status(:unauthorized)
            end
          end

          context 'when token expired' do
            before do
              allow(Redis.new).to receive(:get).and_return(
                { jwt: refresh_token, exp: 10.minutes.ago.to_i }.to_json
              )
            end

            run_test!

            it 'returns status 401' do
              expect(response).to have_http_status(:unauthorized)
            end
          end

          context 'when token mismatch' do
            let(:stolen_rt) { 'stolen_rt_c938e91f2d1b7301033fb16b1d51d13b4cb2b862a233c2jZ5dvIWrB8' }
            let(:cookie) { "jwt=#{stolen_rt}" }

            before do
              allow(Redis.new).to receive(:get).and_return(
                { jwt: refresh_token, exp: 10.minutes.from_now.to_i }.to_json
              )
            end

            run_test!

            it 'returns status 401' do
              expect(response).to have_http_status(:unauthorized)
            end
          end
        end
      end
    end
  end

  describe 'POST auth/login' do
    path '/api/v1/auth/login' do
      post 'user login' do
        tags 'Authentication'
        produces 'application/json'
        consumes 'application/json'

        parameter name: 'fields', in: :body, required: true, schema: {
          type: :object,
          properties: {
            user: {
              type: :object,
              properties: {
                email: { type: :string },
                password: { type: :string }
              }
            }
          },
          example: {
            user: {
              email: 'claris@metz.test',
              password: '1e0ff691a8a88f92#A'
            }
          }
        }

        let!(:login_user) { user }
        let(:fields) do
          {
            user: {
              email: email,
              password: password
            }
          }
        end

        response '200', 'Success' do
          before do
            allow(JsonWebToken).to receive(:encode).and_return(access_token)
          end

          schema(
            type: :object,
            properties: {
              result: { type: :string },
              access_token: { type: :string },
              refresh_token: { type: :string }
            },
            example: {
              result: 'OK',
              access_token: %(eyJhbGciOiJIUzI1NiJ9.
                eyJ1c2VyX2lkIjoxLCJ1c2VyX2VtYWlsIjoidGVzdEBtYWlsLmNvbSIsImV4cCI6MTcwMDkyNDAyOH0.
                nuJ-2HFN0IK5mRFaaPsRnxGmPROmJ70nciGgNKQML4M).squish,
              refresh_token: '6c4ac53ebb510e001237b4bb536728593f1b1ea6453e91a5509e98iGgNKQML4M'
            }
          )

          run_test!

          it 'returns status ok' do
            expect(response).to have_http_status(:ok)
          end

          it 'saves user id, refresh token, expired time' do
            expect(JSON.parse(redis.get(login_user.id))).to have_key('jwt')
          end
        end

        response '404', 'Not Found' do
          schema(
            type: :object,
            properties: {
              result: { type: :string },
              errors: {
                type: :aray,
                items: { type: :string }
              }
            },
            example: {
              result: 'Not Found',
              errors: ["Couldn't find User with 'id'=45"]
            }
          )

          let(:not_found_email) { 'notfounduser@mail.com' }
          let(:fields) do
            {
              user: {
                email: not_found_email,
                password: password
              }
            }
          end
          run_test!

          it 'returns status 404' do
            expect(response).to have_http_status(:not_found)
          end
        end

        response '400', 'Bad Credentials, password is invalid' do
          schema(
            type: :object,
            properties: {
              result: { type: :string },
              errors: {
                type: :aray,
                items: { type: :string }
              }
            },
            example: {
              result: 'Bad Credentials',
              errors: ['Password is invalid']
            }
          )

          let(:fields) do
            {
              user: {
                email: email,
                password: invalid_password
              }
            }
          end
          let(:invalid_password) { 'Wrongpassword+gcNHDiQ\#$' }

          run_test!

          it 'returns status 400' do
            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end
  end
end
