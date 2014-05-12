class AuthController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def init
    raise(ArgumentError, "An HTTP referer is required to begin auth flow.") unless request.referer
    session[:auth_referer] = request.referer
    redirect_to "/auth/#{params[:provider]}"
  end

  def callback
    auth_data = request.env['omniauth.auth']
    @user_name = auth_data['info']['name']
    @api_read_key = SecureRandom.uuid
    $redis.mapped_hmset("#{SubscriberAuth::KEY_PREFIX}#{@api_read_key}", auth_data.slice('provider', 'uid', 'info'))

    # Redirect if we captured a referring URL. Otherwise render.
    if referer = session[:auth_referer]
      redirect_to "#{referer}?api_key=#{CGI.escape(@api_read_key)}&user_name=#{CGI.escape(@user_name)}"
    end
  end

  def failure
    @auth_message = params[:message]
  end

  def logout
    @api_key = params[:api_key]
    $redis.del("#{SubscriberAuth::KEY_PREFIX}#{@api_key}")
    if referer = request.referer
      redirect_to "#{referer}?logout=true"
    end
  end

end
