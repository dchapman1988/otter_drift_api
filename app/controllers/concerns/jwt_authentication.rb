module JwtAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
  end

  private

  def authenticate_request
    return true if Rails.env.test?
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    begin
      @decoded = JsonWebToken.decode(header)
      @current_client_id = @decoded[:client_id]
    rescue JWT::DecodeError => e
      render json: { errors: ['Invalid token'] }, status: :unauthorized
    end
  end

  def current_client_id
    @current_client_id
  end
end
