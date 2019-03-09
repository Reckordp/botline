require 'line/bot'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  before_action :validate_signature

  def validate_signature
    return if action_name == "index"
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      render plain: "#{ActionController::BadRequest} 'Bad Request'"
    end
  end

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end
end
