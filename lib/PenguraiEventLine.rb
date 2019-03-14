module PenguraiEventLine
  class DasarEvent
    def self.data(*args)
      attr_accessor *args
    end
    def self.urai(gumpalan)
      return new
    end
  end
  module Pengurai
    class Pengirim < ::PenguraiEventLine::DasarEvent
      class Rincian < ::PenguraiEventLine::DasarEvent
        data :nama
        data :alamatPP
        data :status

        def self.urai(gumpalan)
          saya.nama = "Tanpa Nama" if gumpalan['message'] == 'Not found'
          saya = super
          saya.nama = gumpalan['displayName']
          saya.alamatPP = gumpalan['pictureUrl']
          saya.status = gumpalan['statusMessage']
          return saya
        end
      end
      data :jenis
      data :nomortempat
      data :nomorinduk
      data :rincian

      def self.urai(gumpalan)
        saya = super
        saya.jenis = gumpalan['type']
        case gumpalan['type']
        when 'group'
          saya.nomortempat = gumpalan['groupId']
        when 'room'
          saya.nomortempat = gumpalan['roomId']
        end
        saya.nomorinduk = gumpalan['userId']
        saya.rincian = nil
        return saya
      end

      def sendiri?
        @jenis == 'user'
      end
    end
    class Dasar < ::PenguraiEventLine::DasarEvent
      data :jenis
      data :waktu
      data :pengirim
      def self.urai(gumpalan)
        saya = super
        saya.jenis = gumpalan['type']
        saya.waktu = gumpalan['timestamp']
        saya.pengirim = Pengirim.urai(gumpalan['source'])
        return saya
      end
    end
    class Message < Dasar
      class Dasar < PenguraiEventLine::DasarEvent
        data :nomor
        data :jenis

        def self.urai(gumpalan)
          saya = super
          saya.nomor = gumpalan['id']
          saya.jenis = gumpalan['type']
          return saya
        end
      end
      class ContentProvider < PenguraiEventLine::DasarEvent
        data :jenis
        data :alamatasli
        data :gambarpenunjuk

        def self.urai(gumpalan)
          saya = super
          saya.jenis = gumpalan['type']
          return saya if gumpalan['type'] == 'line'
          saya.alamatasli = gumpalan['originalContentUrl']
          saya.gambarpenunjuk = gumpalan['previewImageUrl']
          return saya
        end
      end
      class Text < Dasar
        data :tulisan

        def self.urai(gumpalan)
          saya = super
          saya.tulisan = gumpalan['text']
          return saya
        end
      end
      class Image < Dasar
        data :konten

        def self.urai(gumpalan)
          saya = super
          saya.konten = ContentProvider.urai(gumpalan['contentProvider'])
          return saya
        end
      end
      class Video < Dasar
        data :durasi
        data :konten

        def self.urai(gumpalan)
          saya = super
          saya.durasi = gumpalan['duration']
          saya.konten = ContentProvider.urai(gumpalan['contentProvider'])
          return saya
        end
      end
      class Audio < Dasar
        data :durasi
        data :konten

        def self.urai(gumpalan)
          saya = super
          saya.durasi = gumpalan['duration']
          saya.konten = ContentProvider.urai(gumpalan['contentProvider'])
          return saya
        end
      end
      class Fileu < Dasar
        data :nama
        data :ukuran

        def self.urai(gumpalan)
          saya = super
          saya.nama = gumpalan['fileName']
          saya.ukuran = gumpalan['fileSize']
          return saya
        end
      end
      class Location < Dasar
        data :judul
        data :alamat
        data :latitude
        data :longitude

        def self.urai(gumpalan)
          saya = super
          saya.judul = gumpalan['title']
          saya.alamat = gumpalan['address']
          saya.latitude = gumpalan['latitude']
          saya.longitude = gumpalan['longitude']
          return saya
        end
      end
      class Sticker < Dasar
        data :paket
        data :urutan

        def self.urai(gumpalan)
          saya = super
          saya.paket = gumpalan['packageId']
          saya.urutan = gumpalan['stickerId']
          return saya
        end
      end
      data :kodepos
      data :pesan

      def self.urai(gumpalan)
        saya = super
        saya.kodepos = gumpalan['replyToken']
        saya.pesan =
          case gumpalan['message']['type']
          when 'text'
            Text.urai(gumpalan['message'])
          when 'image'
            Image.urai(gumpalan['message'])
          when 'video'
            Video.urai(gumpalan['message'])
          when 'audio'
            Audio.urai(gumpalan['message'])
          when 'File'
            Fileu.urai(gumpalan['message'])
          when 'location'
            Location.urai(gumpalan['message'])
          when 'sticker'
            Sticker.urai(gumpalan['message'])
          else
            nil
          end
        return saya
      end
    end
    class Follow < Dasar
      data :kodepos

      def self.urai(gumpalan)
        saya = super
        saya.kodepos = gumpalan['replyToken']
        return saya
      end
    end
    class Unfollow < Dasar
    end
    class Join < Dasar
      data :kodepos
      def self.urai(gumpalan)
        saya = super
        saya.kodepos = gumpalan['replyToken']
        return saya
      end
    end
    class Leave < Dasar
    end
    class MemberJoined < Dasar
      data :kodepos
      data :pendaftar
      def self.urai(gumpalan)
        saya = super
        saya.kodepos = gumpalan['replyToken']
        saya.pendaftar = gumpalan['joined']['members'].map {|i| Pengirim.urai(i)}
        return saya
      end
    end
    class MemberLeft < Dasar
      data :pengundur
      def self.urai(gumpalan)
        saya = super
        saya.pengundur = gumpalan['left']['members'].map { |i| Pengirim.urai(i) }
        return saya
      end
    end
    class Postback < Dasar
      class Isi < PenguraiEventLine::DasarEvent
        data :nilai
        data :masukan

        def self.urai(gumpalan)
          saya = super
          saya.nilai = gumpalan['data']
          saya.masukan = gumpalan['params']
          return saya
        end
      end
      data :kodepos
      data :isi
      def self.urai(gumpalan)
        saya = super
        saya.kodepos = gumpalan['replyToken']
        saya.isi = Isi.urai(gumpalan['postback'])
        return saya
      end
    end
    class Beacon < Dasar
      class Rincian < PenguraiEventLine::DasarEvent
        data :nomorperangkat
        data :jenisperangkat
        data :pesanperangkat

        def self.urai(gumpalan)
          saya = super
          saya.nomorperangkat = gumpalan['hwid']
          saya.jenisperangkat = gumpalan['type']
          saya.pesanperangkat = gumpalan['dm']
          return saya
        end
      end
      data :kodepos
      data :rincian
      def self.urai(gumpalan)
        saya = super
        saya.kodepos = gumpalan['replyToken']
        saya.rincian = Rincian.urai(gumpalan['beacon'])
        return saya
      end
    end
    class AccountLink < Dasar
      class Alamat < PenguraiEventLine::DasarEvent
        data :hasil
        data :nonce

        def self.urai(gumpalan)
          saya = super
          saya.hasil = gumpalan['result']
          saya.nonce = gumpalan['nonce']
          return saya
        end
      end
      data :kodepos
      data :almt
      def self.urai(gumpalan)
        saya = super
        saya.kodepos = gumpalan['replyToken']
        saya.almt = Alamat.urai(gumpalan['link'])
        return saya
      end
    end
    class Thing < Dasar
      class Benda < PenguraiEventLine::DasarEvent
        data :nomor
        data :jenis

        def self.urai(gumpalan)
          saya = super
          saya.nomor = gumpalan['deviceId']
          saya.jenis = gumpalan['type']
          return saya
        end
      end
      data :kodepos
      data :bnd
      def self.urai(gumpalan)
        saya = super
        saya.kodepos = gumpalan['replyToken']
        saya.bnd = Benda.urai(gumpalan['things'])
        return saya
      end
    end
    def self.urai(gumpalan)
      case gumpalan['type']
      when 'message'
        Message.urai(gumpalan)
      when 'follow'
        Follow.urai(gumpalan)
      when 'unfollow'
        Unfollow.urai(gumpalan)
      when 'join'
        Join.urai(gumpalan)
      when 'leave'
        Leave.urai(gumpalan)
      when 'memberJoined'
        MemberJoined.urai(gumpalan)
      when 'memberLeft'
        MemberLeft.urai(gumpalan)
      when 'postback'
        Postback.urai(gumpalan)
      when 'beacon'
        Beacon.urai(gumpalan)
      when 'accountLink'
        AccountLink.urai(gumpalan)
      when 'things'
        Thing.urai(gumpalan)
      else
        # Code 400 BadRequest
      end
    end
  end

  def self.urai(gumpalan)
    json = JSON.parse(gumpalan)

    json['events'].map do |e|
      Pengurai.urai(e)
    end
  end
end
