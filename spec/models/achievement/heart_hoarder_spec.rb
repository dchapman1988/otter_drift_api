require 'rails_helper'

RSpec.describe Achievement::HeartHoarder do
  describe '.achievement_type' do
    it 'returns the achievement type identifier' do
      expect(described_class.achievement_type).to eq('heart_hoarder')
    end
  end

  describe '.achievement_name' do
    it 'returns the achievement name' do
      expect(described_class.achievement_name).to eq('Heart Hoarder')
    end
  end

  describe '.points' do
    it 'returns the points value' do
      expect(described_class.points).to eq(150)
    end
  end

  describe '.requirements_text' do
    it 'returns the requirements description' do
      expect(described_class.requirements_text).to eq('Collect 20 hearts in a single game')
    end
  end

  describe '.check_progress' do
    context 'when game session has 20 or more hearts' do
      let(:game_session) { build(:game_session, hearts_collected: 20) }

      it 'returns true' do
        expect(described_class.check_progress(game_session)).to be true
      end
    end

    context 'when game session has more than 20 hearts' do
      let(:game_session) { build(:game_session, hearts_collected: 25) }

      it 'returns true' do
        expect(described_class.check_progress(game_session)).to be true
      end
    end

    context 'when game session has fewer than 20 hearts' do
      let(:game_session) { build(:game_session, hearts_collected: 19) }

      it 'returns false' do
        expect(described_class.check_progress(game_session)).to be false
      end
    end

    context 'when game session has no hearts' do
      let(:game_session) { build(:game_session, hearts_collected: 0) }

      it 'returns false' do
        expect(described_class.check_progress(game_session)).to be false
      end
    end

    context 'when hearts_collected is nil' do
      let(:game_session) { build(:game_session, hearts_collected: nil) }

      it 'returns false' do
        expect(described_class.check_progress(game_session)).to be false
      end
    end
  end

  describe 'LSP compliance' do
    it 'implements all required Achievement template methods' do
      expect(described_class).to respond_to(:achievement_type)
      expect(described_class).to respond_to(:achievement_name)
      expect(described_class).to respond_to(:points)
      expect(described_class).to respond_to(:requirements_text)
      expect(described_class).to respond_to(:check_progress)
    end
  end
end
