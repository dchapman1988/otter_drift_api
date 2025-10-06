module JwtAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
    around_action :set_current_attributes
  end

  private

  def authenticate_request
    # Try Devise authentication first (for player endpoints)
    if authenticated_via_devise?
      return true
    end
    
    # Fall back to client authentication
    authenticate_client
  end

  def authenticated_via_devise?
    warden&.authenticated?(:player)
  end

  def authenticate_client
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    
    return unless header
    
    begin
      @decoded = JsonWebToken.decode(header)
      @current_client_id = @decoded[:client_id]
    rescue JWT::DecodeError => e
      render json: { errors: ['Invalid token'] }, status: :unauthorized
    end
  end

  def set_current_attributes
    # Set Current.player from Devise authentication
    if authenticated_via_devise?
      Current.player = warden.user(:player)
    end
    
    yield
  ensure
    # Clear Current attributes after each request
    Current.reset
  end

  def current_client_id
    @current_client_id
  end
  
  def current_player
    Current.player
  end
end
