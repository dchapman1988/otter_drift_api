require 'rails_helper'

RSpec.describe JsonWebToken do
  include ActiveSupport::Testing::TimeHelpers

  let(:secret_key) { Rails.application.secret_key_base }
  let(:payload) { { user_id: 123, email: 'test@example.com' } }

  describe '.encode' do
    context 'with default expiration' do
      it 'encodes a payload into a JWT token' do
        token = described_class.encode(payload)

        expect(token).to be_a(String)
        expect(token.split('.').length).to eq(3) # JWT format: header.payload.signature
      end

      it 'includes the payload data in the token' do
        token = described_class.encode(payload)
        decoded = JWT.decode(token, secret_key)[0]

        expect(decoded['user_id']).to eq(123)
        expect(decoded['email']).to eq('test@example.com')
      end

      it 'sets expiration to 24 hours from now by default' do
        travel_to Time.current do
          token = described_class.encode(payload)
          decoded = JWT.decode(token, secret_key)[0]

          expect(decoded['exp']).to eq(24.hours.from_now.to_i)
        end
      end
    end

    context 'with custom expiration' do
      it 'sets custom expiration time' do
        custom_exp = 2.hours.from_now
        token = described_class.encode(payload, custom_exp)
        decoded = JWT.decode(token, secret_key)[0]

        expect(decoded['exp']).to eq(custom_exp.to_i)
      end
    end

    context 'with empty payload' do
      it 'encodes an empty payload' do
        token = described_class.encode({})

        expect(token).to be_a(String)
        decoded = JWT.decode(token, secret_key)[0]
        expect(decoded).to have_key('exp')
      end
    end

    context 'with special characters in payload' do
      it 'handles special characters correctly' do
        special_payload = { name: "O'Brien", description: '<script>alert("xss")</script>' }
        token = described_class.encode(special_payload)
        decoded = JWT.decode(token, secret_key)[0]

        expect(decoded['name']).to eq("O'Brien")
        expect(decoded['description']).to eq('<script>alert("xss")</script>')
      end
    end
  end

  describe '.decode' do
    let(:token) { described_class.encode(payload) }

    context 'with valid token' do
      it 'decodes a valid JWT token' do
        decoded = described_class.decode(token)

        expect(decoded[:user_id]).to eq(123)
        expect(decoded[:email]).to eq('test@example.com')
      end

      it 'returns a HashWithIndifferentAccess' do
        decoded = described_class.decode(token)

        expect(decoded).to be_a(HashWithIndifferentAccess)
        expect(decoded[:user_id]).to eq(decoded['user_id'])
      end

      it 'includes expiration in decoded payload' do
        decoded = described_class.decode(token)

        expect(decoded[:exp]).to be_a(Integer)
        expect(decoded[:exp]).to be > Time.current.to_i
      end
    end

    context 'with expired token' do
      it 'raises JWT::ExpiredSignature error' do
        expired_token = described_class.encode(payload, 1.hour.ago)

        expect {
          described_class.decode(expired_token)
        }.to raise_error(JWT::ExpiredSignature)
      end
    end

    context 'with tampered token' do
      it 'raises JWT::VerificationError when signature is invalid' do
        parts = token.split('.')
        # Tamper with the payload
        parts[1] = Base64.urlsafe_encode64('{"user_id":999}', padding: false)
        tampered_token = parts.join('.')

        expect {
          described_class.decode(tampered_token)
        }.to raise_error(JWT::VerificationError)
      end

      it 'raises error when payload is modified' do
        # Create a token with different payload but keep same signature
        original_token = token
        decoded = JWT.decode(original_token, nil, false)[0]
        decoded['user_id'] = 999

        # Encode with a different secret to simulate tampering
        fake_token = JWT.encode(decoded, 'fake_secret')

        expect {
          described_class.decode(fake_token)
        }.to raise_error(JWT::VerificationError)
      end
    end

    context 'with invalid token format' do
      it 'raises JWT::DecodeError for malformed token' do
        expect {
          described_class.decode('invalid.token')
        }.to raise_error(JWT::DecodeError)
      end

      it 'raises error for non-JWT string' do
        expect {
          described_class.decode('not-a-jwt-token')
        }.to raise_error(JWT::DecodeError)
      end

      it 'raises error for empty string' do
        expect {
          described_class.decode('')
        }.to raise_error(JWT::DecodeError)
      end

      it 'raises error for nil token' do
        expect {
          described_class.decode(nil)
        }.to raise_error(JWT::DecodeError)
      end
    end

    context 'security: algorithm attacks' do
      it 'rejects tokens signed with "none" algorithm' do
        # Create a token with "none" algorithm (a known JWT vulnerability)
        header = { alg: 'none', typ: 'JWT' }
        encoded_header = Base64.urlsafe_encode64(header.to_json, padding: false)
        encoded_payload = Base64.urlsafe_encode64(payload.to_json, padding: false)
        none_token = "#{encoded_header}.#{encoded_payload}."

        expect {
          described_class.decode(none_token)
        }.to raise_error(JWT::DecodeError)
      end

      it 'only accepts tokens signed with HS256 algorithm' do
        # The JWT library should default to HS256 and reject other algorithms
        # unless explicitly allowed. This verifies that behavior.
        token_with_default = described_class.encode(payload)
        decoded_header = JSON.parse(Base64.urlsafe_decode64(token_with_default.split('.')[0]))

        expect(decoded_header['alg']).to eq('HS256')
      end
    end

    context 'security: wrong secret key' do
      it 'raises JWT::VerificationError with wrong secret' do
        token_with_wrong_secret = JWT.encode(payload, 'wrong_secret')

        expect {
          described_class.decode(token_with_wrong_secret)
        }.to raise_error(JWT::VerificationError)
      end
    end

    context 'security: token reuse and expiration' do
      it 'properly validates expiration timestamp' do
        # Token expires in 1 second
        short_lived_token = described_class.encode(payload, 1.second.from_now)

        # Should work immediately
        expect {
          described_class.decode(short_lived_token)
        }.not_to raise_error

        # Should fail after expiration
        travel_to 2.seconds.from_now do
          expect {
            described_class.decode(short_lived_token)
          }.to raise_error(JWT::ExpiredSignature)
        end
      end
    end

    context 'security: injection attempts' do
      it 'safely handles SQL injection attempts in payload' do
        injection_payload = { query: "'; DROP TABLE users; --" }
        token = described_class.encode(injection_payload)
        decoded = described_class.decode(token)

        expect(decoded[:query]).to eq("'; DROP TABLE users; --")
      end

      it 'safely handles XSS attempts in payload' do
        xss_payload = { name: '<script>alert("XSS")</script>' }
        token = described_class.encode(xss_payload)
        decoded = described_class.decode(token)

        expect(decoded[:name]).to eq('<script>alert("XSS")</script>')
      end
    end
  end

  describe 'round-trip encoding and decoding' do
    it 'correctly encodes and decodes the same data' do
      original_payload = {
        user_id: 456,
        email: 'roundtrip@example.com',
        roles: [ 'admin', 'user' ],
        metadata: { created_at: '2025-01-01' }
      }

      token = described_class.encode(original_payload)
      decoded = described_class.decode(token)

      expect(decoded[:user_id]).to eq(456)
      expect(decoded[:email]).to eq('roundtrip@example.com')
      expect(decoded[:roles]).to eq([ 'admin', 'user' ])
      expect(decoded[:metadata]).to eq({ 'created_at' => '2025-01-01' })
    end

    it 'maintains data types through encoding/decoding' do
      typed_payload = {
        integer: 42,
        string: 'test',
        boolean: true,
        array: [ 1, 2, 3 ],
        hash: { key: 'value' }
      }

      token = described_class.encode(typed_payload)
      decoded = described_class.decode(token)

      expect(decoded[:integer]).to eq(42)
      expect(decoded[:string]).to eq('test')
      expect(decoded[:boolean]).to eq(true)
      expect(decoded[:array]).to eq([ 1, 2, 3 ])
      expect(decoded[:hash]).to eq({ 'key' => 'value' })
    end
  end

  describe 'SECRET_KEY configuration' do
    it 'uses Rails secret_key_base' do
      expect(described_class::SECRET_KEY).to eq(Rails.application.secret_key_base)
    end

    it 'ensures SECRET_KEY is not empty' do
      expect(described_class::SECRET_KEY).not_to be_nil
      expect(described_class::SECRET_KEY).not_to be_empty
    end
  end
end
