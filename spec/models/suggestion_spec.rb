require 'rails_helper'

RSpec.describe Suggestion, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:player).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:note) }
    it { is_expected.to validate_length_of(:note).is_at_least(3) }
    it { is_expected.to validate_length_of(:note).is_at_most(1000) }
  end

  describe '#to_s' do
    context 'when note is present' do
      let(:suggestion) { build(:suggestion, note: 'Great game!') }

      it 'returns the note' do
        expect(suggestion.to_s).to eq('Great game!')
      end
    end

    context 'when note is blank' do
      let(:suggestion) { build(:suggestion, note: '') }

      it 'returns the default string representation' do
        # Should fall back to ApplicationRecord's to_s
        expect(suggestion.to_s).not_to be_empty
      end
    end
  end

  describe 'factory' do
    context ':suggestion trait' do
      let(:suggestion) { build(:suggestion) }

      it 'creates a valid suggestion without a player' do
        expect(suggestion).to be_valid
      end
    end

    context ':from_guest trait' do
      let(:suggestion) { build(:suggestion, :from_guest) }

      it 'creates a suggestion with no player' do
        expect(suggestion.player).to be_nil
      end
    end

    context ':from_player trait' do
      let(:suggestion) { build(:suggestion, :from_player) }

      it 'creates a suggestion with an associated player' do
        expect(suggestion.player).to be_a(Player)
      end
    end
  end
end
