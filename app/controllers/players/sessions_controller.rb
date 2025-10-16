module Players
  class SessionsController < Devise::SessionsController
    respond_to :json
    skip_before_action :authenticate_request, raise: false
    skip_around_action :set_current_attributes, raise: false
    skip_before_action :verify_signed_out_user, only: [ :destroy ]
    wrap_parameters false

    # Skip flash for API-only controllers
    def flash
      {}
    end

    private

    def respond_with(resource, _opts = {})
      if resource.persisted?
        render json: {
          player: {
            id: resource.id,
            email: resource.email,
            username: resource.username,
            display_name: resource.display_name_or_username,
            total_score: resource.total_score,
            games_played: resource.games_played
          },
          message: "Logged in successfully."
        }, status: :ok
      else
        render json: {
          errors: [ "Invalid email or password" ]
        }, status: :unauthorized
      end
    end

    def respond_to_on_destroy
      if current_player
        render json: {
          message: "Logged out successfully."
        }, status: :ok
      else
        render json: {
          errors: [ "No active session or invalid token." ]
        }, status: :unauthorized
      end
    end

    # Fix for devise-jwt parameter wrapping issue
    def sign_in_params
      params.require(:player).permit(:email, :password)
    end
  end
end
