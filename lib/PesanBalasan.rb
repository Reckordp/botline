module PesanBalasan
  Pemilik = 'Uabc3a27c357d0ab0484c8c171ff0062f'
  INFORMASI_SAYA = "Infomasi Saya\n BOT 1.0 botline-inscreat.herokuapp.com\n" \
    " Mesosialisasikan kemajuan website\n Dalam tahap pengembangan\n" \
    "\nPersyaratan\n Akun ini bersifat rahasia\n\n Dibuat 8 Maret 2019" \
    " FreePlan\n\nSiap Bekerja."

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
      bentuk_tugas.tambah_jenis(:tugas, :string)
      bentuk_tugas.tambah_jenis(:rincian, :string)
      Ingatan.buat_rancangan(Tugas, bentuk_tugas)
    end

    def balas(tulisan, pengirim)
      pesan = urai_pesan(tulisan)
      pesan.map! { |psn| pencarian_balasan(psn, pengirim) }
      return bentuk_balasan(pesan)
    end

    def urai_pesan(gumpalan_pesan)
      return gumpalan_pesan.split(/\./)
    end

    def bentuk_balasan(balasan)
      hasil = {:tulisan => "", :emot => ""}
      balasan.each do |gumpalan_gj|
        gumpalan_gj.each do |gumpalan|
          next unless gumpalan.match(/\[(\w+)\s[\w\s\d\:\/\.]+\]/)
          hasil[$1.downcase.to_sym] << gumpalan
          hasil[$1.downcase.to_sym] << ";"
        end
      end
      return hasil.values
    end

    def pencarian_balasan(pesan, pengirim)
      khusus = balasan_khusus(pesan, pengirim)
      return khusus if khusus
      umum = balasan_umum(pesan, pengirim)
      return umum if umum
      return buat_format_jenis(:tulisan, "Gak ada enviromentnya...")
    end

    def balasan_umum(pesan, pengirim)
      balas = []
      balas << perintah(pesan, pengirim)
      balas << sapaan(pesan, pengirim.rincian.nama)
      balas << kepunyaan(pesan)
      balas << pujian(pesan)
      balas << curhat(pesan)
      balas.compact!
      return balas.empty? ? nil : balas.first
    end

    def perintah(pesan, pengirim)
      case pesan
      when /TK\: DT/, /[Uu]pda?te?/, /[Pp]e?rba?ru?i?/, /[Bb]e?ri?ta?/, /[Ww]e?bsi?t?e?/, /[Ww]eb/
        tambah_tugas(:website)
        buat_format_jenis(:tulisan, "alamat: https://inscreat.herokuapp.com\n mengambil file...")
      when /TE\: E (.+) D (.+)/, /(.+) jawaba?n?nya (.+)/
        tambah_enviroment(pengirim.nomorinduk, $1, $2)
        buat_format_jenis(:tulisan, "Enviroment ditambahkan")
      when /TK\: RM/, /[Rr]incian emot/, /[Ss]elidiki emot/, /[Nn]omor emot/
        tambah_tugas(:emot)
        buat_format_jenis(:tulisan, "Merekam...")
      when /TK\: DM (\d+)/, /[Dd]iam (\d+)/
        tambah_tugas(:diam, $1)
        buat_format_jenis(:emot, {paket: 1, nomor: 3})
      end
    end

    def sapaan(pesan, nama_pengirim)
      case pesan
      when /[Hh]alo ?(\w*)/
        buat_format_jenis(:tulisan, format("%s %s", "Hai", (nama?($1) ? nama_pengirim[0, 4] : "")))
      when /[Hh]ai ?(\w*)/
        buat_format_jenis(:tulisan, format("%s %s", "Halo", (nama?($1) ? nama_pengirim[0, 4] : "")))
      else
        buat_format_jenis(:tulisan, nama_pengirim) if nama?(pesan)
      end
    end

    def kepunyaan(pesan)
      case pesan
      when /[Kk]enalan yuk/, /[Aa]ku mau kenalan/, /[Ss]iapa kamu [itu]{3}/
        buat_format_jenis(:tulisan, INFORMASI_SAYA)
      end
    end

    def pujian(pesan)
      case pesan
      when /[Bb]erguna juga/
        buat_format_jenis(:tulisan, "Itukan karena kamu percaya sama aku")
      end
    end

    def curhat(pesan)
    end

    def balasan_khusus(pesan, pengirim)
      jawaban = []
      Ingatan.semua_bagian(Dialog).each do |bagian|
        next unless bagian.user_id == pengirim.nomorinduk
        next unless bagian.pertanyaan == pesan
        jawaban = bagian.jawaban.split(",")
      end
      return nil if jawaban.empty?
      return buat_format_jenis(:tulisan, jawaban[rand(jawaban.size)])
    end

    def nama?(tulisan)
      return true if tulisan.match(/[Zz]akira/)
      return true if tulisan.match(/[Kk]ira/)
      return true if tulisan.match(/[Zz]aki/)
      return false
    end

    def tambah_tugas(nama_tugas, rincian = nil)
      selesai = ambil_bagian_kosong(Tugas) { |bagian| bagian.tugas.empty? }
      selesai.tugas = nama_tugas.to_s
      selesai.rincian = rincian.to_s
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
      "Salam kenal"
    end

    def undangan_grup
      buat_format_jenis(:tulisan, "Salam kenal semuanya") + \
      buat_format_jenis(:emot, {paket: 11537, nomor: 52002739})
    end

    def sambut(anggota)
      dasar_sambutan = "Halo %s, salam kenal ya"
      anggota.map! { |i| format(dasar_sambutan, i.nama) } .join("\n")
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

    def buat_format_jenis(jenis, isi)
      hsl = []
      case jenis
      when :tulisan
        hsl << format("[%s %s]", "TULISAN", isi)
      when :emot
        hsl << format("[%s %d %d]", "EMOT", isi[:paket], isi[:nomor])
      end
      return hsl
    end
  end

  persiapan
end
