require 'rails_helper'

RSpec.describe JwtDenylist, type: :model do
  describe "token revocation" do
    let(:player) { create(:player, email: 'denylist@example.com', password: 'password123', password_confirmation: 'password123') }
    let(:jti) { SecureRandom.uuid }
    let(:exp) { 30.days.from_now.to_i }

    it "can store revoked tokens" do
      expect {
        JwtDenylist.create!(jti: jti, exp: Time.at(exp))
      }.to change(JwtDenylist, :count).by(1)
    end

    it "requires jti field" do
      denylist_entry = JwtDenylist.new(exp: Time.at(exp))
      expect(denylist_entry).not_to be_valid
    end

    it "requires exp field" do
      denylist_entry = JwtDenylist.new(jti: jti)
      expect(denylist_entry).not_to be_valid
    end

    it "stores the correct expiration time" do
      entry = JwtDenylist.create!(jti: jti, exp: Time.at(exp))
      expect(entry.exp.to_i).to eq(exp)
    end
  end


  describe "performance: denylist cleanup" do
    it "should have a mechanism to clean up expired tokens" do
      # Create expired denylist entries
      10.times do
        JwtDenylist.create!(
          jti: SecureRandom.uuid,
          exp: 1.day.ago
        )
      end

      # Create valid (not expired) entries
      5.times do
        JwtDenylist.create!(
          jti: SecureRandom.uuid,
          exp: 1.day.from_now
        )
      end

      # There should be a way to clean up expired entries
      # This is important for database performance
      expired_count = JwtDenylist.where('exp < ?', Time.current).count
      expect(expired_count).to eq(10)

      # You should implement a cleanup task, e.g.:
      # JwtDenylist.where('exp < ?', Time.current).delete_all
    end

    it "stores reasonable expiration times" do
      # Verify tokens don't have unreasonably long expiration
      entry = JwtDenylist.create!(
        jti: SecureRandom.uuid,
        exp: 30.days.from_now
      )

      # Expiration should be reasonable (not 100 years in the future)
      expect(entry.exp).to be < 1.year.from_now
    end
  end

  describe "security: jti uniqueness and collision" do
    it "enforces uniqueness of jti" do
      jti = SecureRandom.uuid
      JwtDenylist.create!(jti: jti, exp: 30.days.from_now)

      # Attempting to create duplicate should fail
      duplicate = JwtDenylist.new(jti: jti, exp: 30.days.from_now)
      expect(duplicate).not_to be_valid
    end

    it "handles concurrent token revocations" do
      jtis = 5.times.map { SecureRandom.uuid }

      threads = jtis.map do |jti|
        Thread.new do
          JwtDenylist.create!(jti: jti, exp: 30.days.from_now)
        end
      end

      threads.each(&:join)

      # All tokens should be in denylist
      expect(JwtDenylist.where(jti: jtis).count).to eq(5)
    end
  end

  describe "monitoring and auditing" do
    it "tracks when tokens were revoked" do
      entry = JwtDenylist.create!(
        jti: SecureRandom.uuid,
        exp: 30.days.from_now
      )

      expect(entry.created_at).to be_present
      expect(entry.created_at).to be_within(1.second).of(Time.current)
    end

    it "can query denylist size for monitoring" do
      # Important for security monitoring
      initial_count = JwtDenylist.count

      3.times do
        JwtDenylist.create!(
          jti: SecureRandom.uuid,
          exp: 30.days.from_now
        )
      end

      expect(JwtDenylist.count).to eq(initial_count + 3)
    end
  end
end
