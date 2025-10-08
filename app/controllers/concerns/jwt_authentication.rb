module JwtAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request
    around_action :set_current_attributes
  end

  private

  def authenticate_request
    # Try Devise authentication first (for player endpoints)
    # This will attempt JWT authentication via devise-jwt if Authorization header is present
    if authenticate_devise_player
      return true
    end
    
    # Fall back to client authentication
    authenticate_client
  end

  def authenticate_devise_player
    # First check if already authenticated (from session)
    return true if warden&.authenticated?(:player)
    
    # Try to authenticate via JWT (devise-jwt will handle this)
    # The jwt strategy is automatically registered by devise-jwt
    if request.headers['Authorization'].present?
      Rails.logger.info "🔐 JWT Auth: Authorization header present, attempting authentication..."
      result = warden&.authenticate(scope: :player, store: false)
      Rails.logger.info "🔐 JWT Auth: Result = #{result.inspect}, Authenticated? #{warden&.authenticated?(:player)}"
      result
    else
      Rails.logger.info "🔐 JWT Auth: No Authorization header found"
      nil
    end
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
      Rails.logger.info "✅ Current.player set to: #{Current.player.inspect}"
    else
      Rails.logger.info "❌ No authenticated player, Current.player will be nil"
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
