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

  TUGAS_PRIORITAS = %i[ website ]
  TUGAS_KELANJUTAN = %i[ emot ]

  def siapkan_alat_balas
    @penampungan = {}
    @diam = false
  end

  def kirim_pesan(kodepos, isi_terformat)
    @penampungan[kodepos] ||= []
    @penampungan[kodepos].push(*isi_terformat)
  end

  def kirim_balasan
    @penampungan.each { |kode, isi| @client&.reply_message(kode, isi) }
  end

  def kirim_pesan_dari_gumpalan(kodepos, daftar_gumpalan)
    hasil = []
    gumpalan_tulisan = daftar_gumpalan[0]
    gumpalan_tulisan.slice!(-1, 1)
    gumpalan_tulisan.split(/;/).each do |gumpalan|
      gumpalan.slice!(/^\[TULISAN /)
      gumpalan.slice!(/\]$/)
      hasil << buat_pesan_terstruktur(:text, gumpalan)
    end
    gumpalan_emot = daftar_gumpalan[1]
    gumpalan_emot.slice!(-1, 1)
    gumpalan_emot.split(/;/).each do |gumpalan|
      gumpalan.slice!(/^\[EMOT /)
      gumpalan.slice!(/\]$/)
      hasil << buat_pesan_terstruktur(:emot, gumpalan.split(/ /).map(&:to_i))
    end

    kirim_pesan(kodepos, hasil)
  end

  def dipanggil?(pesan)
    panggilan = false
    case pesan
    when PenguraiEventLine::Pengurai::Message::Text
      panggilan = true if pesan.tulisan =~ /^[Bb]ot\s\,/
      panggilan = true if panggilan || PesanBalasan.nama?(pesan.tulisan)
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
    when :emot
      struktur = {
        :type    =>   'sticker',
        :packageId => isi[0].to_s,
        :stickerId => isi[1].to_s
      }
    end
    return struktur
  end

  def pengelola_pesan(permintaan)
    return if !permintaan.pengirim.sendiri? && !dipanggil?(permintaan.pesan)
    case permintaan.pesan
    when PenguraiEventLine::Pengurai::Message::Text
      kirim_pesan_dari_gumpalan(permintaan.kodepos, PesanBalasan.balas(permintaan.pesan.tulisan, permintaan.pengirim))
    when PenguraiEventLine::Pengurai::Message::Image
    when PenguraiEventLine::Pengurai::Message::Video
    when PenguraiEventLine::Pengurai::Message::Audio
    when PenguraiEventLine::Pengurai::Message::Fileu
    when PenguraiEventLine::Pengurai::Message::Location
    when PenguraiEventLine::Pengurai::Message::Sticker
    end
  end

  def pengelola_ditambahkan(permintaan)
    kirim_pesan(permintaan.kodepos, buat_pesan_terstruktur(:text, PesanBalasan.pesan_pembuka))
  end

  def pengelola_diundang_grup(permintaan)
    kirim_pesan(permintaan.kodepos, buat_pesan_terstruktur(:text, PesanBalasan.undangan_grup))
  end

  def pengelola_sambutan(permintaan)
    kirim_pesan(permintaan.kodepos, buat_pesan_terstruktur(:text, PesanBalasan.sambut(permintaan.pendaftar)))
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
    kirim_balasan
    render plain: "OK"
  end

  def kerjakan_tugas_dari(kondisi, kodepos)
    Ingatan.semua_bagian(PesanBalasan::Tugas).each do |tugas|
      jenis_tugas = tugas.tugas.to_sym
      case kondisi
      when :prioritas
        kerjakan_tugas(jenis_tugas, tugas, kodepos) if TUGAS_PRIORITAS.include?(jenis_tugas)
      when :kelanjutan
        kerjakan_tugas(jenis_tugas, tugas, kodepos) if TUGAS_KELANJUTAN.include?(jenis_tugas)
      end
    end
  end

  def kerjakan_tugas(jenis_tugas, tugas, kodepos)
    case jenis_tugas
    when :website
      tugas_website(kodepos)
    when :emot
      a = @daftar_evtline.select { |i| i.is_a?(PenguraiEventLine::Pengurai::Message) } .map(&:pesan)
      a = a.find { |i| i.is_a?(PenguraiEventLine::Pengurai::Message::Sticker) }
      return kirim_pesan(kodepos, :text, "Gak jadi merekam") if a.empty?
      @diam = true
      tugas_rekam_emot(kodepos, a)
    end
    tugas.ulangi
    tugas.ubah_data
  end

  def tugas_website(kodepos)
    sistem = 'https:'
    website = 'inscreat.herokuapp.com'
    tempat = 'data/developer/baru'
    username = 'Reckordp'
    password = 'tidakada'
    port = 443
    uri = URI(format('%s//%s/%s/%s/%s', sistem, website, tempat, username, password))
    uri.port = port
    # Nanti
    # disini saya request get
    # disana cuma ambil bagian akhir file
    # tidak menampilkan 2 versi catatan!
    # stategi 1 : setiap versi di batasi oleh \n\n dan \n\n terakhir yang dikirim
    kirim_pesan(kodepos, buat_pesan_terstruktur(:text, Net::HTTP.get_response(uri).body))
  end

  def tugas_rekam_emot(kodepos, evt_sticker)
    psn = format("Paket: %s\nUrutan: %s", evt_sticker.paket, evt_sticker.urutan)
    kirim_pesan(kodepos, buat_pesan_terstruktur(:text, psn))
  end

  def olah_event_line
    @daftar_evtline = PenguraiEventLine.urai(request.body.read)
    @daftar_evtline.each do |permintaan|
      tanya_nama(permintaan)
      kerjakan_tugas_dari(:kelanjutan, permintaan.kodepos)
      break if @diam

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
      kerjakan_tugas_dari(:prioritas, permintaan.kodepos)
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
