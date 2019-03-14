class WebhookController < ApplicationController
  # def menerima_pesan(pesan)
  #   case pesan.type
  #   when Line::Bot::Event::MessageType::Text
  #     balas_pesan(pesan, PesanBalasan.buat_balasan(pesan))
  #   when Line::Bot::Event::MessageType::Sticker
  #     menerima_stiker(pesan)
  #   end
  # end

  # def menerima_stiker(pesan)
  #   msgapi = pesan.message['packageId'].to_i <= 4
  #   messages = [{
  #     type: 'text',
  #     text: "[STICKER]\npackageId: #{pesan.message['packageId']}\nstickerId: #{pesan.message['stickerId']}"
  #     }]
  #
  #   if msgapi
  #     messages.push(
  #       type: 'sticker',
  #       packageId: pesan.message['packageId'],
  #       stickerId: pesan.message['stickerId']
  #     )
  #   end
  #   balas_konten(pesan, messages)
  # end
  #
  # def balas_pesan(pesan, tulisan)
  #   client.reply_message(pesan['replyToken'], { type: 'text', text: tulisan })
  # end
  #
  # def balas_konten(pesan, konten)
  #   client.push_message(pesan['replyToken'], konten)
  # end

  def siapkan_alat_balas
    @penampungan = []
  end

  def kirim_pesan(kodepos, jenis, isi)
    @penampungan[0] = kodepos
    @penampungan.push(buat_pesan_terstruktur(jenis, isi))
  end

  def kirim_balasan
    @client.reply_message(@penampungan.shift, @penampungan)
  end

  def dipanggil?(pesan)
    panggilan = false
    case pesan
    when PenguraiEventLine::Pengurai::Message::Text
      panggilan = true if pesan.tulisan =~ /\sBot\s/
      panggilan = true if PesanBalasan.nama?(nama) || panggilan
    end
    return panggilan
  end

  def buat_pesan_terstruktur(jenis, isi)
    struktur = nil
    case jenis
    when :text
      struktur = {
        :type     =>  'text',
        :text     =>  isi,
      }
    end
    return struktur
  end

  def pengelola_pesan(permintaan)
    return if !permintaan.pengirim.sendiri? && !dipanggil?(permintaan.pesan)
    case permintaan.pesan
    when PenguraiEventLine::Pengurai::Message::Text
      kirim_pesan(permintaan.kodepos, buat_pesan_terstruktur(:text, PesanBalasan.balas(permintaan)))
    when PenguraiEventLine::Pengurai::Message::Image
    when PenguraiEventLine::Pengurai::Message::Video
    when PenguraiEventLine::Pengurai::Message::Audio
    when PenguraiEventLine::Pengurai::Message::Fileu
    when PenguraiEventLine::Pengurai::Message::Location
    when PenguraiEventLine::Pengurai::Message::Sticker
    end
  end

  def pengelola_ditambahkan(permintaan)
    kirim_pesan(permintaan.kodepos, kirim_pesan(:text, PesanBalasan.pesan_pembuka))
  end

  def pengelola_diundang_grup(permintaan)
    kirim_pesan(permintaan.kodepos, kirim_pesan(:text, PesanBalasan.undangan_grup))
  end

  def pengelola_sambutan(permintaan)
    kirim_pesan(permintaan.kodepos, kirim_pesan(:text, PesanBalasan.sambut))
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
    siapkan_alat_balas
    olah_event_line
    kerjakan_tugas_prioritas
    kirim_balasan
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
    sistem = 'https:'
    website = 'inscreat.herokuapp.com'
    tempat = 'data/developer/baru'
    username = 'Reckordp'
    password = 'tidakada'
    port = 443
    uri = URI(format('%s//%s/%s/%s/%s', sistem, website, tempat, username, password))
    uri.port = port
    kirim_pesan(tugas.kodepos, :text, Net::HTTP.get_response(uri).body)
    tugas.ulangi
    tugas.ubah_data
  end

  def olah_event_line
    PenguraiEventLine.urai(request.body.read).each do |permintaan|
      tanya_nama(permintaan)

      case permintaan
      when PenguraiEventLine::Pengurai::Message
        pengelola_pesan(permintaan)
      when PenguraiEventLine::Pengurai::Follow
        pengelola_ditambahkan(permintaan)
      when PenguraiEventLine::Pengurai::Join, PenguraiEventLine::Pengurai::Leave
        pengelola_diundang_grup(permintaan)
      when PenguraiEventLine::Pengurai::MemberJoined#, PenguraiEventLine::Pengurai::MemberLeft
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
    gumpalan = JSON.parse(client.get_profile(permintaan.pengirim.nomorinduk).body)
    permintaan.pengirim.rincian = PenguraiEventLine::Pengurai::Pengirim::Rincian.urai(gumpalan)
  end

  def callback_text
    render plain: "Gunakan POST!"
  end
end
