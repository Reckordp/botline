class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session
  # before_action :validate_signature

  def validate_signature
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    if action_name != "index" && !client.validate_signature(body, signature)
      render plain: "Bad request", status: 400
    end
  end

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end
end
