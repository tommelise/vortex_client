require 'rubygems'
require 'vortex_client'
require 'open-uri'
require 'uri'
require 'net/https'
require 'ruby-debug'

def http_content_type(url)
  puts "URL: " + url 
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.request_uri)
  request["User-Agent"] = "My Ruby Script"
  request["Accept"] = "*/*"
  response = http.request(request)
  return response['content-type']
end

def download_image(image_src,dest_path,url)
  image_src = image_src.gsub(/\?.*/,'')
  content_type = http_content_type(image_src)
  puts "content type:" + content_type
  content_type = content_type.gsub("image/", "")
  content_type = content_type.gsub("pjpeg","jpg")
  content_type = content_type.gsub("jpeg","jpg")
  if File.extname(image_src) == ".jpeg" || File.extname(image_src) == ".jpg"
    content_type = "jpg"
  end
  if File.extname(image_src) == ".png"
    content_type = "png"
  end
  if File.extname(image_src) == ".gif"
    content_type = "gif"
  end
  basename = Pathname.new(image_src).basename.to_s.gsub(/\..*/,'')
  #  basename = image_src.gsub(url,dest_path)
  vortex_url = dest_path + basename + "." + content_type
  vortex_url = vortex_url.downcase
  begin
    content = open(image_src).read
    begin
      @vortex.put_string(vortex_url, content)
    rescue Exception => e
      puts e.message
      pp e.backtrace.inspect
      puts "vortex_url: " + vortex_url
      #    exit
    end
  rescue 
    puts "Problems with file: " + vortex_url.to_s
  end
end

def get_images(url,dest_path,images)
images.each do |image_src|
    puts "image_src: " + image_src
    image_src = image_src.gsub("?size=micro","")
    image_src = image_src.gsub("?size=small","")
    image_src = image_src.gsub("?size=medium","")
    image_src = image_src.gsub("?size=large","")
    image_src = image_src.gsub("?size=original","")
    puts "new_image_src: " + image_src
    download_image(image_src,dest_path,url)
    end
  end

@vortex = Vortex::Connection.new("https://nyweb4-dav.uio.no", :osx_keychain => true)

url = "http://www.hlsenteret.no/bilder/"
dest_path = "/konv/bilder/"


images = ["http://www.hlsenteret.no/bilder/01_01.jpg?size=medium",
"http://www.hlsenteret.no/bilder/221.bokomslag_fil.160.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/arnold.44.jpg?size=medium",
"http://www.hlsenteret.no/bilder/274/arnold.44.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8180.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8184.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8186.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8195.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8198.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8200.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8201.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8219.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8231.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8242.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8246.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8251.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8253.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8255.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8256.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8257.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8264.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8265.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8266.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8274.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8276.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hl8283.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/hls_grand_view_crop.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/skilt.jpg?size=large",
"http://www.hlsenteret.no/bilder/274/undervisning_copy.jpg?size=large",
"http://www.hlsenteret.no/bilder/274/utstillingen.jpg?size=large",
"http://www.hlsenteret.no/bilder/274/villagrande1.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/villagrande2.jpg?size=small",
"http://www.hlsenteret.no/bilder/274/villagrande3.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/01112010markmirsky.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/11092007_011_.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/26.nov.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/26.nov.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/6693arnold.21.jpg?size=large",
"http://www.hlsenteret.no/bilder/275/6693arnold.21.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/elise_batnes.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/elise_batnes.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/etterlemkinnr.1-aarg.1-2009.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/falskmyntner_i_sh.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/galbraith_anfal.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/henrik.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/hl_temahefte_2_2007_omslag2.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/hl_temahefte_omslag_2007_01.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/hl_temahefte_omslag_gronn_2.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/img_4738.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/img_4743.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/img_4758.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/img_4774.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/img_4787.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/img_4810.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/kibbutz_1.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/kibbutz_2.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/larsmo.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/levene_genocide.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/lind_knut_rod.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/lind_knut_rod.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/linne-eriksen.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/lislevand_1.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/loi_hjiab.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/mandal_benjamin.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/monument_240ppi-20x26cm.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/ruthmaiersdagbok-300dpi.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/ruthmaiersdagbok-300dpi.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/stolene-pa-akershuskaia.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/stolene-pa-akershuskaia.jpg?size=small",
"http://www.hlsenteret.no/bilder/275/strengthemmelig_hovedmotiv_m_tittel_rgb4.jpg?size=medium",
"http://www.hlsenteret.no/bilder/275/villa_grande_oslomuseene_bannerweb.jpg?size=large",
"http://www.hlsenteret.no/bilder/275/wergeland_portrait.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/1934_protocols_patriotic_pub.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/1942-gjeninnforing_av_jodeparagrafen.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/49813.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/64403.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/64407.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/77342.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/anti-semitismus_1933.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/anti_sem_skilt.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/antisemiticroths.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/auschwitz.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/auschwitz2.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/avis_avlang_kopi.jpg?size=large",
"http://www.hlsenteret.no/bilder/276/avis_avlang_kopi.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/brama-birkenau.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/coffinbg.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/den-norske-legion2.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/der_sturmer_forside.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/edderkoppen-med-tekst.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/ford_intjew.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/himmler.jpg?size=medium",
"http://www.hlsenteret.no/bilder/276/hvite_busser.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/identitetskortj.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/institut_zur_erforscherung_der_judenfrage.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/josef_terboven.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/kart_leirsystem.jpg",
"http://www.hlsenteret.no/bilder/276/krig.nazi.2010.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/lind_knut_rod.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/nasjonal_samling_symbol.jpg?size=small",
"http://www.hlsenteret.no/bilder/276/stolene-pa-akershuskaia.jpg?size=medium",
"http://www.hlsenteret.no/bilder/276/stolene-pa-akershuskaia.jpg?size=small",
"http://www.hlsenteret.no/bilder/277/bb-15.jpg?size=small",
"http://www.hlsenteret.no/bilder/277/bb59.jpg?size=small",
"http://www.hlsenteret.no/bilder/277/collectivization-get-rid-of-kulak.jpg?size=small",
"http://www.hlsenteret.no/bilder/277/kayibanda-med-machete.jpg?size=small",
"http://www.hlsenteret.no/bilder/277/propaganda_collage_kopi.jpg?size=large",
"http://www.hlsenteret.no/bilder/277/propaganda_collage_kopi.jpg?size=small",
"http://www.hlsenteret.no/bilder/277/rwanda_poster.jpg?size=small",
"http://www.hlsenteret.no/bilder/277/surviving_herero.jpg?size=small",
"http://www.hlsenteret.no/bilder/277/tidenst_08.08.1925s1.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/ali_asghar.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/antisemittisme_litauen.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/baba-tahir-bektashi-tekke-t.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/cimg1399.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/cimg1589.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/declaration_of_human_rights.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/hajj-hus.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/kamakura_budda_daibutsu_front_1885_1_.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/pinsegudstjeneste-i-suto-or.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/small_knives.jpg?size=small",
"http://www.hlsenteret.no/bilder/278/zuljenah.jpg?size=small",
"http://www.hlsenteret.no/bilder/7165/fromhet_web.jpg?size=small",
"http://www.hlsenteret.no/bilder/7165/stor_poster.jpg",
"http://www.hlsenteret.no/bilder/7214/as-bilde.jpg?size=original",
"http://www.hlsenteret.no/bilder/7214/banner_web.jpg?size=original",
"http://www.hlsenteret.no/bilder/7214/bauer_triumph_web.jpg",
"http://www.hlsenteret.no/bilder/7214/herrefolk_web.jpg?size=original",
"http://www.hlsenteret.no/bilder/7214/himmler_og_lie.jpg?size=original",
"http://www.hlsenteret.no/bilder/7214/logosamling_cut.jpg",
"http://www.hlsenteret.no/bilder/7214/naziparade3.jpg?size=original",
"http://www.hlsenteret.no/bilder/7214/nesemaling_crop.jpg?size=original",
"http://www.hlsenteret.no/bilder/7214/oyemaling.jpg?size=original",
"http://www.hlsenteret.no/bilder/7214/toppbanner_ungdomsskole_3copy.jpg?size=original",
"http://www.hlsenteret.no/bilder/ansatte/antonimg_7969.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/antonimg_7969.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/christianimg_8062.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/christianimg_8062.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/christopherimg_8050.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/christopherimg_8050.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/erikimg_8038.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/erikimg_8038.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/georgimg_8035.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/georgimg_8035.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/kariimg_8320.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/kariimg_8320.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/kjetil.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/kjetil.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/larsimg_8071.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/larsimg_8071.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/minkimg_8044.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/minkimg_8044.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/odd_bjornimg_8101_1.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/odd_bjornimg_8101_1.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/oysteinimg_8330.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/oysteinimg_8330.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/oyvindimg_8025.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/oyvindimg_8025.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/pederimg_8279.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/pederimg_8279.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/ragnhildimg_8060.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/ragnhildimg_8060.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/sigurdimg_8532.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/sigurdimg_8532.jpg?size=micro",
"http://www.hlsenteret.no/bilder/ansatte/small_town_russia.cover_cut.jpg?size=small",
"http://www.hlsenteret.no/bilder/ansatte/terje2img_7981.jpg?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/terje2img_7981.jpg?size=micro",
"http://www.hlsenteret.no/bilder/classroom.jpg?size=medium",
"http://www.hlsenteret.no/bilder/classroom.jpg?size=small",
"http://www.hlsenteret.no/bilder/copy_of_plakat.jpg",
"http://www.hlsenteret.no/bilder/detkanskjeigjen.jpg?size=small",
"http://www.hlsenteret.no/bilder/ewige_web_front_1_.jpg?size=medium",
"http://www.hlsenteret.no/bilder/forestillingen_om_herrefolket.jpg?size=small",
"http://www.hlsenteret.no/bilder/gacaca.jpg?size=small",
"http://www.hlsenteret.no/bilder/havard_gimse.jpg?size=medium",
"http://www.hlsenteret.no/bilder/historicizing_the_uses_of_the_past.jpg?size=small",
"http://www.hlsenteret.no/bilder/hl_temahefte_2009_7_omslag-_ny_til_wweb.jpg?size=small",
"http://www.hlsenteret.no/bilder/intergrering_cover.jpg?size=small",
"http://www.hlsenteret.no/bilder/jakten_pa_germania.jpg?size=small",
"http://www.hlsenteret.no/bilder/jodeaksjon_dump.jpg?size=small",
"http://www.hlsenteret.no/bilder/kartet_oslo.jpg?size=small",
"http://www.hlsenteret.no/bilder/logo_turist_i_egen_by.jpg?size=medium",
"http://www.hlsenteret.no/bilder/lorenz_web_ill.jpg?size=small",
"http://www.hlsenteret.no/bilder/maerz_forside.jpg?size=small",
"http://www.hlsenteret.no/bilder/murder-190.jpg?size=small",
"http://www.hlsenteret.no/bilder/n20531316728_2397.jpg?size=small",
"http://www.hlsenteret.no/bilder/nyhet_53b33d0aa2b89eaace83042d9f7c57ee_1_.jpg?size=small",
"http://www.hlsenteret.no/bilder/olga_kukovic.jpg?size=small",
"http://www.hlsenteret.no/bilder/propaganda_funksjonshemmede2.jpg?size=small",
"http://www.hlsenteret.no/bilder/triumph_poster-731265.jpg?size=medium",
"http://www.hlsenteret.no/bilder/turist-i-egen-by2010.jpg?size=medium",
"http://www.hlsenteret.no/bilder/vermessungen2_web2.jpg?size=small",
"http://www.hlsenteret.no/mapper/eng/elements/skilt_jpg_large.jpg",
"http://www.hlsenteret.no/bilder/275/oslo_kammermusikk3.gif?size=medium",
"http://www.hlsenteret.no/bilder/276/1507tyskland_etter_45.gif?size=small",
"http://www.hlsenteret.no/bilder/276/wt_logo2.gif?size=small",
"http://www.hlsenteret.no/bilder/277/hutuprop.gif?size=small",
"http://www.hlsenteret.no/bilder/277/kambodjsa.gif?size=small",
"http://www.hlsenteret.no/bilder/277/rw-map.gif?size=small",
"http://www.hlsenteret.no/bilder/278/nistjerne.gif?size=small",
"http://www.hlsenteret.no/bilder/278/tro_og_viten.gif?size=small",
"http://www.hlsenteret.no/bilder/by_og_land-hand_i_hand_1_.gif?size=medium",
"http://www.hlsenteret.no/bilder/logo_1_.gif?size=small",
"http://www.hlsenteret.no/bilder/272/anettte.png?size=medium",
"http://www.hlsenteret.no/bilder/275/falck.png?size=medium",
"http://www.hlsenteret.no/bilder/275/fjeldstuen_8._mars_2008.png?size=medium",
"http://www.hlsenteret.no/bilder/275/hl-senteret_linne-eriksen_forside.png?size=small",
"http://www.hlsenteret.no/bilder/275/illuminatus.png?size=medium",
"http://www.hlsenteret.no/bilder/275/nackt_unter_wolfen.png?size=medium",
"http://www.hlsenteret.no/bilder/276/minnesmerke_folder.png?size=large",
"http://www.hlsenteret.no/bilder/276/minnesmerke_folder.png?size=medium",
"http://www.hlsenteret.no/bilder/277/little_red_book.png?size=small",
"http://www.hlsenteret.no/bilder/278/different_equal.png?size=small",
"http://www.hlsenteret.no/bilder/278/green_shahada_crescent.png?size=small",
"http://www.hlsenteret.no/bilder/9330hl_lind_bilde.png?size=small",
"http://www.hlsenteret.no/bilder/ansatte/katusha-2.png?size=medium",
"http://www.hlsenteret.no/bilder/ansatte/katusha-2.png?size=micro",
"http://www.hlsenteret.no/bilder/byggforalle-logo.png",
"http://www.hlsenteret.no/bilder/hl_jodene_i_polen_bilde.png?size=small",
"http://www.hlsenteret.no/bilder/hl_lind_bilde.png?size=small",
"http://www.hlsenteret.no/bilder/hl_minoritet_bilde.png?size=small",
"http://www.hlsenteret.no/bilder/hl_temahefte_nr4_forside.png?size=small",
"http://www.hlsenteret.no/bilder/hl_temahefte_nr5_forside.png?size=small",
"http://www.hlsenteret.no/bilder/minnesmonumentet_i_malmo.png?size=medium"]

get_images(url,dest_path,images)
