module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [ :create ]

      # POST /auth/login
      def create
        # Simple client_id based authentication
        # You can make this more sophisticated later
        client_id = params[:client_id]
        api_key = params[:api_key]

        # For now, we'll use environment variables or a simple check
        # In production, you'd want this in a database or more secure method
        if valid_credentials?(client_id, api_key)
          token = JsonWebToken.encode(client_id: client_id)
          render json: { token: token }, status: :ok
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      private

      def valid_credentials?(client_id, api_key)
        # Get the expected API key from Rails credentials
        expected_api_key = Rails.application.credentials.dig(client_id.to_sym)

        if expected_api_key.nil?
          Rails.logger.error "Unknown client_id: #{client_id}"
          return false
        end

        # Use secure comparison to prevent timing attacks
        ActiveSupport::SecurityUtils.secure_compare(expected_api_key, api_key.to_s)
      end
    end
  end
end
