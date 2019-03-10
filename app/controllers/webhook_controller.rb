class WebhookController < ApplicationController
  def callback
    body = request.body.read
    events = client.parse_event_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::MessageType::Text
        message = {
          type: 'text',
          text: event.message['text']
        }
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        reponse = client.get_message_content(event.message['id'])
        tf = Tempfile.open('content')
        tf.write(reponse.body)
      end
    end

    "OK"
  end

  def callback_text
    render plain: "Gunakan POST!"
  end
end
