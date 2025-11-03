require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  describe 'default configuration' do
    it 'sets default from address' do
      expect(ApplicationMailer.default[:from]).to eq("hello@otterdrift.com")
    end

    it 'uses mailer layout' do
      expect(ApplicationMailer._layout).to eq("mailer")
    end
  end
end
