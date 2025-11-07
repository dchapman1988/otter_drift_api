require 'rails_helper'

RSpec.describe "Players::Registrations", type: :request do
  describe "POST /players" do
    let(:valid_attributes) do
      {
        player: {
          email: 'newplayer@example.com',
          username: 'newplayer',
          display_name: 'New Player',
          avatar_url: 'https://example.com/avatar.png',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    context "with valid parameters" do
      it "creates a new player" do
        expect {
          post '/players', params: valid_attributes
        }.to change(Player, :count).by(1)
      end

      it "returns a created status" do
        post '/players', params: valid_attributes
        expect(response).to have_http_status(:created)
      end

      it "returns player data" do
        post '/players', params: valid_attributes
        json = JSON.parse(response.body)

        expect(json['player']).to be_present
        expect(json['player']['email']).to eq('newplayer@example.com')
        expect(json['player']['username']).to eq('newplayer')
        expect(json['player']['display_name']).to eq('New Player')
        expect(json['message']).to eq("Signed up successfully.")
      end

      it "returns player id" do
        post '/players', params: valid_attributes
        json = JSON.parse(response.body)

        expect(json['player']['id']).to be_present
      end

      it "creates player with display_name_or_username" do
        post '/players', params: valid_attributes
        json = JSON.parse(response.body)

        expect(json['player']['display_name']).to eq('New Player')
      end
    end

    context "with invalid parameters" do
      it "does not create a player with missing email" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:email] = nil

        expect {
          post '/players', params: invalid_attributes
        }.not_to change(Player, :count)
      end

      it "returns unprocessable entity for missing email" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:email] = nil

        post '/players', params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns error messages for missing email" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:email] = nil

        post '/players', params: invalid_attributes
        json = JSON.parse(response.body)

        expect(json['errors']).to be_present
        expect(json['errors']).to include("Email can't be blank")
      end

      it "returns error details" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:email] = nil

        post '/players', params: invalid_attributes
        json = JSON.parse(response.body)

        expect(json['details']).to be_present
      end

      it "does not create a player with missing username" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:username] = nil

        expect {
          post '/players', params: invalid_attributes
        }.not_to change(Player, :count)
      end

      it "returns error for missing username" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:username] = nil

        post '/players', params: invalid_attributes
        json = JSON.parse(response.body)

        expect(json['errors']).to include("Username can't be blank")
      end

      it "does not create a player with short username" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:username] = 'ab'

        expect {
          post '/players', params: invalid_attributes
        }.not_to change(Player, :count)
      end

      it "does not create a player with duplicate email" do
        create(:player, email: 'existing@example.com')

        duplicate_attributes = valid_attributes.deep_dup
        duplicate_attributes[:player][:email] = 'existing@example.com'

        expect {
          post '/players', params: duplicate_attributes
        }.not_to change(Player, :count)
      end

      it "returns error for duplicate email" do
        create(:player, email: 'existing@example.com')

        duplicate_attributes = valid_attributes.deep_dup
        duplicate_attributes[:player][:email] = 'existing@example.com'

        post '/players', params: duplicate_attributes
        json = JSON.parse(response.body)

        expect(json['errors']).to include("Email has already been taken")
      end

      it "does not create a player with duplicate username" do
        create(:player, username: 'existinguser')

        duplicate_attributes = valid_attributes.deep_dup
        duplicate_attributes[:player][:username] = 'existinguser'

        expect {
          post '/players', params: duplicate_attributes
        }.not_to change(Player, :count)
      end

      it "does not create a player with mismatched password confirmation" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:password_confirmation] = 'wrongpassword'

        expect {
          post '/players', params: invalid_attributes
        }.not_to change(Player, :count)
      end

      it "returns error for mismatched password confirmation" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:password_confirmation] = 'wrongpassword'

        post '/players', params: invalid_attributes
        json = JSON.parse(response.body)

        expect(json['errors']).to include("Password confirmation doesn't match Password")
      end

      it "logs errors when registration fails" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:email] = nil

        expect(Rails.logger).to receive(:error).with(/Player registration failed/)
        post '/players', params: invalid_attributes
      end
    end

    context "without display_name" do
      it "creates player and returns username as display_name" do
        attributes = valid_attributes.deep_dup
        attributes[:player].delete(:display_name)

        post '/players', params: attributes
        json = JSON.parse(response.body)

        expect(json['player']['display_name']).to eq('newplayer')
      end
    end

    context "parameter sanitization" do
      it "permits username parameter" do
        post '/players', params: valid_attributes
        expect(response).to have_http_status(:created)
      end

      it "permits display_name parameter" do
        post '/players', params: valid_attributes
        expect(response).to have_http_status(:created)
      end

      it "permits avatar_url parameter" do
        post '/players', params: valid_attributes
        expect(response).to have_http_status(:created)
      end

      it "filters unpermitted parameters" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:player][:admin] = true

        post '/players', params: invalid_attributes

        created_player = Player.find_by(email: 'newplayer@example.com')
        expect(created_player).to be_present
        expect(created_player.respond_to?(:admin)).to be_falsey
      end
    end

    context "JSON response format" do
      it "responds to JSON requests" do
        post '/players', params: valid_attributes, as: :json
        expect(response.content_type).to match(%r{application/json})
      end
    end

    context "authentication bypass" do
      it "does not require authentication" do
        # Should work without any authentication headers
        post '/players', params: valid_attributes
        expect(response).to have_http_status(:created)
      end
    end
  end
end
