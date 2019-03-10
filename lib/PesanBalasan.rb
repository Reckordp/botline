module PesanBalasan
  class << self
    DAFTAR_BALASAN = {
      :halo             =>      ["Iya?", "Apa?", "Hai"],
      :nanya            =>      ["Punya", "Ada", "Iya"],
      :nama             =>      ["nama saya Zakira", "Zakira", "Panggil aja Zakira"],
      :bingung          =>      ["Gak ada enviromentnya..."],
      :umur             =>      ["Lahirku 10 Maret 2019"],
      :ok               =>      "OK"
    }

    def buat_balasan(pesan)
      case pesan.message['text']
      when /^[Hh]{1,1}[Aa]?[Ll]{1,1}[Oo]+[\?]?$/
        ambil_balasan(:halo)
      when /^[Pp]*[u]?ny[a]?/
        kepunyaan(pesan)
      when /^[Nn][a]?mamu\?$/
        ambil_balasan(:nama)
      when /^[Uu]m[u]?rmu\?$/
        ambil_balasan(:umur)
      when /^[Kk][a]?p[a]?n l[a]?hir\?$/
        ambil_balasan(:umur)
      when /^([\w\s]+) j[a]?w[a]?bny[a]? ([\w\,\s]+)$/
        DAFTAR_BALASAN[$1] = $2.split(',')
        balasan(:ok)
      else
        if DAFTAR_BALASAN.key?(pesan.message['text'])
          ambil_balasan(pesan.message['text'])
        else
          ambil_balasan(:bingung)
        end
      end
    end

    def kepunyaan(pesan)
      case pesan.message['text']
      when /n[a]?ma[\?]?$/
        sprintf("%s, %s", ambil_balasan(:nanya), ambil_balasan(:nama))
      when /um[u]?r\?$/
        sprintf("%s, %s", ambil_balasan(:nanya), ambil_balasan(:umur))
      end
    end

    def ambil_balasan(jenis)
      jawaban = balasan(jenis)
      return jawaban[rand jawaban.size]
    end

    def balasan(jenis)
      DAFTAR_BALASAN[jenis]
    end
  end
end
