require 'rails_helper'

RSpec.describe "Players::Profiles", type: :request do
  let(:player) { create(:player, email: 'test@example.com', username: 'testuser', password: 'password123') }
  let(:auth_headers) do
    post '/players/sign_in', params: { player: { email: player.email, password: 'password123' } }
    token = response.headers['Authorization']
    { 'Authorization' => token }
  end

  describe "PATCH /players/profile" do
    context "when authenticated" do
      context "with valid player attributes" do
        it "updates the player attributes" do
          patch '/players/profile',
                params: {
                  player: {
                    display_name: 'New Display Name',
                    username: 'newusername'
                  }
                },
                headers: auth_headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json['player']['display_name']).to eq('New Display Name')
          expect(json['player']['username']).to eq('newusername')
          expect(json['message']).to eq('Profile updated successfully.')
        end
      end

      context "with valid profile attributes" do
        it "creates and updates the player profile" do
          patch '/players/profile',
                params: {
                  player: {
                    profile: {
                      bio: 'I love otters!',
                      favorite_otter_fact: 'Otters hold hands when they sleep',
                      title: 'Otter Expert',
                      location: 'River Valley'
                    }
                  }
                },
                headers: auth_headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json['player']['profile']['bio']).to eq('I love otters!')
          expect(json['player']['profile']['favorite_otter_fact']).to eq('Otters hold hands when they sleep')
          expect(json['player']['profile']['title']).to eq('Otter Expert')
          expect(json['player']['profile']['location']).to eq('River Valley')
          expect(json['message']).to eq('Profile updated successfully.')
        end
      end

      context "with both player and profile attributes" do
        it "updates both player and profile" do
          patch '/players/profile',
                params: {
                  player: {
                    display_name: 'Otter Master',
                    avatar_url: 'https://example.com/avatar.png',
                    profile: {
                      bio: 'Professional otter enthusiast',
                      title: 'Master of Otters'
                    }
                  }
                },
                headers: auth_headers

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)

          expect(json['player']['display_name']).to eq('Otter Master')
          expect(json['player']['avatar_url']).to eq('https://example.com/avatar.png')
          expect(json['player']['profile']['bio']).to eq('Professional otter enthusiast')
          expect(json['player']['profile']['title']).to eq('Master of Otters')
        end
      end

      context "with invalid username (too short)" do
        it "returns validation errors" do
          patch '/players/profile',
                params: {
                  player: {
                    username: 'ab'
                  }
                },
                headers: auth_headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json['errors']).to be_present
          expect(json['errors'].first).to include('too short')
        end
      end

      context "with duplicate username" do
        let!(:other_player) { create(:player, username: 'existinguser') }

        it "returns validation errors" do
          patch '/players/profile',
                params: {
                  player: {
                    username: 'existinguser'
                  }
                },
                headers: auth_headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json['errors']).to be_present
          expect(json['errors'].first).to include('taken')
        end
      end

      context "with duplicate email" do
        let!(:other_player) { create(:player, email: 'existing@example.com') }

        it "returns validation errors" do
          patch '/players/profile',
                params: {
                  player: {
                    email: 'existing@example.com'
                  }
                },
                headers: auth_headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json['errors']).to be_present
          expect(json['errors'].first).to include('taken')
        end
      end

      context "with invalid URL format" do
        it "returns validation errors for avatar_url" do
          patch '/players/profile',
                params: {
                  player: {
                    avatar_url: 'not-a-valid-url'
                  }
                },
                headers: auth_headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json['errors']).to be_present
          expect(json['errors'].first).to include('valid URL')
        end
      end

      context "with profile fields that are too long" do
        it "returns validation errors" do
          patch '/players/profile',
                params: {
                  player: {
                    profile: {
                      bio: 'a' * 501  # Exceeds 500 character limit
                    }
                  }
                },
                headers: auth_headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json['errors']).to be_present
          expect(json['errors'].first).to include('too long')
        end
      end
    end

    context "when not authenticated" do
      it "returns unauthorized error" do
        patch '/players/profile',
              params: {
                player: {
                  display_name: 'New Name'
                }
              }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
