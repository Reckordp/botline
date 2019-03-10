module PesanBalasan
  class << self
    DAFTAR_BALASAN = {
      :halo             =>      ["Iya?", "Apa?", "Hai"],
      :nanya            =>      ["Punya", "Ada", "Iya"],
      :nama             =>      ["nama saya Zakira", "Zakira", "Panggil aja Zakira"],
      :bingung          =>      ["Gak ada enviromentnya..."],
      :umur             =>      ["Lahirku 10 Maret 2019"]
    }

    def buat_balasan(pesan)
      case pesan.message['text']
      when /^[Hh]{1,1}[Aa]?[Ll]{1,1}[Oo]+[\?]?$/
        ambil_balasan(:halo)
      when /^[Pp]*[u]?ny[a]?/
        kepunyaan(pesan)
      when /^[Nn][a]?mamu\?$/
        balasan(:nama)
      when /^[Uu]m[u]?rmu\?$/
        balasan(:umur)
      when /^[Kk][a]?p[a]?n l[a]?hir\?$/
        balasan(:umur)
      when /^([\w\s]+) j[a]?w[a]?bny[a]? ([\w\,\s]+)$/
        DAFTAR_BALASAN[$1] = $2.split(',')
      else
        if DAFTAR_BALASAN.key?(pesan.message['text'])
          DAFTAR_BALASAN[pesan.message['text']]
        else
          balasan(:bingung)
        end
      end
    end

    def kepunyaan(pesan)
      case pesan.message['text']
      when /n[a]?ma[\?]?$/
        sprintf("%s, %s", balasan(:nanya), balasan(:nama))
      when /um[u]?r\?$/
        sprintf("%s, %s", balasan(:nanya), balasan(:umur))
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
