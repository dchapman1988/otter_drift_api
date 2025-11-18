module Api
  module V1
    class SuggestionsController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :player_not_found

      def create
        if params[:suggestion].present?
          permitted_params = params.require(:suggestion).permit(:note, :player_id, :player_name)
        else
          permitted_params = {}
        end

        # Look up player by name if provided (do this first to catch player errors)
        if permitted_params[:player_name].present?
          player = Player.find_by(username: permitted_params[:player_name])
          if player.nil?
            raise ActiveRecord::RecordNotFound, "Player with username '#{permitted_params[:player_name]}' not found"
          end
          permitted_params = permitted_params.to_h.merge(player_id: player.id)
        end

        @suggestion = Suggestion.new(permitted_params.except(:player_name).slice(:note, :player_id))

        if @suggestion.save
          render json: @suggestion, status: :created
        else
          render json: { errors: @suggestion.errors.messages }, status: :unprocessable_content
        end
      end

      private

      def player_not_found(exception)
        render json: { errors: { player_name: [ exception.message ] } }, status: :unprocessable_content
      end
    end
  end
end
