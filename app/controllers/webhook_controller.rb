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
    client.push_message(pesan['replyToken'], konten)
  end

  def pengelola_pesan(permintaan)
    pengirim = permintaan.pengirim
    case permintaan.pesan
    when PenguraiEventLine::Pengurai::Message::Text
      balasan = {
        :type     =>  'text',
        :text     =>  PesanBalasan.balas(pengirim, permintaan.pesan.tulisan)
      }
      client.reply_message(permintaan.kodepos, balasan)
    when PenguraiEventLine::Pengurai::Message::Image
    when PenguraiEventLine::Pengurai::Message::Video
    when PenguraiEventLine::Pengurai::Message::Audio
    when PenguraiEventLine::Pengurai::Message::Fileu
    when PenguraiEventLine::Pengurai::Message::Location
    when PenguraiEventLine::Pengurai::Message::Sticker
    end
  end

  def pengelola_pengikut(permintaan)
  end

  def pengelola_sapaan(permintaan)
  end

  def pengelola_sambutan(permintaan)
  end

  def pengelola_postback(permintaan)
  end

  def pengelola_beacon(permintaan)
  end

  def pengelola_akun_link(permintaan)
  end

  def pengelola_perangkat(permintaan)
  end

  def callback
    olah_event_line
    kerjakan_tugas_prioritas
    render plain: "OK"
  end

  def kerjakan_tugas_prioritas
    Ingatan.semua_bagian(PesanBalasan::Tugas).each do |tugas|
      case tugas.tugas.to_sym
      when :website
        tugas_website(tugas)
      end
    end
  end

  def tugas_website(tugas)
    uri = URI('http://inscreat.herokuapp.com/data/developer/baru/Reckordp/hmm')
    res = Net::HTTP.get_response(uri)
    balasan = {
      :type     =>  'text',
      :text     =>  res.body
    }
    client.push_message(tugas.user_id, balasan)
    tugas.ulangi
  end

  def olah_event_line
    PenguraiEventLine.urai(request.body.read).each do |permintaan|
      tanya_nama(permintaan)

      case permintaan
      when PenguraiEventLine::Pengurai::Message
        pengelola_pesan(permintaan)
      when PenguraiEventLine::Pengurai::Follow, PenguraiEventLine::Pengurai::Unfollow
        pengelola_pengikut(permintaan)
      when PenguraiEventLine::Pengurai::Join, PenguraiEventLine::Pengurai::Leave
        pengelola_sapaan(permintaan)
      when PenguraiEventLine::Pengurai::MemberJoined, PenguraiEventLine::Pengurai::MemberLeft
        pengelola_sambutan(permintaan)
      when PenguraiEventLine::Pengurai::Postback
        pengelola_postback(permintaan)
      when PenguraiEventLine::Pengurai::Beacon
        pengelola_beacon(permintaan)
      when PenguraiEventLine::Pengurai::AccountLink
        pengelola_akun_link(permintaan)
      when PenguraiEventLine::Pengurai::Thing
        pengelola_perangkat(permintaan)
      else
        return render plain: "Bad request", status: 400
      end
    end
  end

  def tanya_nama(permintaan)
    id = permintaan.pengirim.nomorinduk
    gumpalan = JSON.parse(client.get_profile(id).body)
    permintaan.pengirim.rincian = PenguraiEventLine::Pengurai::Pengirim::Rincian.urai(gumpalan)
  end

  def callback_text
    render plain: "Gunakan POST!"
  end
end
