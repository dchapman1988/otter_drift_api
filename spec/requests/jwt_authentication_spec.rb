require 'rails_helper'

RSpec.describe "JWT Authentication", type: :request do
  let(:player) { create(:player, email: 'jwt_test@example.com', username: 'jwtuser', password: 'securepassword', password_confirmation: 'securepassword') }

  describe "Complete JWT Authentication Flow" do
    it "successfully authenticates through the entire flow" do
      # Step 1: Sign in and receive JWT token
      post '/players/sign_in', params: {
        player: {
          email: player.email,
          password: 'securepassword'
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Authorization']).to be_present

      jwt_token = response.headers['Authorization']

      # Verify token format (Bearer <token>)
      expect(jwt_token).to match(/^Bearer .+/)

      json = JSON.parse(response.body)
      expect(json['player']['email']).to eq(player.email)
      expect(json['message']).to eq('Logged in successfully.')

      # Step 2: Use JWT token to access protected endpoint
      get '/api/v1/players/profile', headers: {
        'Authorization' => jwt_token
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['player']['email']).to eq(player.email)
      expect(json['player']['username']).to eq(player.username)

      # Step 3: Update profile using JWT token
      patch '/api/v1/players/profile',
        params: {
          player: {
            display_name: 'JWT Authenticated User'
          }
        },
        headers: {
          'Authorization' => jwt_token
        }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['player']['display_name']).to eq('JWT Authenticated User')
      expect(json['message']).to eq('Profile updated successfully.')

      # Step 4: Sign out (revoke token)
      delete '/players/sign_out', headers: {
        'Authorization' => jwt_token
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Logged out successfully.')

      # Step 5: Verify token is revoked and cannot be used
      get '/api/v1/players/profile', headers: {
        'Authorization' => jwt_token
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests without JWT token" do
      get '/api/v1/players/profile'

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with invalid JWT token" do
      get '/api/v1/players/profile', headers: {
        'Authorization' => 'Bearer invalid.token.here'
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with malformed Authorization header" do
      get '/api/v1/players/profile', headers: {
        'Authorization' => 'InvalidFormat'
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "JWT Token Validation" do
    it "validates JWT token structure and claims" do
      # Sign in to get a valid token
      post '/players/sign_in', params: {
        player: {
          email: player.email,
          password: 'securepassword'
        }
      }

      jwt_token = response.headers['Authorization']
      token_string = jwt_token.sub('Bearer ', '')

      # Decode the token to inspect its structure
      secret = Rails.application.credentials.devise_jwt_secret_key!
      decoded = JWT.decode(token_string, secret, true, algorithm: 'HS256')

      payload = decoded.first

      # Verify required claims
      expect(payload).to have_key('sub')
      expect(payload).to have_key('jti')
      expect(payload).to have_key('exp')
      expect(payload).to have_key('scp')

      # Verify player ID is in the token
      expect(payload['sub']).to eq(player.id.to_s)

      # Verify scope is 'player'
      expect(payload['scp']).to eq('player')

      # Verify expiration is set (30 days from now based on config)
      expect(payload['exp']).to be > Time.now.to_i
      expect(payload['exp']).to be <= (Time.now + 31.days).to_i
    end
  end
end
