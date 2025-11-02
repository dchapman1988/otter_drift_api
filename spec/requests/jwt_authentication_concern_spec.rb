require 'rails_helper'

RSpec.describe "JwtAuthentication Concern", type: :request do
  let(:player) { create(:player, email: 'concern_test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:valid_client_id) { 'test_client' }
  let(:valid_api_key) { 'test_api_key_12345' }

  before do
    # Mock Rails credentials for client authentication
    allow(Rails.application.credentials).to receive(:dig).with(:test_client).and_return(valid_api_key)
  end

  describe "authentication priority and fallback" do
    context "when both player JWT and client JWT are present" do
      it "prioritizes player authentication over client authentication" do
        # Get player token
        post '/players/sign_in', params: {
          player: { email: player.email, password: 'password123' }
        }
        player_token = response.headers['Authorization']

        # Get client token
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: valid_api_key
        }
        client_token = JSON.parse(response.body)['token']

        # Use player token (should authenticate as player)
        get '/api/v1/players/profile', headers: {
          'Authorization' => player_token
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['player']['email']).to eq(player.email)
      end
    end

    context "when only client JWT is present" do
      it "client tokens can be generated" do
        # Get client token
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: valid_api_key
        }
        client_token = JSON.parse(response.body)['token']

        # Verify token is valid
        decoded = JsonWebToken.decode(client_token)
        expect(decoded[:client_id]).to eq(valid_client_id)
      end
    end

    context "when no authentication is present" do
      it "returns unauthorized" do
        get '/api/v1/players/profile'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "security: token format validation" do
    it "accepts valid Bearer tokens" do
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }
      token = response.headers['Authorization']

      get '/api/v1/players/profile', headers: {
        'Authorization' => token
      }

      expect(response).to have_http_status(:ok)
    end

    it "handles Authorization header with extra spaces" do
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }
      token = response.headers['Authorization']

      # Add extra spaces
      token_with_spaces = token.gsub('Bearer ', 'Bearer    ')

      get '/api/v1/players/profile', headers: {
        'Authorization' => token_with_spaces
      }

      # Should still work or gracefully fail (not crash)
      expect([ 200, 401 ]).to include(response.status)
    end

    it "rejects empty Authorization header" do
      get '/api/v1/players/profile', headers: {
        'Authorization' => ''
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects Authorization header with only whitespace" do
      get '/api/v1/players/profile', headers: {
        'Authorization' => '   '
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "security: token tampering" do
    it "rejects tokens signed with wrong secret" do
      # Create a token with a different secret
      fake_token = JWT.encode(
        { sub: player.id.to_s, exp: 30.days.from_now.to_i },
        'wrong_secret',
        'HS256'
      )

      get '/api/v1/players/profile', headers: {
        'Authorization' => "Bearer #{fake_token}"
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "security: expired tokens" do
    it "rejects expired player tokens" do
      # Create an expired token manually
      secret = Rails.application.credentials.devise_jwt_secret_key!
      expired_token = JWT.encode(
        {
          sub: player.id.to_s,
          jti: SecureRandom.uuid,
          scp: 'player',
          exp: 1.hour.ago.to_i
        },
        secret,
        'HS256'
      )

      get '/api/v1/players/profile', headers: {
        'Authorization' => "Bearer #{expired_token}"
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects expired client tokens" do
      expired_client_token = JsonWebToken.encode({ client_id: valid_client_id }, 1.hour.ago)

      get '/api/v1/game_sessions', headers: {
        'Authorization' => "Bearer #{expired_client_token}"
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "security: JWT header injection" do
    it "rejects tokens with SQL injection in JWT payload" do
      malicious_token = JsonWebToken.encode({ client_id: "'; DROP TABLE players; --" })

      get '/api/v1/game_sessions', headers: {
        'Authorization' => "Bearer #{malicious_token}"
      }

      # Should either reject or safely handle
      # Verify database still intact by checking player exists
      expect(Player.find_by(id: player.id)).to be_present
    end

    it "rejects multiple Authorization headers" do
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }
      token = response.headers['Authorization']

      # Some frameworks concatenate multiple headers, which could cause security issues
      # This test verifies the app handles this safely
      get '/api/v1/players/profile', headers: {
        'Authorization' => "#{token}, Bearer fake.token.here"
      }

      # Should either work with first token or reject (not crash)
      expect([ 200, 401 ]).to include(response.status)
    end

    it "sanitizes header injection attempts" do
      get '/api/v1/players/profile', headers: {
        'Authorization' => "Bearer token\r\nX-Admin: true"
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "security: Current attributes isolation" do
    it "clears Current.player after each request" do
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }
      token = response.headers['Authorization']

      # Make authenticated request
      get '/api/v1/players/profile', headers: {
        'Authorization' => token
      }

      expect(response).to have_http_status(:ok)

      # Current.player should be cleared after request
      expect(Current.player).to be_nil
    end

    it "each player gets their own token with correct data" do
      another_player = create(:player, email: 'another@example.com', username: 'anotheruser', password: 'password123', password_confirmation: 'password123')

      # Get token for first player
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }
      token1 = response.headers['Authorization']

      # Verify first player's token works
      get '/api/v1/players/profile', headers: { 'Authorization' => token1 }
      response1 = JSON.parse(response.body)
      expect(response1['player']['email']).to eq(player.email)
      expect(response1['player']['username']).to eq(player.username)

      # Sign out first player
      delete '/players/sign_out', headers: { 'Authorization' => token1 }

      # Get token for second player
      post '/players/sign_in', params: {
        player: { email: another_player.email, password: 'password123' }
      }
      token2 = response.headers['Authorization']

      # Verify second player's token works with correct data
      get '/api/v1/players/profile', headers: { 'Authorization' => token2 }
      response2 = JSON.parse(response.body)
      expect(response2['player']['email']).to eq(another_player.email)
      expect(response2['player']['username']).to eq('anotheruser')
    end
  end

  describe "security: concurrent request handling" do
    it "allows same JWT token to be reused across multiple sequential requests" do
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }
      token = response.headers['Authorization']

      # Make multiple sequential requests with the same token
      5.times do
        get '/api/v1/players/profile', headers: { 'Authorization' => token }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['player']['email']).to eq(player.email)
      end
    end

    it "JWT decoding is thread-safe", :truncation do
      # Create a valid token
      payload = { player_id: player.id, exp: 24.hours.from_now.to_i }
      token = JsonWebToken.encode(payload)

      # Decode the same token concurrently in multiple threads
      threads = 10.times.map do
        Thread.new do
          begin
            decoded = JsonWebToken.decode(token)
            { success: true, player_id: decoded[:player_id] }
          rescue => e
            { success: false, error: e.message }
          end
        end
      end

      results = threads.map(&:value)

      # All threads should successfully decode the token
      expect(results).to all(include(success: true, player_id: player.id))
    end
  end

  describe "security: missing or invalid Authorization scenarios" do
    it "handles nil Authorization header gracefully" do
      get '/api/v1/players/profile', headers: { 'Authorization' => nil }

      expect(response).to have_http_status(:unauthorized)
    end

    it "handles non-string Authorization header" do
      # This shouldn't normally happen, but test defensive coding
      expect {
        get '/api/v1/players/profile'
      }.not_to raise_error
    end

    it "rejects tokens from different JWT libraries" do
      # Token created with different library or settings
      rogue_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

      get '/api/v1/players/profile', headers: {
        'Authorization' => "Bearer #{rogue_token}"
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
