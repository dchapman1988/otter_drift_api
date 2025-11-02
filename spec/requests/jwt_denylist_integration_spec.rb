require 'rails_helper'

RSpec.describe "JwtDenylist Integration", type: :request do
  let(:player) { create(:player, email: 'integration@example.com', password: 'password123', password_confirmation: 'password123') }

  describe "token revocation workflow" do
    it "adds token to denylist when player signs out" do
      # Sign in to get a token
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }

      token = response.headers['Authorization']
      expect(token).to be_present

      # Sign out
      initial_count = JwtDenylist.count
      delete '/players/sign_out', headers: {
        'Authorization' => token
      }

      # Denylist should have one more entry
      expect(JwtDenylist.count).to eq(initial_count + 1)
    end

    it "prevents reuse of denylisted token" do
      # Sign in
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }

      token = response.headers['Authorization']

      # Verify token works
      get '/api/v1/players/profile', headers: {
        'Authorization' => token
      }
      expect(response).to have_http_status(:ok)

      # Sign out (adds to denylist)
      delete '/players/sign_out', headers: {
        'Authorization' => token
      }

      # Try to use the same token again
      get '/api/v1/players/profile', headers: {
        'Authorization' => token
      }

      # Should be unauthorized
      expect(response).to have_http_status(:unauthorized)
    end

    it "denylists token by jti, not by token string" do
      # Sign in
      post '/players/sign_in', params: {
        player: { email: player.email, password: 'password123' }
      }

      token = response.headers['Authorization'].sub('Bearer ', '')

      # Decode to get jti
      secret = Rails.application.credentials.devise_jwt_secret_key!
      decoded = JWT.decode(token, secret, true, algorithm: 'HS256')
      jti = decoded.first['jti']

      # Sign out
      delete '/players/sign_out', headers: {
        'Authorization' => "Bearer #{token}"
      }

      # Verify jti is in denylist
      expect(JwtDenylist.exists?(jti: jti)).to be true

      # Try to use the token again - should be rejected
      get '/api/v1/players/profile', headers: {
        'Authorization' => "Bearer #{token}"
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
