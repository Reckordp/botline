module PesanBalasan
  class << self
    DAFTAR_BALASAN = {
      :halo             =>      ["Iya?", "Apa?", "Hai"],
      :jwb_dng          =>      ["OK"],
      :sblm             =>      nil
    }

    def p(*args)
      File.open("log/pesanbalasan.log", "r+") do |f|
        f.pos = f.size
        f.write super + "\n"
      end
    end

    def buat_balasan(pesan)
      case pesan.message['text']
      when /[Hh]{1,1}[Aa]?[Ll]{1,1}[Oo]+/
        ambil_balasan(:halo)
      when /[Jj]awab (\w+) dong/
        DAFTAR_BALASAN[balasan(:sblm)] = [$1] if balasan(:sblm)
        ambil_balasan(:jwb_dng)
      end
    end

    def ambil_balasan(jenis)
      DAFTAR_BALASAN[:sblm] = jenis
      jawaban = balasan(:sblm)
      return jawaban[rand jawaban.size]
    end

    def balasan(jenis)
      DAFTAR_BALASAN[jenis]
    end
  end
end
