require 'rails_helper'

RSpec.describe DeviseTestHelpers, type: :request do
  let(:player) { create(:player) }

  describe '#sign_out' do
    it 'configures warden to return unauthenticated state' do
      # Setup initial authenticated state
      sign_in(player)

      # Sign out
      sign_out

      # Verify warden mock returns unauthenticated state
      warden_double = ApplicationController.new.warden
      expect(warden_double.authenticated?).to be false
      expect(warden_double.user).to be_nil
    end

    it 'works without passing a player argument' do
      expect { sign_out }.not_to raise_error
    end

    it 'works with a player argument for backwards compatibility' do
      expect { sign_out(player) }.not_to raise_error
    end
  end

  describe '#sign_in' do
    it 'configures warden to return authenticated state' do
      sign_in(player)

      warden_double = ApplicationController.new.warden
      expect(warden_double.authenticated?).to be true
      expect(warden_double.user).to eq(player)
    end
  end
end
