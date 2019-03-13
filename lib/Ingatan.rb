class Ingatan
  class IngatanError < StandardError; end
  class IngatanBukanRancangan < IngatanError; end
  class IngatanBagianTidakAda < IngatanError; end
  class IngatanPartikelSudahAda < IngatanError; end
  class IngatanTidakDisetujui < IngatanError; end
  class IngatanDataTidakSiap < IngatanError; end
  class IngatanRancanganTidakDitemukan < IngatanError; end
  class IngatanRancanganSudahAda < IngatanError; end
  class IngatanPerlindunganBeku < IngatanError; end

  TEMPAT = "db/neuron"

  class BentukPartikelRancangan
    DAFTAR_JENIS_DISETUJUI = {
      :string         =>  256,
      :text           =>  65536,
      :angka          =>  32,
      :waktu          =>  8
    }

    attr_reader :bentuk
    def initialize
      @bentuk = {}
    end

    def nama_dipastikan
      [:rancangan_id, :id, :ukuran]
    end

    def tambah_jenis(nama_lain_jenis, jenis)
      nama_lain_jenis = nama_lain_jenis.to_sym
      if @bentuk.key?(nama_lain_jenis) || nama_dipastikan.include?(nama_lain_jenis)
        raise IngatanPartikelSudahAda, "Beri nama partikel dengan nama lain"
      end
      unless DAFTAR_JENIS_DISETUJUI.key?(jenis)
        raise IngatanTidakDisetujui, "Jenis partikel harus disetujui.\nLihat Daftar!"
      end
      @bentuk[nama_lain_jenis] = jenis
    end

    def ke_bentuk_rancangan
      @bentuk.map { |k, v| sprintf("%s:%s", k, v) } .join(";")
    end

    def urai(gumpalan)
      gumpalan.split(/;/).each do |bagian|
        bagian.match(/(.+)\:(.+)/)
        tambah_jenis($1.to_sym, $2.to_sym)
      end
      return @bentuk
    end

    def ukuran
      32 + @bentuk.values.inject(0) { |b, val| b += DAFTAR_JENIS_DISETUJUI[val] }
    end
  end

  class Rancangan
    attr_accessor :id, :bentuk
  end

  def self.baru(rancangan)
    raise ArgumentError, "Butuh String" unless rancangan.is_a?(String)
    rancangan_app = cari_rancangan_dengan_nama(rancangan)
    ing = new(rancangan_app.id, id_bagian_kosong(rancangan), gunakan_file { |f| f.size }, rancangan_app.bentuk)
    yield(ing) if block_given?
    ing.ubah_data
    return ing
  end

  def self.semua_bagian(rancangan)
    raise ArgumentError, "Butuh String" unless rancangan.is_a?(String)
    rancangan = cari_rancangan_dengan_nama(rancangan)
    bagian = []
    gunakan_file do |f|
      ps = 0
      loop do
        f.pos = ps
        if f.pos >= f.size
          break
        elsif f.read(1) == 'Q'
          batas = 4
          f.pos = ps
          until (bacaan = f.read(batas)).match(/^Q(\d+)\|/)
            f.pos = ps
            batas *= 2
          end
          f.pos = ps
          bacaan = f.read($1.to_i)
          dfukr = bacaan[1, bacaan.size - 2].split("|").map(&:to_i)
          id_rancangan = f.read(dfukr[1])
          next ps += dfukr.inject(0) { |h, i| h += i } unless id_rancangan == rancangan.id
          f.pos += dfukr[2]
          id_bagian = f.read(dfukr[3]) # ukuran id bagian
          bag = allocate
          bag.urai_beku(bacaan, ps, rancangan.bentuk)
          bagian << bag
          ps += dfukr.inject(0) { |h, i| h += i }
        else
          f.pos = ps
          kepala = f.read(32)
          ukuran = kepala[16, 16].sub(/^0+/) { "" } .to_i
          id_rancangan = kepala[0, 8].sub(/^0+/) { "" } .to_i
          next ps += ukuran unless id_rancangan == rancangan.id
          id_bagian = kepala[8, 8].sub(/^0+/) { "" } .to_i
          bag = new(id_rancangan, id_bagian, ps, rancangan.bentuk)
          f.pos = ps
          bag.urai(f.read(ukuran))
          bagian << bag
          ps += ukuran
        end
      end
    end
    return bagian
  end

  def self.cari_id_bagian(rancangan, id)
    raise ArgumentError, "Butuh String" unless rancangan.is_a?(String)
    raise ArgumentError, "Butuh Integer" unless id.is_a?(Integer)
    rancangan = cari_rancangan_dengan_nama(rancangan)
    bagian = nil
    gunakan_file do |f|
      ps = 0
      loop do
        f.pos = ps
        if f.pos >= f.size
          break
        elsif f.read(1) == 'Q'
          batas = 4
          f.pos = ps
          until (bacaan = f.read(batas)).match(/^Q(\d+)\|/)
            f.pos = ps
            batas *= 2
          end
          f.pos = ps
          bacaan = f.read($1.to_i)
          dfukr = bacaan[1, bacaan.size - 2].split("|").map(&:to_i)
          id_rancangan = f.read(dfukr[1]).to_i
          next ps += dfukr.inject(0) { |h, i| h += i } unless id_rancangan == rancangan.id
          f.pos += dfukr[2]
          next ps += dfukr.inject(0) { |h, i| h += i } unless (id_bagian = f.read(dfukr[3]).to_i) == id
          bagian = allocate
          bagian.urai_beku(bacaan, ps, rancangan.bentuk)
          break
        else
          f.pos = ps
          kepala = f.read(32)
          ukuran = kepala[16, 16].sub(/^0+/) { "" } .to_i
          id_rancangan = kepala[0, 8].sub(/^0+/) { "" } .to_i
          next ps += ukuran unless id_rancangan == rancangan.id
          next ps += ukuran unless (id_bagian = kepala[8, 8].sub(/^0+/) { "" } .to_i) == id
          bagian = new(id_rancangan, id_bagian, ps, rancangan.bentuk)
          f.pos = ps
          bagian.urai(f.read(ukuran))
          break
        end
      end
    end
    return bagian
  end

  def self.cari_rancangan_dengan_nama(rancangan, aman = false)
    ranc = nil
    kumpulan_pos = 144
    gunakan_file do |f|
      f.pos = kumpulan_pos + 32
      daftar = f.read(65536).sub(/^\s+/) { "" }
      batas = 4
      bacaan = ""
      loop do
        until daftar.match(/^Daftar\=$/)
          ps = daftar.slice!(/;?\d+$/)
          ps.slice!(0, 1)
          f.pos = ps.to_i# + 8
          until (bacaan = f.read(batas)).match(/^Q(\d+)\|/)
            f.pos = ps.to_i
            batas *= 2
          end
          f.pos = ps.to_i
          bacaan = f.read($1.to_i)
          bacaan.slice!(0, 1)
          bacaan.slice!(-1, 1)
          dfukr = bacaan.split("|").map(&:to_i)
          bacaan.clear
          f.pos += dfukr[1]
          id = f.read(dfukr[2]).to_i
          f.pos += dfukr[3]
          n_ranc = f.read(dfukr[4])
          next batas = 4 unless rancangan == n_ranc
          bentuk = BentukPartikelRancangan.new
          bentuk.urai(f.read(dfukr[5]))
          ranc = Rancangan.new
          ranc.id = id
          ranc.bentuk = bentuk
          break
        end
        break if ranc
        f.pos = kumpulan_pos + 65536 + 32
        kumpulan_pos = f.read(32).sub(/0+/) { "" } .to_i
        break if kumpulan_pos.zero?
      end
    end
    raise IngatanRancanganTidakDitemukan, "Nama tidak valid" if !ranc && !aman
    return ranc
  end

  def self.rancangan?(nama)
    cari_rancangan_dengan_nama(nama, true) ? true : false
  end

  def self.id_bagian_kosong(nama_rancangan)
    raise ArgumentError, "Butuh String" unless nama_rancangan.is_a?(String)
    rancangan = cari_rancangan_dengan_nama(nama_rancangan)
    semua_id = []
    gunakan_file do |f|
      ps = 0
      loop do
        f.pos = ps
        if f.pos >= f.size
          break
        elsif f.read(1) == 'Q'
          batas = 4
          f.pos = ps
          until (bacaan = f.read(batas)).match(/^Q(\d+)\|/)
            f.pos = ps
            batas *= 2
          end
          f.pos = ps
          bacaan = f.read($1.to_i)
          dfukr = bacaan[1, bacaan.size - 2].split("|").map(&:to_i)
          id_rancangan = f.read(dfukr[1]).to_i
          ps += dfukr.inject(0) { |h, i| h += i }
          next unless rancangan.id == id_rancangan
          semua_id << f.read(dfukr[2]).to_i
        else
          f.pos = ps
          kepala = f.read(32)
          ukuran = kepala[16, 16].sub(/^0+/) { "" } .to_i
          id_rancangan = kepala[0, 8].sub(/^0+/) { "" } .to_i
          ps += ukuran
          next unless id_rancangan == rancangan.id
          semua_id << kepala[8, 8].sub(/^0+/) { "" } .to_i
        end
      end
    end
    id = 1
    id += 1 while semua_id.include?(id)
    return id
  end

  def self.gunakan_file
    ulangi unless File.exist?(TEMPAT)
    f = File.open(TEMPAT, "r+")
    r = yield(f)
    f.close
    return r
  end

  def self.buat_rancangan_ingatan_asli
    gunakan_file do |f|
      tersedia = nil
      if f.size > 71
        f.pos = 0
        if f.read(71) == "Q16|1|1|1|19|33;110Pengelola Rancangannama_rancangan:string;bentuk:text"
          tersedia = true
        else
          raise IngatanDataTidakSiap, "Data telah disalahgunakan!"
        end
      elsif f.size > 0
        raise IngatanDataTidakSiap, "Data telah disalahgunakan!"
      else
        tersedia = false
      end

      unless tersedia
        fmt = "%s%d%d%d%s%s"
        id_ranc = 1
        id_bag = 1
        ukr = 0
        nm = "Pengelola Rancangan"
        bentuk = BentukPartikelRancangan.new
        bentuk.tambah_jenis(:nama_rancangan, :string)
        bentuk.tambah_jenis(:bentuk, :text)
        fu = ""
        fb = [id_ranc, id_bag, ukr, nm, bentuk.ke_bentuk_rancangan].map do |i|
          fu += sprintf("|%d", i.to_s.size)
          i.to_s
        end
        u = fu.size + 2
        f.pos = 0
        f.write("Q#{u + u.to_s.size}" + fu + ";" + fb.join)
      end

      f.pos = 71
      ukr = 65600
      if f.size > (f.pos + ukr) && f.read(32).match(/0{7}20{7}10{11}#{ukr}/)
        next
      end

      f.pos = 71
      fmt = "%s%d%d%d%s%s"
      id_ranc = 1
      id_bag = 2
      nm = "Kumpulan Pengelola"
      bentuk = BentukPartikelRancangan.new
      bentuk.tambah_jenis(:daftar_rancangan, :text)
      bentuk.tambah_jenis(:lanjutan, :angka)
      fu = ""
      fb = [id_ranc, id_bag, 0, nm, bentuk.ke_bentuk_rancangan].map do |i|
        fu += sprintf("|%d", i.to_s.size)
        i.to_s
      end
      u = fu.size + 2
      f.write("Q#{u + u.to_s.size}" + fu + ";" + fb.join)

      fmt = "%08d%08d%016d%065536s%032d"
      id_ranc = 2
      id_bag = 1
      daftar = "Daftar=0;71"
      lanjutan = 0
      f.pos = 144
      f.write(sprintf(fmt, id_ranc, id_bag, ukr, daftar, lanjutan))
    end
  end

  def self.buat_rancangan(nama_rancangan, bentuk_rancangan)
    unless bentuk_rancangan.is_a?(BentukPartikelRancangan)
      raise ArgumentError, "Butuh BentukPartikelRancangan untuk membuat rancangan"
    end
    if rancangan?(nama_rancangan)
      raise IngatanRancanganSudahAda, "Coba nama yang lain"
    end
    b = baru("Pengelola Rancangan") do |ranc|
      ranc.nama_rancangan = nama_rancangan
      ranc.bentuk = bentuk_rancangan.ke_bentuk_rancangan
      ranc.ke_beku
    end

    kump = semua_bagian("Kumpulan Pengelola")
    id = kump.map(&:id).max
    log_ranc = kump.find { |k| k.id == id }
    log_ranc.daftar_rancangan += ";#{b.instance_variable_get(:@pos)}"
    log_ranc.ubah_data
    return true
  end

  def self.ulangi(ulangi_file = true)
    File.open(TEMPAT, 'w').close if ulangi_file
    buat_rancangan_ingatan_asli
  end

  private_class_method :new, :buat_rancangan_ingatan_asli
  private_class_method :gunakan_file, :id_bagian_kosong
  ulangi(false)

  attr_reader :rancangan_id, :id
  def initialize(rancangan_id, id, posisi, bentuk)
    @rancangan_id = rancangan_id
    @id = id
    @pos = posisi
    @bentuk = bentuk
    @isi = []
    @ukuran = bentuk.ukuran
    @beku = false
    ulangi
  end

  def ke_beku
    @beku = true
  end

  def ulangi
    @isi = anggota_jenis.map do |jenis|
       pengganti_bentuk(jenis) == "s" ? "" : 0
    end
    return self
  end

  def ukuran_bentuk(bentuk)
    return 16 if bentuk == :ukuran
    ukr = BentukPartikelRancangan::DAFTAR_JENIS_DISETUJUI[bentuk]
    ukr ? ukr : 8
  end

  def pengganti_bentuk(bentuk)
    case bentuk
    when :string, :text
      "s"
    when :angka, :waktu, :id, :rancangan_id, :ukuran
      "d"
    else
      ""
    end
  end

  def anggota_bentuk
    @bentuk.bentuk.keys
  end

  def anggota_jenis
    @bentuk.bentuk.values
  end

  def ambil_partikel(partikel)
    @isi[anggota_bentuk.index(partikel)]
  end

  def ubah_partikel(partikel, isi)
    raise IngatanPerlindunganBeku, "Sudah dibekukan" if @beku
    @isi[anggota_bentuk.index(partikel)] = isi
    return self
  end

  def method_missing(mtd, *args)
    if anggota_bentuk.include?(mtd)
      ambil_partikel(mtd)
    elsif mtd.to_s.match(/^(.+)\=$/) && anggota_bentuk.include?($1.to_sym) && args.first
      ubah_partikel($1.to_sym, args.first)
    else
      super
    end
  end

  def persiapan_mengubah
    agt = [:rancangan_id, :id, :ukuran, *@bentuk.bentuk.values].map do |i|
      "%" + sprintf("0%d%s", ukuran_bentuk(i), pengganti_bentuk(i))
    end
    return agt.join
  end

  def ubah_data
    self.class.send(:gunakan_file) do |f|
      f.pos = @pos
      data = ""
      if @beku
        q = ""
        [@rancangan_id, @id, 0, *@isi].map do |nilai|
          q += sprintf("|%d", nilai.to_s.size)
          data += nilai.to_s
        end
        u = q.size + 2
        # ditambah Q dan ;
        data = "Q#{u + u.to_s.size}" + q + ";" + data
      else
        data = sprintf(persiapan_mengubah, @rancangan_id, @id, @ukuran, *@isi)
      end
      f.write data
    end
    true
  end

  def urai(gumpalan)
    gumpalan.slice!(0, 32)
    @bentuk.bentuk.each do |anggota_key, i|
      nomor = gumpalan[0] == "0"
      val = gumpalan.slice!(0, ukuran_bentuk(i)).sub(/^[0 ]+/) { "" }
      ubah_partikel(anggota_key, nomor ? val.to_i : val)
    end
    return self
  end

  def urai_beku(gumpalan, posisi, bentuk)
    @beku = true
    gumpalan =~ /Q(\d+)\|/
    daftar_ukuran = gumpalan.slice!(0, $1.to_i)
    daftar_ukuran.slice!(0, 1 + $1.size + 1)    #  Q(\d+)|
    daftar_ukuran.slice!(-1, 1)
    daftar_ukuran = daftar_ukuran.split("|")
    @bentuk = bentuk
    @isi = daftar_ukuran.map.with_index do |ukuran, i|
      if pengganti_bentuk(anggota_jenis[i]) == "s"
        gumpalan.slice!(0, ukuran.to_i)
      else
        gumpalan.slice!(0, ukuran.to_i).to_i
      end
    end
    @rancangan_id = @isi.shift.to_i
    @id = @isi.shift.to_i
    @ukuran = @isi.shift.to_i
    @pos = posisi
  end
end
