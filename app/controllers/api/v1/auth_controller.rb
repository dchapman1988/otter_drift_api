module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_request, only: [:create]

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
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end

      private

      def valid_credentials?(client_id, api_key)
        # Simple validation - replace with your preferred method
        # You could use environment variables, a config file, or database
        valid_clients = {
          'game_client_1' => Rails.application.credentials.api_keys&.game_client_1,
          'mobile_app' => Rails.application.credentials.api_keys&.mobile_app
        }
        
        valid_clients[client_id] == api_key
      end
    end
  end
end
