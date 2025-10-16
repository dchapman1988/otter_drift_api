module Players
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json
    skip_before_action :authenticate_request, raise: false
    skip_around_action :set_current_attributes, raise: false

    before_action :configure_sign_up_params, only: [ :create ]

    def create
      build_resource(sign_up_params)

      resource.save
      if resource.persisted?
        render json: {
          player: {
            id: resource.id,
            email: resource.email,
            username: resource.username,
            display_name: resource.display_name_or_username
          },
          message: "Signed up successfully."
        }, status: :created
      else
        # Log the actual errors to help debug
        Rails.logger.error "Player registration failed: #{resource.errors.full_messages.join(', ')}"

        render json: {
          errors: resource.errors.full_messages,
          details: resource.errors.details
        }, status: :unprocessable_entity
      end
    end

    private

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :display_name, :avatar_url ])
    end

    def sign_up_params
      params.require(:player).permit(:email, :username, :display_name, :avatar_url, :password, :password_confirmation)
    end
  end
end
