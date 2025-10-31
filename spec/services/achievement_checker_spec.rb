require 'rails_helper'

RSpec.describe AchievementChecker do
  let(:player) { create(:player) }

  describe '.check_and_award' do
    context 'when player meets achievement criteria for multiple achievements' do
      let(:game_session) do
        create(:game_session,
               player: player,
               lilies_collected: 15,
               hearts_collected: 25,
               ended_at: Time.current,
               final_score: 1000)
      end

      it 'creates EarnedAchievement records for all earned achievements' do
        expect {
          described_class.check_and_award(player, game_session)
        }.to change(EarnedAchievement, :count).by(2)
      end

      it 'creates Achievement records from templates' do
        expect {
          described_class.check_and_award(player, game_session)
        }.to change(Achievement, :count).by(2)
      end

      it 'links achievements to the game session' do
        described_class.check_and_award(player, game_session)

        earned_achievements = player.earned_achievements
        expect(earned_achievements.map(&:game_session)).to all(eq(game_session))
      end

      it 'returns newly earned achievement records' do
        newly_earned = described_class.check_and_award(player, game_session)

        expect(newly_earned.size).to eq(2)
        expect(newly_earned.map(&:achievement_type)).to contain_exactly('lily_collector', 'heart_hoarder')
      end

      it 'logs achievement awards' do
        allow(Rails.logger).to receive(:info)

        described_class.check_and_award(player, game_session)

        expect(Rails.logger).to have_received(:info).with(/earned achievement: Lily Collector/)
        expect(Rails.logger).to have_received(:info).with(/earned achievement: Heart Hoarder/)
      end
    end

    context 'when player meets criteria for only one achievement' do
      let(:game_session) do
        create(:game_session,
               player: player,
               lilies_collected: 15,
               hearts_collected: 10,
               ended_at: Time.current,
               final_score: 500)
      end

      it 'creates EarnedAchievement record only for met criteria' do
        expect {
          described_class.check_and_award(player, game_session)
        }.to change(EarnedAchievement, :count).by(1)
      end

      it 'awards the correct achievement' do
        newly_earned = described_class.check_and_award(player, game_session)

        expect(newly_earned.size).to eq(1)
        expect(newly_earned.first.achievement_type).to eq('lily_collector')
      end
    end

    context 'when player does not meet any criteria' do
      let(:game_session) do
        create(:game_session,
               player: player,
               lilies_collected: 5,
               hearts_collected: 10,
               ended_at: Time.current,
               final_score: 100)
      end

      it 'does not create any EarnedAchievement records' do
        expect {
          described_class.check_and_award(player, game_session)
        }.not_to change(EarnedAchievement, :count)
      end

      it 'does not create any Achievement records' do
        expect {
          described_class.check_and_award(player, game_session)
        }.not_to change(Achievement, :count)
      end

      it 'returns empty array' do
        newly_earned = described_class.check_and_award(player, game_session)
        expect(newly_earned).to be_empty
      end
    end

    context 'when player already earned one achievement' do
      let(:game_session) do
        create(:game_session,
               player: player,
               lilies_collected: 15,
               hearts_collected: 25,
               ended_at: Time.current,
               final_score: 1000)
      end

      before do
        # Player already earned Lily Collector
        lily_achievement = Achievement.from_template(Achievement::LilyCollector)
        create(:earned_achievement, player: player, achievement: lily_achievement)
      end

      it 'only awards new achievements' do
        expect {
          described_class.check_and_award(player, game_session)
        }.to change(EarnedAchievement, :count).by(1)
      end

      it 'does not award achievement twice' do
        newly_earned = described_class.check_and_award(player, game_session)

        expect(newly_earned.size).to eq(1)
        expect(newly_earned.first.achievement_type).to eq('heart_hoarder')
      end

      it 'only checks unearned templates' do
        allow(Achievement::LilyCollector).to receive(:check_progress)
        allow(Achievement::HeartHoarder).to receive(:check_progress).and_call_original

        described_class.check_and_award(player, game_session)

        expect(Achievement::LilyCollector).not_to have_received(:check_progress)
        expect(Achievement::HeartHoarder).to have_received(:check_progress)
      end
    end

    context 'when player already earned all achievements' do
      let(:game_session) do
        create(:game_session,
               player: player,
               lilies_collected: 15,
               hearts_collected: 25,
               ended_at: Time.current,
               final_score: 1000)
      end

      before do
        # Player already earned all achievements
        Achievement.templates.each do |template|
          achievement = Achievement.from_template(template)
          create(:earned_achievement, player: player, achievement: achievement)
        end
      end

      it 'does not create any new EarnedAchievement records' do
        expect {
          described_class.check_and_award(player, game_session)
        }.not_to change(EarnedAchievement, :count)
      end

      it 'returns empty array' do
        newly_earned = described_class.check_and_award(player, game_session)
        expect(newly_earned).to be_empty
      end
    end

    context 'when Achievement record already exists but player has not earned it' do
      let(:game_session) do
        create(:game_session,
               player: player,
               lilies_collected: 15,
               hearts_collected: 10,
               ended_at: Time.current,
               final_score: 500)
      end

      before do
        # Achievement record exists from another player earning it
        Achievement.from_template(Achievement::LilyCollector)
      end

      it 'reuses existing Achievement record' do
        expect {
          described_class.check_and_award(player, game_session)
        }.not_to change(Achievement, :count)
      end

      it 'awards the achievement to the player' do
        expect {
          described_class.check_and_award(player, game_session)
        }.to change(EarnedAchievement, :count).by(1)
      end
    end
  end

  describe '#unearned_templates' do
    let(:checker) { described_class.new(player, build(:game_session)) }

    it 'delegates to Achievement.unearned_templates_for' do
      allow(Achievement).to receive(:unearned_templates_for).with(player)

      checker.send(:unearned_templates)

      expect(Achievement).to have_received(:unearned_templates_for).with(player)
    end
  end
end
