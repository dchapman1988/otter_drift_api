module Api
  module V1
    module Players
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json
        skip_before_action :authenticate_request

        private

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              player: {
                id: resource.id,
                email: resource.email,
                username: resource.username,
                display_name: resource.display_name_or_username
              }
            }, status: :created
          else
            render json: {
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end

