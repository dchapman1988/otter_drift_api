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
              errors: [ "You must be logged in to update your profile" ]
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

            # Handle avatar upload if provided
            if params.dig(:player, :avatar).present?
              avatar_file = params[:player][:avatar]

              # Sanitize filename to prevent directory traversal and script injection
              sanitized_filename = sanitize_filename(avatar_file.original_filename)

              # Validate and attach avatar
              # We read the file once for validation to avoid double I/O
              tempfile = avatar_file.tempfile
              tempfile.rewind

              unless valid_image_content?(tempfile, avatar_file.content_type)
                @player.errors.add(:avatar, "file content does not match the declared image type")
                raise ActiveRecord::RecordInvalid, @player
              end

              # File is already rewound from validation
              @player.avatar.attach(
                io: tempfile,
                filename: sanitized_filename,
                content_type: avatar_file.content_type
              )
            end

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
              avatar: avatar_data(player),
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

        def avatar_data(player)
          return nil unless player.avatar.attached?

          {
            url: rails_blob_url(player.avatar, only_path: false),
            filename: player.avatar.filename.to_s,
            content_type: player.avatar.content_type,
            byte_size: player.avatar.byte_size
          }
        end

        # Optimized: accepts io and content_type directly to avoid re-reading file
        def valid_image_content?(io, content_type)
          return false unless content_type

          # Read only the minimum bytes needed (reduces I/O)
          bytes_needed = case content_type
          when "image/webp" then 12  # RIFF (4) + size (4) + WEBP (4)
          when "image/png" then 8    # PNG signature
          when "image/gif" then 3    # GIF
          when "image/jpeg", "image/jpg" then 2  # JPEG
          else
            return false  # Unsupported type
          end

          header = io.read(bytes_needed)
          io.rewind

          return false unless header && header.bytesize >= bytes_needed

          case content_type
          when "image/png"
            header[0..7] == "\x89PNG\r\n\x1a\n".b
          when "image/jpeg", "image/jpg"
            header[0..1] == "\xff\xd8".b
          when "image/gif"
            header[0..2] == "GIF".b
          when "image/webp"
            header[0..3] == "RIFF".b && header[8..11] == "WEBP".b
          else
            false
          end
        rescue StandardError => e
          Rails.logger.error("Image content validation error: #{e.message}")
          false
        end

        def sanitize_filename(filename)
          # Remove path components (directory traversal protection)
          basename = File.basename(filename)

          # Remove any non-alphanumeric characters except dots, dashes, and underscores
          # This prevents script injection and special character exploits
          sanitized = basename.gsub(/[^\w\.\-]/, '_')

          # Ensure filename has a reasonable length
          sanitized = sanitized[0..255]

          # Prevent double extensions that could be exploited (.jpg.php)
          # Keep only the last extension
          name_parts = sanitized.split('.')
          if name_parts.length > 2
            extension = name_parts.last
            name = name_parts[0..-2].join('_')
            sanitized = "#{name}.#{extension}"
          end

          # Fallback to timestamp-based name if sanitization resulted in empty string
          sanitized.presence || "avatar_#{Time.current.to_i}.jpg"
        end
      end
    end
  end
end
