require 'rails_helper'

RSpec.describe WelcomeMailer, type: :mailer do
  describe '#welcome_email' do
    let(:player) { create(:player, email: 'player@example.com', username: 'otterfan', display_name: 'Otter Fan') }
    let(:mail) { WelcomeMailer.welcome_email(player) }

    it 'renders the subject' do
      expect(mail.subject).to eq('🦦 Welcome to Otter Drift! Get ready to collect some lilies!')
    end

    it 'sends to the player email' do
      expect(mail.to).to eq([ player.email ])
    end

    it 'sends from the default address' do
      expect(mail.from).to eq([ 'hello@otterdrift.com' ])
    end

    describe 'email body' do
      it 'includes the player display name in HTML body' do
        expect(mail.html_part.body.encoded).to include('Otter Fan')
      end

      it 'includes the player display name in text body' do
        expect(mail.text_part.body.encoded).to include('Otter Fan')
      end

      it 'includes lily collection tip in HTML body' do
        expect(mail.html_part.body.encoded).to include('Collect lilies')
      end

      it 'includes lily collection tip in text body' do
        expect(mail.text_part.body.encoded).to include('Collect lilies')
      end

      it 'includes log warning in HTML body' do
        expect(mail.html_part.body.encoded).to include('Watch out for logs')
      end

      it 'includes log warning in text body' do
        expect(mail.text_part.body.encoded).to include('Watch out for logs')
      end

      it 'includes high score encouragement in HTML body' do
        expect(mail.html_part.body.encoded).to include('Chase that high score')
      end

      it 'includes high score encouragement in text body' do
        expect(mail.text_part.body.encoded).to include('Chase that high score')
      end

      it 'includes otter emojis in HTML body' do
        expect(mail.html_part.body.encoded).to include('🦦')
      end

      it 'includes otter emojis in text body' do
        expect(mail.text_part.body.encoded).to include('🦦')
      end
    end

    context 'when player has no display_name' do
      let(:player) { create(:player, email: 'player@example.com', username: 'otterfan', display_name: nil) }

      it 'uses username in HTML body' do
        expect(mail.html_part.body.encoded).to include('otterfan')
      end

      it 'uses username in text body' do
        expect(mail.text_part.body.encoded).to include('otterfan')
      end
    end
  end
end
