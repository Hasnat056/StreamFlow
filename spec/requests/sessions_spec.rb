require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "GET /auth/google_oauth2/callback (omniauth)" do
    it "creates a session for a new OAuth user and redirects to root" do
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "brand-new-uid",
        info: { email: "brandnew@example.com", name: "Brand New" }
      )

      expect { get auth_google_oauth2_callback_path }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      user = User.find_by(uid: "brand-new-uid")
      expect(session[:user_id]).to eq(user.id)
    end

    it "reuses an existing user's session on repeat login" do
      existing = create(:user, provider: "google_oauth2", uid: "repeat-uid")
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "repeat-uid",
        info: { email: existing.email, name: existing.username }
      )

      expect { get auth_google_oauth2_callback_path }.not_to change(User, :count)

      expect(session[:user_id]).to eq(existing.id)
    end
  end

  describe "DELETE /logout" do
    it "clears session[:user_id] and redirects to root" do
      sign_in_as create(:user)

      delete logout_path

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end
end
