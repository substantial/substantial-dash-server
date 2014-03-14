require 'spec_helper'

describe AuthController do

  describe '#init' do

    describe 'with an HTTP referer' do
      before do
        request.env['HTTP_REFERER'] = 'http://bar.foo/'
        get :init, provider: 'google_apps'
      end

      it "captures the original referer" do
        expect(session[:auth_referer]).to eq('http://bar.foo/')
      end

      it "redirects to auth flow" do
        expect(response).to redirect_to("/auth/google_apps")
      end
    end

    describe 'without an HTTP referer' do
      it "raises an ArgumentError" do
        expect { get :init, provider: 'google_apps' }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#callback' do
    before do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_apps]
    end

    describe 'with an HTTP referer' do
      before do
        session[:auth_referer] = 'http://bar.foo/'
      end

      it "stores the new API key with auth info" do
        $redis.should_receive(:mapped_hmset) do |key, value|
          expect(key).to match(/^api-read-key:.+/)
          expect(value).to be_kind_of(Hash)
          expect(value).to have_key('provider')
          expect(value).to have_key('uid')
          expect(value).to have_key('info')
          nil
        end
        get :callback, provider: 'google_apps'
      end

      it "redirects back to the auth referer" do
        get :callback, provider: 'google_apps'
        expect(response.location).to match('http://bar.foo/')
      end

      it "redirects with the API key" do
        get :callback, provider: 'google_apps'
        expect(response.location).to match(/api_key=.+%3D%3D/)
      end

      it "redirects with the user's name" do
        get :callback, provider: 'google_apps'
        expect(response.location).to match(/user_name=\w+/)
      end
    end

    describe 'without an HTTP referer' do
      it "assigns the API key" do
        get :callback, provider: 'google_apps'
        expect(assigns(:api_read_key)).to be_present
      end

      it "assigns the user name" do
        get :callback, provider: 'google_apps'
        expect(assigns(:user_name)).to be_present
      end

      it "renders the callback template" do
        get :callback, provider: 'google_apps'
        expect(response).to render_template("callback")
      end
    end
  end

  describe '#failure' do
    before do
      get :failure, message: 'Account is locked out.'
    end

    it "assigns @auth_message" do
      expect(assigns(:auth_message)).to eq('Account is locked out.')
    end

    it "renders the failure template" do
      get :failure, provider: 'google_apps'
      expect(response).to render_template("failure")
    end
  end

end
