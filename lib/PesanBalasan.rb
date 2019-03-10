class PesanBalasan
  DAFTAR_BALASAN = {
    :halo             =>      ["Iya?", "Apa?", "Hai"],
    :jwb_dng          =>      ["OK"]
  }

  def initialize
    @sblm = nil
  end

  def p(*args)
    File.open("log/pesanbalasan.log", "r+") do |f|
      f.pos = f.size
      f.write super + "\n"
    end
  end

  def buat_balasan(pesan)
    case pesan.message['text']
    when /[Hh]{1,1}[Aa]?[Ll]{1,1}[Oo]+/
      balasan(:halo)
    when /[Jj]awab (\w+) dong/
      DAFTAR_BALASAN[@sblm] = [$1]
      balasan(:jwb_dng)
    end
  end

  def balasan(jenis)
    @sblm = jenis
    jawaban = DAFTAR_BALASAN[jenis]
    return jawaban[rand jawaban.size]
  end
end
