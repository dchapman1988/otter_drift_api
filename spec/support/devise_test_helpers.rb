module DeviseTestHelpers
  def sign_in(player)
    # For API-only applications, we need to manually set the warden user
    # since there's no session middleware
    # We'll use a different approach - set the player in the controller instance
    allow_any_instance_of(ApplicationController).to receive(:warden).and_return(
      double('warden',
        authenticated?: true,
        user: player,
        set_user: true,
        logout: true
      )
    )
  end

  def sign_out(player = nil)
    allow_any_instance_of(ApplicationController).to receive(:warden).and_return(
      double('warden',
        authenticated?: false,
        user: nil,
        set_user: true,
        logout: true
      )
    )
  end
end

RSpec.configure do |config|
  config.include DeviseTestHelpers, type: :request
end
