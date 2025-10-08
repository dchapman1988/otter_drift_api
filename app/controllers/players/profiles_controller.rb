module Players
  class ProfilesController < ApplicationController
    include JwtAuthentication
    
    before_action :ensure_profile_exists, only: [:update]

    def update
      # Check if player is authenticated
      unless current_player
        render json: {
          errors: ['You must be logged in to update your profile']
        }, status: :unauthorized
        return
      end

      player = current_player
      profile = player.player_profile

      # Start a transaction to ensure both updates succeed or fail together
      ActiveRecord::Base.transaction do
        # Update player fields if provided
        if player_params.present?
          unless player.update(player_params)
            render json: {
              errors: player.errors.full_messages,
              details: format_error_details(player.errors)
            }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
            return
          end
        end

        # Update profile fields if provided
        if profile_params.present?
          unless profile.update(profile_params)
            render json: {
              errors: profile.errors.full_messages,
              details: format_error_details(profile.errors)
            }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
            return
          end
        end

        # Reload to get fresh data
        player.reload
        profile.reload

        render json: {
          player: {
            id: player.id,
            email: player.email,
            username: player.username,
            display_name: player.display_name,
            avatar_url: player.avatar_url,
            profile: {
              bio: profile.bio,
              favorite_otter_fact: profile.favorite_otter_fact,
              title: profile.title,
              profile_banner_url: profile.profile_banner_url,
              location: profile.location
            }
          },
          message: 'Profile updated successfully.'
        }, status: :ok
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: {
        errors: [e.message],
        details: {}
      }, status: :unprocessable_entity
    end

  private

  def ensure_profile_exists
    # Return early if not authenticated
    return unless current_player
    
    # Create profile if it doesn't exist
    current_player.create_player_profile! unless current_player.player_profile
  end

    def player_params
      # Only extract player-specific fields if they are present in the params
      params.require(:player).permit(
        :display_name,
        :username,
        :email,
        :avatar_url
      ).select { |_k, v| v.present? } if params[:player]
    rescue ActionController::ParameterMissing
      {}
    end

    def profile_params
      # Extract profile-specific fields from the nested profile hash
      if params[:player] && params[:player][:profile]
        params.require(:player).require(:profile).permit(
          :bio,
          :favorite_otter_fact,
          :title,
          :profile_banner_url,
          :location
        ).select { |_k, v| v.present? }
      else
        {}
      end
    rescue ActionController::ParameterMissing
      {}
    end

    def format_error_details(errors)
      errors.details.transform_values do |error_array|
        error_array.map { |error| error[:error] }
      end
    end
  end
end
