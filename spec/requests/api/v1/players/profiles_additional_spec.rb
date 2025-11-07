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

    context "avatar upload" do
      let(:valid_image) do
        Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/avatar.png'),
          'image/png'
        )
      end

      let(:invalid_image_type) do
        Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/document.pdf'),
          'application/pdf'
        )
      end

      it "successfully uploads a valid avatar image" do
        patch '/api/v1/players/profile',
              params: {
                player: {
                  avatar: valid_image
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['player']['avatar']).to be_present
        expect(json['player']['avatar']['url']).to be_present
        expect(json['player']['avatar']['filename']).to eq('avatar.png')
        expect(json['player']['avatar']['content_type']).to eq('image/png')
        expect(json['player']['avatar']['byte_size']).to be > 0

        player.reload
        expect(player.avatar).to be_attached
      end

      it "returns avatar data in GET response when avatar is attached" do
        player.avatar.attach(valid_image)
        player.save!

        get '/api/v1/players/profile',
            headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['player']['avatar']).to be_present
        expect(json['player']['avatar']['url']).to be_present
        expect(json['player']['avatar']['filename']).to eq('avatar.png')
      end

      it "returns null avatar data when no avatar is attached" do
        get '/api/v1/players/profile',
            headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['player']['avatar']).to be_nil
      end

      it "rejects invalid file types" do
        patch '/api/v1/players/profile',
              params: {
                player: {
                  avatar: invalid_image_type
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        # The magic number validation kicks in before content type validation
        expect(json['errors']).to include("Avatar file content does not match the declared image type")
      end

      it "rejects text file with image extension" do
        # Create a text file disguised as an image
        File.write(Rails.root.join('spec/fixtures/files/fake.png'), 'This is actually a text file')

        fake_image = Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/fake.png'),
          'image/png'
        )

        patch '/api/v1/players/profile',
              params: {
                player: {
                  avatar: fake_image
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['errors']).to include("Avatar file content does not match the declared image type")

        # Cleanup
        File.delete(Rails.root.join('spec/fixtures/files/fake.png'))
      end

      it "rejects executable file as image" do
        # Create a fake executable file
        File.binwrite(Rails.root.join('spec/fixtures/files/malware.png'), "\x4D\x5A" + 'X' * 100) # MZ header (EXE)

        exe_file = Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/malware.png'),
          'image/png'
        )

        patch '/api/v1/players/profile',
              params: {
                player: {
                  avatar: exe_file
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['errors']).to include("Avatar file content does not match the declared image type")

        # Cleanup
        File.delete(Rails.root.join('spec/fixtures/files/malware.png'))
      end

      it "rejects SVG files (potential XSS vector)" do
        # SVG files can contain JavaScript and are a common XSS vector
        svg_content = '<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg"><script>alert("XSS")</script></svg>'
        File.write(Rails.root.join('spec/fixtures/files/xss.svg'), svg_content)

        svg_file = Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/xss.svg'),
          'image/svg+xml'
        )

        patch '/api/v1/players/profile',
              params: {
                player: {
                  avatar: svg_file
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['errors']).to include("Avatar file content does not match the declared image type")

        # Cleanup
        File.delete(Rails.root.join('spec/fixtures/files/xss.svg'))
      end

      it "rejects files that are too large" do
        # Create a mock file that reports as being over 5MB
        large_file = Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/avatar.png'),
          'image/png'
        )

        allow(large_file).to receive(:size).and_return(6.megabytes)

        # Attach the file directly to test validation
        player.avatar.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/avatar.png')),
          filename: 'large.png',
          content_type: 'image/png'
        )

        # Stub byte_size to return over 5MB
        allow(player.avatar).to receive(:byte_size).and_return(6.megabytes)

        expect(player.valid?).to be false
        expect(player.errors[:avatar]).to include("must be less than 5MB")
      end

      it "can update profile and avatar simultaneously" do
        patch '/api/v1/players/profile',
              params: {
                player: {
                  display_name: 'Avatar Tester',
                  avatar: valid_image,
                  profile: {
                    bio: 'I have a new avatar!'
                  }
                }
              },
              headers: { 'Authorization' => auth_token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['player']['display_name']).to eq('Avatar Tester')
        expect(json['player']['profile']['bio']).to eq('I have a new avatar!')
        expect(json['player']['avatar']).to be_present

        player.reload
        expect(player.avatar).to be_attached
        expect(player.display_name).to eq('Avatar Tester')
      end

      context "security validations" do
        it "rejects file with fake content type (content-type spoofing)" do
          # Create a text file pretending to be a PNG
          fake_image = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/document.pdf'),
            'image/png' # Lying about content type
          )

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: fake_image
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)

          expect(json['errors']).to include("Avatar file content does not match the declared image type")
        end

        it "sanitizes malicious filenames (directory traversal)" do
          malicious_file = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/avatar.png'),
            'image/png'
          )

          # Simulate a filename with path traversal attempt
          allow(malicious_file).to receive(:original_filename).and_return('../../../etc/passwd.png')

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: malicious_file
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:ok)
          player.reload

          # Filename should be sanitized, not contain path traversal
          expect(player.avatar.filename.to_s).not_to include('..')
          expect(player.avatar.filename.to_s).not_to include('/')
          expect(player.avatar.filename.to_s).to eq('passwd.png')
        end

        it "sanitizes filenames with special characters" do
          malicious_file = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/avatar.png'),
            'image/png'
          )

          allow(malicious_file).to receive(:original_filename).and_return('<script>alert("xss")</script>.png')

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: malicious_file
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:ok)
          player.reload

          # Filename should be sanitized
          expect(player.avatar.filename.to_s).not_to include('<')
          expect(player.avatar.filename.to_s).not_to include('>')
          # 'script' is a valid word part that remains after sanitization, we just verify dangerous chars are removed
        end

        it "prevents double extension exploits" do
          malicious_file = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/avatar.png'),
            'image/png'
          )

          allow(malicious_file).to receive(:original_filename).and_return('image.jpg.php.png')

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: malicious_file
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:ok)
          player.reload

          # Should only keep the last extension
          expect(player.avatar.filename.to_s).to eq('image_jpg_php.png')
        end

        it "validates JPEG files correctly" do
          # Create a minimal JPEG fixture
          jpeg_data = [0xFF, 0xD8, 0xFF, 0xE0].pack('C*') + 'X' * 100
          File.binwrite(Rails.root.join('spec/fixtures/files/test.jpg'), jpeg_data)

          jpeg_file = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/test.jpg'),
            'image/jpeg'
          )

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: jpeg_file
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:ok)
          player.reload
          expect(player.avatar).to be_attached

          # Cleanup
          File.delete(Rails.root.join('spec/fixtures/files/test.jpg'))
        end

        it "validates GIF files correctly" do
          # Create a minimal GIF fixture
          gif_data = "GIF89a" + 'X' * 100
          File.write(Rails.root.join('spec/fixtures/files/test.gif'), gif_data)

          gif_file = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/test.gif'),
            'image/gif'
          )

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: gif_file
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:ok)
          player.reload
          expect(player.avatar).to be_attached

          # Cleanup
          File.delete(Rails.root.join('spec/fixtures/files/test.gif'))
        end

        it "validates WebP files correctly" do
          # Create a minimal WebP fixture (RIFF + size + WEBP)
          webp_data = "RIFF" + [16].pack('V') + "WEBP" + 'X' * 100
          File.write(Rails.root.join('spec/fixtures/files/test.webp'), webp_data)

          webp_file = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/test.webp'),
            'image/webp'
          )

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: webp_file
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:ok)
          player.reload
          expect(player.avatar).to be_attached

          # Cleanup
          File.delete(Rails.root.join('spec/fixtures/files/test.webp'))
        end

        it "rejects files with unsupported content type in validation" do
          # Try to upload with a completely bogus content type
          fake_file = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/avatar.png'),
            'application/x-evil'
          )

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: fake_file
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include("Avatar file content does not match the declared image type")
        end

        it "rejects file when ActiveStorage reports invalid content type" do
          # This tests the Player model's avatar_validation method
          # We need to bypass the controller validation and hit the model validation
          player.avatar.attach(
            io: File.open(Rails.root.join('spec/fixtures/files/document.pdf')),
            filename: 'test.pdf',
            content_type: 'application/pdf'
          )

          expect(player.valid?).to be false
          expect(player.errors[:avatar]).to include("must be a PNG, JPG, JPEG, GIF, or WebP image")
        end

        it "handles exceptions during file content validation" do
          bad_file = Rack::Test::UploadedFile.new(
            Rails.root.join('spec/fixtures/files/avatar.png'),
            'image/png'
          )

          # Mock tempfile to raise an exception during read
          mock_tempfile = instance_double(Tempfile)
          allow(mock_tempfile).to receive(:rewind)
          allow(mock_tempfile).to receive(:read).and_raise(IOError.new("Disk read error"))
          allow(mock_tempfile).to receive(:size).and_return(1000)
          allow(bad_file).to receive(:tempfile).and_return(mock_tempfile)
          allow(bad_file).to receive(:content_type).and_return('image/png')
          allow(bad_file).to receive(:original_filename).and_return('test.png')

          patch '/api/v1/players/profile',
                params: {
                  player: {
                    avatar: bad_file
                  }
                },
                headers: { 'Authorization' => auth_token }

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include("Avatar file content does not match the declared image type")
        end
      end
    end
  end
end
