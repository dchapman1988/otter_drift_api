require 'rails_helper'

RSpec.describe "Api::V1::Players::Profiles Additional Coverage", type: :request do
  let(:player) { create(:player, email: 'test@example.com', username: 'testuser', password: 'password123') }
  let(:auth_token) do
    post '/players/sign_in', params: { player: { email: player.email, password: 'password123' } }
    response.headers['Authorization']
  end

  describe "PATCH /api/v1/players/profile" do
    context "updating only profile attributes" do
      it "updates profile without player attributes" do
        patch '/api/v1/players/profile',
              params: {
                player: {
                  profile: {
                    bio: 'Updated bio',
                    favorite_otter_fact: 'Otters hold hands while sleeping'
                  }
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['player']['profile']['bio']).to eq('Updated bio')
        expect(json['player']['profile']['favorite_otter_fact']).to eq('Otters hold hands while sleeping')
      end
    end

    context "profile validation errors" do
      it "returns errors when profile bio is too long" do
        patch '/api/v1/players/profile',
              params: {
                player: {
                  profile: {
                    bio: 'a' * 501  # Max is 500 characters
                  }
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Bio is too long (maximum is 500 characters)")
        expect(json['details']).to be_present
      end

      it "returns errors when profile title is too long" do
        patch '/api/v1/players/profile',
              params: {
                player: {
                  profile: {
                    title: 'a' * 101  # Max is 100 characters
                  }
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context "combined player and profile errors" do
      it "returns validation errors with details" do
        patch '/api/v1/players/profile',
              params: {
                player: {
                  username: 'ab',  # Too short (min 3 characters)
                  profile: {
                    bio: 'a' * 501  # Too long (max 500 characters)
                  }
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        # Should have errors and details from validation failures
        expect(json['errors']).to be_present
        expect(json['errors'].length).to be >= 1
        expect(json['details']).to be_present
      end
    end
  end
end
