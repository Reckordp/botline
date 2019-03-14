module PesanBalasan
  Pemilik = 'Uabc3a27c357d0ab0484c8c171ff0062f'

  DAFTAR_BALASAN_UMUM = {
    :halo             =>      ["Iya?", "Apa?", "Hai"],
    :nanya            =>      ["Punya", "Ada", "Iya"],
    :nama             =>      ["nama saya Zakira", "Zakira", "Panggil aja Zakira"],
    :bingung          =>      ["Gak ada enviromentnya..."],
    :umur             =>      ["Lahirku 10 Maret 2019"],
    :ok               =>      "OK"
  }

  Dialog = "Dialog"
  Grup = "Grup"
  Tugas = "Daftar Tugas"

  class << self
    def persiapan
      bentuk_dialog = Ingatan::BentukPartikelRancangan.new
      bentuk_dialog.tambah_jenis(:user_id, :string)
      bentuk_dialog.tambah_jenis(:pertanyaan, :string)
      bentuk_dialog.tambah_jenis(:jawaban, :text)
      Ingatan.buat_rancangan(Dialog, bentuk_dialog)

      bentuk_grup = Ingatan::BentukPartikelRancangan.new
      bentuk_grup.tambah_jenis(:grup_id, :string)
      Ingatan.buat_rancangan(Grup, bentuk_grup)

      bentuk_tugas = Ingatan::BentukPartikelRancangan.new
      bentuk_tugas.tambah_jenis(:kodepos, :string)
      bentuk_tugas.tambah_jenis(:tugas, :string)
      Ingatan.buat_rancangan(Tugas, bentuk_tugas)
    end

    def balas(event_pesan)
      pesan = urai_pesan(event_pesan.pesan.tulisan)
      pesan.map! { |pesan| pencarian_balasan(event_pesan, pesan) }
      return bentuk_balasan(pesan)
    end

    def urai_pesan(gumpalan_pesan)
      return gumpalan_pesan.split(/\./)
    end

    def bentuk_balasan(balasan)
      return balasan.join("\n")
    end

    def pencarian_balasan(event_pesan, pesan)
      khusus = balasan_khusus(event_pesan, pesan)
      return khusus if khusus
      umum = balasan_umum(event_pesan, pesan)
      return umum if umum
      return "Gak ada enviromentnya..."
    end

    def balasan_umum(event_pesan, pesan)
      balas = []
      balas << perintah(event_pesan.kodepos, pesan)
      balas << sapaan(event_pesan.pengirim, pesan)
      balas << kepunyaan(pesan)
      balas << pujian(pesan)
      balas << curhat(pesan)
      balas.compact!
      return balas.empty? ? nil : balas.first
    end

    def perintah(kodepos, pesan)
      case pesan
      when /TK\: DT/, /[Uu]pda?te?/, /[Pp]e?rba?ru?i?/, /[Bb]e?ri?ta?/, /[Ww]e?bsi?t?e?/, /[Ww]eb/
        tambah_tugas(kodepos, :website)
        "Aku tanya dulu..."
      when /TE\: ED/, /(.+) jawaba?n?nya (.+)/
        tambah_enviroment(pengirim, $1, $2)
        "Enviroment ditambahkan"
      when /TK\: RM/, /[Rr]incian emot/, /[Ss]elidiki emot/, /[Nn]omor emot/
        tambah_tugas(kodepos, :emot)
        "Merekam..."
      end
    end

    def sapaan(pengirim, pesan)
      nama = pengirim.rincian.nama[0, 4]
      case pesan
      when /[Hh]alo ?(\w*)/
        format("%s %s", "Hai", (nama?($1) ? nama : ""))
      when /[Hh]ai ?(\w*)/
        format("%s %s", "Halo", (nama?($1) ? nama : ""))
      when nama?(pesan)
        nama
      end
    end

    def kepunyaan(pesan)
    end

    def pujian(pesan)
    end

    def curhat(pesan)
    end

    def balasan_khusus(pengirim, pesan)
      jawaban = []
      Ingatan.semua_bagian(Dialog).each do |bagian|
        next unless bagian.user_id == pengirim.nomorinduk
        next unless bagian.pertanyaan == pesan
        jawaban = bagian.jawaban.split(",")
      end
      return nil if jawaban.empty?
      return jawaban[rand(jawaban.size)]
    end

    def nama?(tulisan)
      return true if tulisan.match(/[Zz]akira/)
      return true if tulisan.match(/[Kk]ira/)
      return true if tulisan.match(/[Zz]aki/)
      return false
    end

    def tambah_tugas(kodepos, nama_tugas)
      selesai = ambil_bagian_kosong(Tugas) { |bagian| bagian.tugas.empty? }
      selesai.kodepos = kodepos
      selesai.tugas = nama_tugas.to_s
      selesai.ubah_data
      return true
    end

    def tambah_enviroment(pengirim, tanya, gumpalan_jawab)
      gumpalan_jawab.gsub!(/at[wau]{1,2}/) { "," }
      gumpalan_jawab.gsub!(/\//) { "," }
      gumpalan_jawab.gsub!(/\, /) { "," }

      bag = ambil_bagian_kosong(Dialog) do |bagian|
        bagian.user_id.empty? || bagian.pertanyaan == tanya
      end
      bag.user_id = pengirim.nomorinduk
      bag.pertanyaan = tanya
      bag.jawaban = gumpalan_jawab
      bag.ubah_data
      return true
    end

    def pesan_pembuka
      return "Salam Kenal"
    end

    def undangan_grup
    end

    def sambut
    end

    def ambil_bagian_kosong(nama_rancangan)
      selesai = false
      Ingatan.semua_bagian(nama_rancangan).each do |bagian|
        next unless yield(bagian)
        selesai = bagian
        break
      end
      return selesai if selesai
      selesai = Ingatan.baru(nama_rancangan) unless selesai
      return selesai
    end
  end
  persiapan
end
