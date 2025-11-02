require 'rails_helper'

RSpec.describe "Api::V1::AuthController", type: :request do
  describe "POST /auth/login" do
    let(:valid_client_id) { 'test_client' }
    let(:valid_api_key) { 'test_api_key_12345' }

    before do
      # Mock Rails credentials for testing - allow any argument and return nil by default
      allow(Rails.application.credentials).to receive(:dig).and_return(nil)
      allow(Rails.application.credentials).to receive(:dig).with(:test_client).and_return(valid_api_key)
    end

    context "with valid credentials" do
      it "returns a JWT token" do
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: valid_api_key
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to have_key('token')
        expect(json['token']).to be_present
      end

      it "returns a valid JWT token that can be decoded" do
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: valid_api_key
        }

        json = JSON.parse(response.body)
        token = json['token']

        decoded = JsonWebToken.decode(token)
        expect(decoded[:client_id]).to eq(valid_client_id)
      end

      it "token has proper expiration set" do
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: valid_api_key
        }

        json = JSON.parse(response.body)
        token = json['token']

        decoded = JsonWebToken.decode(token)
        expect(decoded[:exp]).to be > Time.current.to_i
        expect(decoded[:exp]).to be <= 24.hours.from_now.to_i
      end
    end

    context "with invalid credentials" do
      it "rejects invalid api_key" do
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: 'wrong_key'
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid credentials')
      end

      it "rejects unknown client_id" do
        post '/api/v1/auth/login', params: {
          client_id: 'invalid_client',
          api_key: valid_api_key
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid credentials')
      end

      it "rejects missing client_id" do
        post '/api/v1/auth/login', params: {
          api_key: valid_api_key
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid credentials')
      end

      it "rejects missing api_key" do
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid credentials')
      end

      it "rejects request with no params" do
        post '/api/v1/auth/login', params: {}

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid credentials')
      end
    end

    context "security: timing attack prevention" do
      it "uses secure_compare to prevent timing attacks" do
        # Verify that ActiveSupport::SecurityUtils.secure_compare is used
        expect(ActiveSupport::SecurityUtils).to receive(:secure_compare)
          .with(valid_api_key, valid_api_key)
          .and_call_original

        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: valid_api_key
        }
      end

      it "takes similar time for valid and invalid keys" do
        # This is a basic check - real timing attack testing requires more sophisticated tools
        valid_times = []
        invalid_times = []

        5.times do
          start = Time.now
          post '/api/v1/auth/login', params: { client_id: valid_client_id, api_key: valid_api_key }
          valid_times << (Time.now - start)
        end

        5.times do
          start = Time.now
          post '/api/v1/auth/login', params: { client_id: valid_client_id, api_key: 'wrong_key_same_length' }
          invalid_times << (Time.now - start)
        end

        # Timing should be similar (within reasonable variance)
        # This is a basic sanity check, not a rigorous timing attack test
        valid_avg = valid_times.sum / valid_times.size
        invalid_avg = invalid_times.sum / invalid_times.size

        # Allow for 5x variance (very generous, real timing attacks need tighter analysis)
        expect((valid_avg - invalid_avg).abs).to be < (valid_avg * 5)
      end
    end

    context "security: injection attacks" do
      it "safely handles SQL injection in client_id" do
        post '/api/v1/auth/login', params: {
          client_id: "'; DROP TABLE players; --",
          api_key: valid_api_key
        }

        expect(response).to have_http_status(:unauthorized)
        # Verify no SQL was executed by checking that endpoint still works
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: valid_api_key
        }
        expect(response).to have_http_status(:ok)
      end

      it "safely handles special characters in api_key" do
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: "<script>alert('xss')</script>"
        }

        expect(response).to have_http_status(:unauthorized)
      end

      it "safely handles null bytes in credentials" do
        post '/api/v1/auth/login', params: {
          client_id: "test\x00_client",
          api_key: valid_api_key
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "security: credential stuffing and enumeration" do
      it "does not leak information about valid client_ids" do
        # Both invalid client_id and invalid api_key should return same error
        post '/api/v1/auth/login', params: {
          client_id: 'nonexistent_client',
          api_key: 'any_key'
        }
        response1 = JSON.parse(response.body)

        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: 'wrong_key'
        }
        response2 = JSON.parse(response.body)

        # Error messages should be identical (no enumeration)
        expect(response1['error']).to eq(response2['error'])
        expect(response1['error']).to eq('Invalid credentials')
      end
    end

    context "security: token usage" do
      it "generated token is properly formatted" do
        post '/api/v1/auth/login', params: {
          client_id: valid_client_id,
          api_key: valid_api_key
        }

        token = JSON.parse(response.body)['token']

        # Verify token can be decoded
        decoded = JsonWebToken.decode(token)
        expect(decoded[:client_id]).to eq(valid_client_id)
        expect(decoded[:exp]).to be > Time.current.to_i
      end
    end

    context "logging and monitoring" do
      it "logs failed authentication attempts" do
        expect(Rails.logger).to receive(:error).with(/Unknown client_id/)

        post '/api/v1/auth/login', params: {
          client_id: 'unknown_client',
          api_key: 'any_key'
        }
      end
    end
  end
end
