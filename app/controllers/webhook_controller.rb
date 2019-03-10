class WebhookController < ApplicationController
  def menerima_pesan(pesan)
    case pesan.type
    when Line::Bot::Event::MessageType::Text
      balas_pesan(pesan, PesanBalasan.buat_balasan(pesan))
    when Line::Bot::Event::MessageType::Sticker
      menerima_stiker(pesan)
    end
  end

  def menerima_stiker(pesan)
    msgapi = pesan.message['packageId'].to_i <= 4
    messages = [{
      type: 'text',
      text: "[STICKER]\npackageId: #{pesan.message['packageId']}\nstickerId: #{pesan.message['stickerId']}"
      }]

    if msgapi
      messages.push(
        type: 'sticker',
        packageId: pesan.message['packageId'],
        stickerId: pesan.message['stickerId']
      )
    end
    balas_konten(pesan, messages)
  end

  def balas_pesan(pesan, tulisan)
    client.reply_message(pesan['replyToken'], { type: 'text', text: tulisan })
  end

  def balas_konten(pesan, konten)
    client.reply_message(pesan['replyToken'], konten)
  end

  def callback
    body = request.body.read
    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        menerima_pesan(event)
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

    render plain: "OK"
  end

  def callback_text
    render plain: "Gunakan POST!"
  end
end
