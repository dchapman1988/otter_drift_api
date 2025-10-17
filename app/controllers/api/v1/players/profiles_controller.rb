module Api
  module V1
    module Players
      class ProfilesController < ::ApplicationController
        include JwtAuthentication

        before_action :authenticate_player!
        before_action :ensure_profile_exists
        before_action :set_profile

        def show
          render json: profile_response(@player, @profile)
        end

        def update
          if update_player_and_profile
            render json: profile_response(@player, @profile).merge(
              message: "Profile updated successfully."
            ), status: :ok
          else
            render_update_errors
          end
        end

        private

        def authenticate_player!
          unless current_player
            render json: {
              errors: ["You must be logged in to update your profile"]
            }, status: :unauthorized
          end
        end

        def ensure_profile_exists
          current_player.create_player_profile! unless current_player.player_profile
        end

        def set_profile
          @player = current_player
          @profile = @player.player_profile
        end

        def update_player_and_profile
          ActiveRecord::Base.transaction do
            @player.assign_attributes(player_params) if player_params.present?
            @profile.assign_attributes(profile_params) if profile_params.present?

            # Save both, rolling back if either fails
            @player.save! && @profile.save!
          end
        rescue ActiveRecord::RecordInvalid
          false
        end

        def render_update_errors
          errors = collect_errors(@player, @profile)

          render json: {
            errors: errors[:messages],
            details: errors[:details]
          }, status: :unprocessable_entity
        end

        def collect_errors(player, profile)
          messages = []
          details = {}

          if player.errors.any?
            messages.concat(player.errors.full_messages)
            details.merge!(format_error_details(player.errors))
          end

          if profile.errors.any?
            messages.concat(profile.errors.full_messages)
            details.merge!(format_error_details(profile.errors))
          end

          { messages: messages, details: details }
        end

        def player_params
          return {} unless params[:player]

          params.require(:player)
                .permit(:display_name, :username, :email, :avatar_url)
                .reject { |_k, v| v.blank? }
        end

        def profile_params
          return {} unless params.dig(:player, :profile)

          params.require(:player)
                .require(:profile)
                .permit(:bio, :favorite_otter_fact, :title, :profile_banner_url, :location)
                .reject { |_k, v| v.blank? }
        end

        def format_error_details(errors)
          errors.details.transform_values do |error_array|
            error_array.map { |error| error[:error] }
          end
        end

        def profile_response(player, profile)
          {
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
            }
          }
        end
      end
    end
  end
end
