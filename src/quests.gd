class_name Quests
extends RefCounted

# BG2-style quest journal: NPCs offer quests; progress is tracked live during
# runs (kills / kind_kills / time / boss downs / loot); turn-in at the giver
# pays choralim, items, or unlocks world-map nodes.

# objective types:
#   kills n               — total kills this run
#   kind <name> n         — kills of one enemy kind (KIND_NAME)
#   time n                — survive n seconds in one run
#   boss <id>             — defeat boss id ("rex","host","twins","final")
#   win                   — any victory
#   elites n              — elite kills this run
#   evos n                — evolutions this run
#   loot n                — items found this run
#   biomes n              — visit n distinct areas (meta.visited)
# reward: {"cho": int, "item": id, "node": node_id, "wep": weapon_id}
const DEFS := [
	{"id": "q_kan",    "giver": "rhasa",   "name": "KAN VERGİSİ",      "desc": "Kovan kanla beslenir. Tek koşuda 200 kesim yap.",         "obj": {"type": "kills", "n": 200},  "rew": {"cho": 60}},
	{"id": "q_varl",   "giver": "ehnar",   "name": "ÇÖLAYAN AVI",      "desc": "Çölayan Varl'lar kamp sınırını kokluyor. 25 tanesini kes.", "obj": {"type": "kind", "k": "Çölayan Varl", "n": 25}, "rew": {"cho": 50, "item": "i_cizme"}},
	{"id": "q_surv",   "giver": "neva",    "name": "REZONANS TÜRKÜSÜ", "desc": "Şarkıya altı dakika dayan — bir koşuda 360 sn hayatta kal.", "obj": {"type": "time", "n": 360}, "rew": {"cho": 80}},
	{"id": "q_rex",    "giver": "rhasa",   "name": "DÜŞMÜŞ KARDEŞ",    "desc": "Alfa-05'i serbest bırak — Endusterra'nın efendisini düşür.", "obj": {"type": "boss", "k": "rex"}, "rew": {"cho": 120, "node": "yol"}},
	{"id": "q_elit",   "giver": "ehnar",   "name": "ELİT DEFTERİ",     "desc": "Elitler sandık taşır. Tek koşuda 6 elit kes.",             "obj": {"type": "elites", "n": 6},   "rew": {"cho": 70, "item": "i_hirsiz"}},
	{"id": "q_evo",    "giver": "vane",    "name": "SAHA DENEYİ",      "desc": "Evrim zincirini test et — bir koşuda 2 evrim tamamla.",    "obj": {"type": "evos", "n": 2},     "rew": {"cho": 90, "item": "i_maske"}},
	{"id": "q_host",   "giver": "david",   "name": "DAMARLARIN KALBİ", "desc": "Simithar'ın Konakçı'sını düşür — madenin kapağını açar.",  "obj": {"type": "boss", "k": "host"}, "rew": {"cho": 140, "node": "tarla"}},
	{"id": "q_loot",   "giver": "saphire", "name": "HURDA MERAKI",     "desc": "Pazar için malzeme lazım. Bir koşuda 3 eşya bul.",         "obj": {"type": "loot", "n": 3},    "rew": {"cho": 60, "node": "pazar"}},
	{"id": "q_gez",    "giver": "david",   "name": "İZ SÜRÜCÜNÜN İZİ", "desc": "Dört sahayı da gör. Her bioma bir koşu yap.",              "obj": {"type": "biomes", "n": 4},   "rew": {"cho": 110, "item": "i_ikiz"}},
	{"id": "q_final",  "giver": "zirkon",  "name": "SON KAYIT",        "desc": "Masadaki son iki isim: Kirin ve Constantin'i düşür.",      "obj": {"type": "boss", "k": "final"}, "rew": {"cho": 250, "item": "i_final"}},
	{"id": "q_zafer",  "giver": "ahusk",   "name": "GÖÇEBENİN İNADI",  "desc": "Kovandan kaçan yaşar, kovana dönen kazanır. Bir zafer getir.", "obj": {"type": "win"}, "rew": {"cho": 100, "item": "i_kantas"}},
	{"id": "q_deep",   "giver": "vane",    "name": "DERİN PROTOKOL",   "desc": "Aeterna'nın altında bir şey sinyal veriyor — Kirin sonrası açılır.", "obj": {"type": "boss", "k": "final"}, "rew": {"node": "kuyu"}, "prereq": "q_final"},
	# — zincir görevler: ilk halka teslim edilince ikincisi açılır —
	{"id": "q_varl2",  "giver": "ehnar",   "name": "SINIR TEMİZLİĞİ",  "desc": "Sınır hâlâ sıcak. 40 Çölayan Varl daha kes — bu sefer kökünden.", "obj": {"type": "kind", "k": "Çölayan Varl", "n": 40}, "rew": {"cho": 80, "item": "i_ruzgar"}, "prereq": "q_varl"},
	{"id": "q_kan2",   "giver": "rhasa",   "name": "KAN ORANI",        "desc": "Vergi büyüdü. Tek koşuda 300 kesim — kovan bunu hissedecek.",  "obj": {"type": "kills", "n": 300},  "rew": {"cho": 120, "item": "i_halka2"}, "prereq": "q_kan"},
	{"id": "q_surv2",  "giver": "neva",    "name": "UZUN TÜRKÜ",       "desc": "Şarkı sekiz dakikaya uzuyor — bir koşuda 480 sn hayatta kal.",  "obj": {"type": "time", "n": 480},   "rew": {"cho": 130, "item": "i_aegis"}, "prereq": "q_surv"},
	{"id": "q_loot2",  "giver": "saphire", "name": "KOLEKSİYONCUNUN GÖZÜ", "desc": "Tezgâh doluyor ama hâlâ eksik. Bir koşuda 6 eşya bul — karşılığında bilinen bir rota var.", "obj": {"type": "loot", "n": 6}, "rew": {"cho": 120, "node": "yuvalar"}, "prereq": "q_loot"},
	{"id": "q_vatika", "giver": "neva",    "name": "SESSİZ VATİKA",    "desc": "Aeterna dibinde bir sığınak var. Uzun Türkü'nü bitirene yolu açarım.", "obj": {"type": "boss", "k": "twins"}, "rew": {"node": "vatika"}, "prereq": "q_surv2"},
	{"id": "q_dua",    "giver": "ahusk",   "name": "SESSİZ DUA",       "desc": "Mabed hâlâ dinliyor. Bir koşuda 300 sn boyunca tek parça kal — tapınağın yolu açılır.", "obj": {"type": "time", "n": 300}, "rew": {"cho": 90, "node": "mabed"}},
	{"id": "q_nobet",  "giver": "ehnar",   "name": "SON NÖBET",        "desc": "Mezardaki nöbetçiler sayıyor. Tek koşuda 10 elit kes — mezarın kapağı kalkar.", "obj": {"type": "elites", "n": 10}, "rew": {"cho": 110, "node": "mezarlik"}, "prereq": "q_elit"},
	{"id": "q_batak",  "giver": "david",   "name": "BATAKLIK ROTASI",   "desc": "Konakçı Yaratıkların izi doğuda bir bataklığa çıkıyor. 8 tanesini kes — rotayı çizerim.", "obj": {"type": "kind", "k": "Konakçı Yaratık", "n": 8}, "rew": {"cho": 90, "node": "batak"}, "prereq": "q_gez"},
	{"id": "q_sans",   "giver": "tegan",   "name": "SİMSAR'IN ŞANSI",   "desc": "Masa döner — 3 bahis tuttur, sana şanslı zarını veririm.", "obj": {"type": "bets", "n": 3}, "rew": {"cho": 150, "item": "i_zar"}},
	{"id": "q_sis",    "giver": "ahusk",   "name": "SİS PERDESİ",        "desc": "Kistlerin şarkısı batıda bir geçidi işaretliyor. 12 Cerebellum Kisti kes — geçidi bulayım.", "obj": {"type": "kind", "k": "Cerebellum Kisti", "n": 12}, "rew": {"cho": 100, "node": "sisgecidi"}, "prereq": "q_dua"},
	{"id": "q_sinir",  "giver": "david",   "name": "HARİTA SINIRI",      "desc": "Haritanın tamamı yankılanmalı. Altı farklı sahada koşu yap.", "obj": {"type": "biomes", "n": 6}, "rew": {"cho": 150}, "prereq": "q_batak"},
	{"id": "q_nobet2", "giver": "ehnar",   "name": "NÖBETÇİNİN KİLİDİ",  "desc": "Elitler defterde iz bırakır. Tek koşuda 15 elit kes — rekoru kır.", "obj": {"type": "elites", "n": 15}, "rew": {"cho": 140, "item": "i_gocek"}, "prereq": "q_nobet"},
	{"id": "q_lanet", "giver": "saphire", "name": "LANETLİ MALLAR",    "desc": "Kızıl sandıklar pusu taşıyor ama içi dolu. 3 lanetli sandık aç — pusuya değer.", "obj": {"type": "cursed", "n": 3}, "rew": {"cho": 130, "item": "i_bosluk"}, "prereq": "q_loot"},
	{"id": "q_kul",   "giver": "david",   "name": "KÜL ROTASI",         "desc": "Kuyu'nun doğusunda kül hâlâ yanıyor — Alfa Şövalyeleri orada toplanıyor. 10 tanesini kes, rotayı çıkarayım.", "obj": {"type": "kind", "k": "Alfa Şövalye", "n": 10}, "rew": {"cho": 150, "node": "kulovasi"}, "prereq": "q_sinir"},
	{"id": "q_yemin", "giver": "ehnar",   "name": "DARE YEMİNİ",        "desc": "Güneyde eski bir dare yeri var — şifa küresi düşmeyen meydan. Bir zafer getir, yemin kapısını açayım.", "obj": {"type": "win"}, "rew": {"cho": 180, "node": "yemin"}, "prereq": "q_nobet"},
	{"id": "q_iz",    "giver": "neva",    "name": "YANKININ İZİ",       "desc": "Düştüğün yerde parçacıkların kalır. Öldüğün sahaya geri dön, eski cesedinden yükünü geri al — iki kez.", "obj": {"type": "ceset", "n": 2}, "rew": {"cho": 140, "item": "i_koro"}, "prereq": "q_surv"},
	{"id": "q_aura",  "giver": "vane",    "name": "AURA FİŞEĞİ",         "desc": "Rezonans protokolü denemeye hazır. Tek koşuda 12 elit kes — fişeği sana bağlarım.", "obj": {"type": "elites", "n": 12}, "rew": {"cho": 160, "wep": "aura"}, "prereq": "q_nobet"},
	{"id": "q_skor",  "giver": "rhasa",   "name": "SKOR VERGİSİ",        "desc": "Kovan rekor sever. Tek koşuda 4000 skor yap — oranını yükseltirim.", "obj": {"type": "score", "n": 4000}, "rew": {"cho": 260}, "prereq": "q_kan2"},
	{"id": "q_vergi", "giver": "rhasa",   "name": "ALTIN VERGİ",         "desc": "Kovan altınla sınanır — sahada gezen şampiyonların madalyonları hazinenin. Üç şampiyon kes, kovan seni tanısın.", "obj": {"type": "champ", "n": 3}, "rew": {"cho": 300, "item": "i_cengel"}, "prereq": "q_skor"},
	{"id": "q_frag",  "giver": "saphire", "name": "PARÇACIK HASADI",     "desc": "Tezgâh parçacıksız dönmez. Tek koşuda 600 parçacık topla — kesende dursun, teslime gerek yok.", "obj": {"type": "frag", "n": 600}, "rew": {"cho": 140}, "prereq": "q_loot"},
	{"id": "q_glaive","giver": "ehnar",   "name": "AĞIR TAHMİS",         "desc": "Sırp diskleri depoda paslanıyor. Tek koşuda 400 kesim yaparsan birini sana kalibrarım.", "obj": {"type": "kills", "n": 400}, "rew": {"cho": 150, "wep": "glaive"}, "prereq": "q_nobet2"},
	{"id": "q_deneme","giver": "ehnar",   "name": "DENEME KANITI",       "desc": "Sahalardaki eski deneme totemleri hâlâ sayıyor. İkisini tamamla — ikisinin de elitleri düşsün.", "obj": {"type": "totem", "n": 2}, "rew": {"cho": 170, "item": "i_koro"}, "prereq": "q_elit"},
	{"id": "q_damar", "giver": "saphire", "name": "DAMAR AVCISI",          "desc": "Sahalarda altın choralim damarları beliriyor — yanında durup kır, parçacıklar senin. Üçünü kır.", "obj": {"type": "vein", "n": 3}, "rew": {"cho": 220}, "prereq": "q_frag"},
	{"id": "q_son",   "giver": "zirkon",  "name": "ARŞİVİN SONU",        "desc": "Defterin son sayfası boş kalmasın. On görev teslim et — arşivin mührü senin olsun.", "obj": {"type": "quests", "n": 10}, "rew": {"cho": 400, "wep": "meteor"}, "prereq": "q_final"},
	{"id": "q_siparis","giver": "saphire","name": "MÜŞTERİ SİPARİŞİ",    "desc": "Bir müşteri Boşluk Halkası istiyor — bulursan stoğa değil, doğrudan bana getir. Teslimde parça senden çıkar.", "obj": {"type": "item", "id": "i_bosluk", "n": 1}, "rew": {"cho": 320, "item": "i_ruzgar"}, "prereq": "q_lanet"},
	{"id": "q_kayit", "giver": "zirkon",  "name": "VERİ AVCISI",          "desc": "Sahalarda hâlâ kütük parçaları saçılı. Beş veri kütüğü topla — arşiv senden borçlu kalacak.", "obj": {"type": "kayit", "n": 5}, "rew": {"cho": 180, "item": "i_merdiven"}, "prereq": "q_final"},
	{"id": "q_sampiyon","giver": "ehnar", "name": "ALTIN TEHDİT",        "desc": "Geç saatlerde altınla parlayan şampiyonlar geziyor — birini kes, madalyonun benim olsun.", "obj": {"type": "champ", "n": 1}, "rew": {"cho": 220}, "prereq": "q_nobet2"},
	{"id": "q_anil",  "giver": "david",   "name": "SON İZLER",            "desc": "Müfretemin son izi Kızıl Çöl'de bitti. Sekiz sahayı da gör — haritanın tamamı yankılansın, eski defter kapansın.", "obj": {"type": "biomes", "n": 8}, "rew": {"cho": 300, "cine": [{"tex": "por_david", "title": "DAVID", "sub": "Hepsini gördün. Müfretemin izi artık haritada değil — hatırada."}, {"tex": "cine_6_0", "title": "SON İZ", "sub": "Kızıl Çöl'ün kumunda yarım bir izcilik nişanı: S-7. Geri getiren tek parçacık oydu."}]}, "prereq": "q_kul"},
	{"id": "q_tekel", "giver": "saphire", "name": "TEKEL BARIŞI",        "desc": "Açgöz bobinleri hâlâ işliyor — tek koşuda 1800 parçacık biriktir, bobinin kalibrasyon hakkı senin.", "obj": {"type": "frag", "n": 1800}, "rew": {"cho": 260}, "prereq": "q_damar"},
	{"id": "q_vaha",  "giver": "saphire", "name": "ÇÖLÜN ALACASI",       "desc": "Kervanlar bir vaha rotasını benden gizledi — tek koşuda 900 parçacık getir, haritadaki yeşil lekeyi sana satarım.", "obj": {"type": "frag", "n": 900}, "rew": {"cho": 220, "node": "vaha"}, "prereq": "q_tekel"},
	{"id": "q_safdamar", "giver": "saphire", "name": "SAF DAMAR",        "desc": "Çukurun ana yatağı imparatorluğun en zengin ocağıydı — haritada duruyor ama girişi kristal gömdü. Tek koşuda 1600 parçacık biriktir, kazıyı ben finanse ederim.", "obj": {"type": "frag", "n": 1600}, "rew": {"cho": 280, "node": "damar"}, "prereq": "q_vaha"},
	{"id": "q_fener", "giver": "ehnar",  "name": "YANKI AVCISI",         "desc": "Sahalardaki sinyal fenerleri yankı şampiyonları uyandırıyor. Üç feneri kır — deneme alanı temizlensin.", "obj": {"type": "fener", "n": 3}, "rew": {"cho": 280, "item": "i_cengel"}, "prereq": "q_deneme"},
	{"id": "q_ocak",  "giver": "ehnar",   "name": "OCAĞIN KAPISI",       "desc": "Kuzeyde çatlak bir ocak var — elitler nabzını koruyor. Tek koşuda 12 elit kes — kapıyı göstereyim.", "obj": {"type": "elites", "n": 12}, "rew": {"cho": 160, "node": "tasocagi"}, "prereq": "q_nobet"},
	{"id": "q_lena",  "giver": "lena",    "name": "LENA'NIN HARİTASI",    "desc": "Kafes beni haritadan attı; haritayı geri çizelim. Üç farklı düğümde zafer getir — pusulamı sana bırakırım.", "obj": {"type": "nodes", "n": 3}, "rew": {"cho": 200, "item": "i_pusula"}},
	{"id": "q_koro",  "giver": "lena",    "name": "ÇAN KESİCİ",           "desc": "Haritada bir yeri işaretledim: orada sürüyü çanla yöneten sözcüler dolaşıyor. Altısını kes, güzergâhlar açılsın — vizörüm senin.", "obj": {"type": "kind", "k": "Koro Sözcüsü", "n": 6}, "rew": {"cho": 220, "item": "i_gocek"}, "prereq": "q_lena"},
	{"id": "q_kum",   "giver": "lena",    "name": "KUM SESLERİ",          "desc": "Çölayan varllerin izleri batıdaki kızıl kuma uzanıyor — on tanesinin izini sür, çölün kapısını haritaya işlerim.", "obj": {"type": "kind", "k": "Çölayan Varl", "n": 10}, "rew": {"cho": 160, "node": "kum", "item": "i_kemer_kum"}, "prereq": "q_koro"},
	{"id": "q_goz",   "giver": "lena",    "name": "GÖZETİM ALTINDA",      "desc": "Aeterna'nın süzülen gözleri rotaları kilitliyor — uzaktan vuruyorlar, yaklaşmak iş. Sekizini düşür, merceğimi sana takayım.", "obj": {"type": "kind", "k": "Gözetmen", "n": 8}, "rew": {"cho": 220, "item": "i_gozcu"}, "prereq": "q_koro"},
	{"id": "q_cukur", "giver": "lena",    "name": "ÇUKURUN ŞARKISI",      "desc": "Gözetmenlerin hepsi aynı yöne bakıyor — Aeterna'nın dibinde bir kuyu var, eski haritalarda 'kristal çukur' yazar. On gözü daha düşür, girişi çizeyim.", "obj": {"type": "kind", "k": "Gözetmen", "n": 10}, "rew": {"cho": 260, "node": "cukur"}, "prereq": "q_goz"},
	{"id": "q_buz",  "giver": "lena",    "name": "BUZUN ŞARKISI",         "desc": "Çukurun kuzeyinde haritalarım buzla bitiyor — ama fısıltılar orada durmuyor. Damar golemlerinden sekizini düşür, kuzey kapısını çizeyim.", "obj": {"type": "kind", "k": "Damar Golemi", "n": 8}, "rew": {"cho": 300, "node": "buzul"}, "prereq": "q_cukur"},
	{"id": "q_buzruh","giver": "lena",    "name": "DONMUŞ NEFES",         "desc": "Çatlakta nefes kesen şey var — süzüldüğü yerde buz seriyor. On dört Buz Ruhu'nu kır, kalbini kolyeye işleyeyim.", "obj": {"type": "kind", "k": "Buz Ruhu", "n": 14}, "rew": {"cho": 340, "item": "i_buzkalp"}, "prereq": "q_buz"},
	{"id": "q_ufuk",  "giver": "lena",    "name": "BEYAZIN ÖTESİ",        "desc": "Haritada boş bıraktığım köşe var — kuzeyin ucu. Buz Anası düştü, yol açık; ama ufku görenlerin dönmediği yazıyor notlarımda. Yirmi beş Buz Ruhu kır, oraya sen git.", "obj": {"type": "kind", "k": "Buz Ruhu", "n": 25}, "rew": {"cho": 380, "node": "beyazufuk", "rep": 3}, "prereq": "q_buzruh"},
	{"id": "q_buzana","giver": "zirkon",  "name": "BUZUN HÜKMÜ",           "desc": "Defterde bir sayfa buzla kaplı — çatlağın dibinde bir hanım bekliyor. Buz Anası'nı düşür; kıskacını sana yüzük yapayım, kuzeydeki donmuş kervanın yolunu da işlerim.", "obj": {"type": "boss", "k": "buz"}, "rew": {"cho": 360, "item": "i_kiragi", "node": "kervan"}, "prereq": "q_buzruh"},
	{"id": "q_tayf",  "giver": "lena",    "name": "PERDENİN ARDI",        "desc": "Ufku gördün — şimdi orada dolaşanlar var. Belirip dağılan ışık hortlakları; on sekizini dağılmadan kes, perdenin ardını birlikte okuyalım.", "obj": {"type": "kind", "k": "Ufuk Tayfı", "n": 18}, "rew": {"cho": 460, "rep": 3, "item": "i_tayfperde"}, "prereq": "q_ufuk"},
	{"id": "q_nur",   "giver": "lena",    "name": "SON FENER",            "desc": "Notlarımın son sayfası: 'ufkun sonunda bir fener yanıyor — kim söndürürse kuzey gerçekten biter.' Nur'u düşür; feneri kolye yaparım, ufkun haritası tamamlanır.", "obj": {"type": "boss", "k": "nur"}, "rew": {"cho": 520, "rep": 4, "item": "i_nurfener", "cine": "cine_8"}, "prereq": "q_tayf"},
	{"id": "q_vdamar","giver": "vane",    "name": "DAMARIN KALBİ",        "desc": "Lena'nın çukuru açtı — dibindeki damarın kalbinden bir mühür çıkar. Çukuru fethet, keserim.", "obj": {"type": "won_node", "id": "cukur", "n": 1}, "rew": {"cho": 300, "item": "i_damar"}},
	{"id": "q_dipte", "giver": "david",   "name": "DİPTEKİ KALP",         "desc": "Çukurun dibinde bir kalp atıyor — müfretemin defterinde bile geçmiyordu. Kuyunun tamamını fethet, izini ben çizeyim.", "obj": {"type": "won_node", "id": "cukur", "n": 1}, "rew": {"cho": 200}, "prereq": "q_cukur"},
	{"id": "q_gol",   "giver": "ehnar",   "name": "KRİSTAL YUMRUK",       "desc": "Çukurda damardan yürüyen golemler var — on tanesini çökert; yumruğunu sana eldiven yaparım, arkasında madenci barakasının yolunu da işlerim.", "obj": {"type": "kind", "k": "Damar Golemi", "n": 10}, "rew": {"cho": 240, "item": "i_golkalp", "node": "baraka"}, "prereq": "q_cukur"},
	{"id": "q_kalp",  "giver": "zirkon",  "name": "KALP DURDURAN",        "desc": "Defterin son sayfası boş — çukurun dibindeki kalp atmayı bırakırsa protokolün bütün damarları sayılır. Damar Kalbi'ni düşür; kalbin parçasını yüzük yapayım.", "obj": {"type": "boss", "k": "damar"}, "rew": {"cho": 320, "item": "i_kalpparca"}, "prereq": "q_vdamar"},
	{"id": "q_dg",    "giver": "vane",    "name": "GÖVDENİN ŞARKISI",     "desc": "Kalp kalıntılarından bir kasa dövdüm — G-1'i sahada sınamadan kampı salmam. O gövdeyle bir zafer getir; nabız çekirdeğini kemerine takarım.", "obj": {"type": "hero_won", "id": "dg", "n": 1}, "rew": {"cho": 280, "item": "i_nabizcek"}, "prereq": "q_kalp"},
	{"id": "q_jeot",  "giver": "lena",    "name": "ÇATLAK SESLERİ",       "desc": "Çukurda ara sıra jeotlar çatlıyor — içleri saf damar dolu. İkisini kır, çatlaklardan çıkan gözü kolye yapayım.", "obj": {"type": "geo", "n": 2}, "rew": {"cho": 220, "item": "i_jeotgoz"}, "prereq": "q_cukur"},
	{"id": "q_fisilti","giver": "lena",   "name": "FISILTI AVCISI",       "desc": "Çukurun duvarları fısıldıyor — kopan kristal parçaları sürü halinde saldırıyor. On sekizini dağıt; en berrak parçayı küpe yaparım.", "obj": {"type": "kind", "k": "Damar Fısıltısı", "n": 18}, "rew": {"cho": 240, "item": "i_fisilti"}, "prereq": "q_jeot"},
	{"id": "q_copcu","giver": "saphire", "name": "ÇÖPÇÜ AVI",           "desc": "Enkazdaki çöpçü kurtlar dökülen kristalleri yutuyor — benim payımı da mideye indiriyorlar. On ikisini kes, dişlerinden dizi yapayım.", "obj": {"type": "kind", "k": "Çöpçü Kurt", "n": 12}, "rew": {"cho": 200, "item": "i_kurtdis"}, "prereq": "q_lena"},
	{"id": "q_barut","giver": "david",   "name": "BARUT TOZU",          "desc": "Simithar'ın tayfleri fıçı taşıyor — biri patlarsa konvoy bölünür. On tanesini kes, fitilini yüzük yapayım.", "obj": {"type": "kind", "k": "Dinamitçi Tayf", "n": 10}, "rew": {"cho": 200, "item": "i_fitil"}, "prereq": "q_gez"},
	{"id": "q_kendiatesi","giver": "david","name": "KOVANIN ATEŞİ",       "desc": "Barutçunun fıçısı kör — sürüsüne de sarar. On beş kesimi fıçıya saydır; maden başlığımı veririm.", "obj": {"type": "keg", "n": 15}, "rew": {"cho": 220, "item": "i_barut"}, "prereq": "q_barut"},
	{"id": "q_igne",  "giver": "saphire", "name": "İĞNE AVCISI",          "desc": "Kumun altında gezen akrepler kervanları ikiye bölüyor. On beşini kes — iğne keselerini kını yaparım, hançer tadında işler.", "obj": {"type": "kind", "k": "Kum Akrebi", "n": 15}, "rew": {"cho": 200, "item": "i_igne"}, "prereq": "q_kum"},
	{"id": "q_batik", "giver": "saphire", "name": "BATIĞIN YÜKÜ",         "desc": "Benim eski kervanım kuma gömüldü — ambarları hâlâ dolu. Tek koşuda 1200 parçacık topla, batığın güverte kapısının yerini vereyim.", "obj": {"type": "frag", "n": 1200}, "rew": {"cho": 240, "node": "batik"}, "prereq": "q_igne"},
	{"id": "q_kralice", "giver": "saphire", "name": "ÇÖLÜN HÜKÜMRARI",   "desc": "Batığın dibinde bir kraliçe yuva yaptı — benim kervanımı ona yedirdi. Kum Anası'nı düşür; iğnesini sana yüzük yaparım.", "obj": {"type": "boss", "k": "anasi"}, "rew": {"cho": 220, "item": "i_anasi_igne"}, "prereq": "q_batik"},
	{"id": "q_degirmen", "giver": "lena",  "name": "DEĞİRMEN SESLERİ",   "desc": "Kum fırtınalarının arasında eski yel değirmenleri hâlâ dönüyor — tek koşuda 350 kesim yap, güzergâhını haritaya işlerim.", "obj": {"type": "kills", "n": 350}, "rew": {"cho": 150, "node": "degirmen"}, "prereq": "q_kum"},
	{"id": "q_kervan", "giver": "tegan",   "name": "SİMSARIN KAYBI",     "desc": "Değirmenlerin ötesinde kumun altında bir han gömülü — kervanımın yarısı orada kaldı, mahzeni hâlâ dolu. Altı kum akrebi iğnesi getir, hanın kilidinin zamanını sana çözerim.", "obj": {"type": "kind", "k": "Kum Akrebi", "n": 6}, "rew": {"cho": 260, "node": "kervansaray", "rep": 2}, "prereq": "q_degirmen"},
	{"id": "q_depot", "giver": "vane",    "name": "MÜHÜRLÜ DEPO",       "desc": "Simithar'ın planlarında bir 'maden kasası' var — mühür mekanik, kapı zamana bağlı; tek ihtiyacımız kasaya giden yolu temiz tutacak kadar parçacık saygınlığı. Tek koşuda 1100 parçacık biriktir, depo rotasını senin için açarım.", "obj": {"type": "frag", "n": 1100}, "rew": {"cho": 240, "node": "madenkasa", "rep": 2}, "prereq": "q_loot"},
	{"id": "q_yagma", "giver": "tegan",   "name": "ÇİFT KASA",            "desc": "İki mühürlü kasa da açıldıysa kervan borcum kapanır — han ve depo, ikisini de yağmala, payımı alırım.", "obj": {"type": "hazine", "n": 2}, "rew": {"cho": 320, "rep": 3}, "prereq": "q_kervan"},
	{"id": "q_korkasa","giver": "tegan",  "name": "KOR KASASI",           "desc": "Kül Ovası'nın altında üçüncü bir kasa var — mührü ısıyla besleniyor, bekçisi ateşin kendisi. Kor Yücelten'i düşür; kasa yolu soğuyunca senin için yanar.", "obj": {"type": "boss", "k": "kor"}, "rew": {"cho": 300, "node": "korkasa", "rep": 2}, "prereq": "q_yagma"},
	{"id": "q_yagmaci","giver": "tegan",  "name": "YAĞMACININ YEMİNİ",    "desc": "Üç kasa da açıldı, dördüncü yağma benim terazimi taşırır — dört kez mahzen boşalt; han, depo ve kor kasası fark etmez. Kantar taşım senin olsun.", "obj": {"type": "hazine", "n": 4}, "rew": {"cho": 380, "item": "i_kantas", "rep": 3}, "prereq": "q_korkasa"},
	{"id": "q_buzkasa","giver": "tegan",  "name": "BUZUN ALTINDAKİ KASA", "desc": "Kuzeyde buzun karnına gömülü bir kasa var — Buz Anası'nın sesi mührü tutuyordu. Onu düşür; kasa yolunun buzu erisin.", "obj": {"type": "boss", "k": "buz"}, "rew": {"cho": 340, "node": "buzkasa", "rep": 3}, "prereq": "q_yagmaci"},
	{"id": "q_dev",   "giver": "ahusk",   "name": "BATAKLIĞIN EFENDİSİ","desc": "Bataklığın dibinde bir dev oturuyor — gençliğimde ondan kaçtım, şimdi sen indir. Kalbi sana tılsım olur.", "obj": {"type": "boss", "k": "dev"}, "rew": {"cho": 240, "item": "i_devkalp"}, "prereq": "q_batak"},
	{"id": "q_sarnic","giver": "ahusk",   "name": "SUYUN ALTINDA",      "desc": "Sarnıçların hâlâ dolu olduğunu bilirim — bataklıkta bir tanesi gördüm. Tek koşuda 1600 parçacık getir, girişin yerini çizeyim.", "obj": {"type": "frag", "n": 1600}, "rew": {"cho": 260, "node": "sarnic"}, "prereq": "q_batak"},
	{"id": "q_balcik","giver": "ahusk",   "name": "ÇAMURUN İÇİNDEKİ",   "desc": "Balçıktan yürüyenler kervan yolunu kesiyor — bırakırsan yarası kapanıyor. On tanesini çökert, kalbini sana tılsım yapayım.", "obj": {"type": "kind", "k": "Balçık Adam", "n": 10}, "rew": {"cho": 200, "item": "i_balcikkalp"}, "prereq": "q_sarnic"},
	{"id": "q_sivri", "giver": "ahusk",   "name": "BULUT KESİCİ",       "desc": "Bulut kervanların üstüne çöküyor — kırk sivri kes, kanlarından aşı çıkarayım. Kim bilir, kalbi de kızarsa durma.", "obj": {"type": "kind", "k": "Sivri Bulutu", "n": 40}, "rew": {"cho": 200, "item": "i_sivriasi"}, "prereq": "q_balcik"},
	{"id": "q_fener2","giver": "ahusk",   "name": "FENER IŞIĞI",        "desc": "Bataklığın içinde eğik bir fener hâlâ şarkı söylüyor — eski yolların kılavuzu. Balçıktan yürüyenler kuleyi kuşattı; on ikisini durdur, fenerin yolunu sana göstereyim.", "obj": {"type": "kind", "k": "Balçık Adam", "n": 12}, "rew": {"cho": 200, "node": "batikfener"}, "prereq": "q_sivri"},
	{"id": "q_dokuz", "giver": "zirkon",  "name": "SON DEFTER",        "desc": "Defterde sekiz efendi sayfası var — hepsi düşerse protokolün savaş kısmı biter. Son kapanışta praetorian gövde zırhını veririm.", "obj": {"type": "bosses", "n": 8}, "rew": {"cho": 300, "item": "i_praetorian"}, "prereq": "q_final"},
	{"id": "q_soy",  "giver": "zirkon",  "name": "TÜM SOY",            "desc": "Kaydın eksik — kovanın her soyundan birini görmeden defter kapanmaz. Yirmi bir türü de gözle; kemer takasını yapayım.", "obj": {"type": "kinds", "n": 21}, "rew": {"cho": 260, "item": "i_soykemer"}, "prereq": "q_dokuz"},
	{"id": "q_kuzgun","giver": "saphire", "name": "KUZGUN TÜYÜ",       "desc": "Tarlalarda yeni bir şey dalıyor — tüyleri işlenirse iyi satılır. 12 Tarla Kuzgunu kes, tüyünü kolye yaparım.", "obj": {"type": "kind", "k": "Tarla Kuzgunu", "n": 12}, "rew": {"cho": 180, "item": "i_tuy"}, "prereq": "q_copcu"},
	{"id": "q_boynuz","giver": "saphire", "name": "BOYNUZ TAKASI",      "desc": "Çoraklıkta boynuzlu bir şey insanları devirmiş — koçbaşı sürüsü çizgisine dikkat et. Sekiz Kocboynuz kes, boynuzundan pence yapayım.", "obj": {"type": "kind", "k": "Kocboynuz", "n": 8}, "rew": {"cho": 200, "item": "i_boynuz"}, "prereq": "q_kuzgun"},
	{"id": "q_yuk",   "giver": "zirkon",  "name": "YÜK USTASI",         "desc": "Aşırı yük motoru ısınmadan öğrenilmez — deftere 15 yakma kaydı düş, kayışını takayım.", "obj": {"type": "over", "n": 15}, "rew": {"cho": 240, "item": "i_sarj"}, "prereq": "q_soy"},
	{"id": "q_avlu",  "giver": "ehnar",   "name": "AVLU SINAVI",        "desc": "Efendi Avlusu'nda altı efendi arka arkaya nöbet tutar — zincirin tamamını tek koşuda kes, penceyi takas ederim.", "obj": {"type": "won_node", "id": "avlis", "n": 1}, "rew": {"cho": 280, "item": "i_efendipence"}, "prereq": "q_kor"},
	{"id": "q_kutuk", "giver": "neva",    "name": "SEKİZ KÜTÜK",        "desc": "Saha eski defterini dağıttı — sekiz kütük var, hepsi sende toplanırsa sessiz çizmeyi söylerim.", "obj": {"type": "kayit", "n": 8}, "rew": {"cho": 200, "item": "i_kozcizme"}, "prereq": "q_vatika"},
	{"id": "q_koz",   "giver": "neva",    "name": "KADER KOLEKSİYONU",   "desc": "Kader kartları şarkının notaları — her biri başka bir geleceği dener. Yirmi farklı kozu koşularda yak; koleksiyon defterime eklensin.", "obj": {"type": "koz", "n": 20}, "rew": {"cho": 320, "rep": 3}, "prereq": "q_kutuk"}, 
	{"id": "q_nuve",  "giver": "ahusk",   "name": "DAMARIN ÇEYİZİ",    "desc": "Damar kıran iyi beslenir — on damar kır, nüve halkasını takarım.", "obj": {"type": "vein", "n": 10}, "rew": {"cho": 220, "item": "i_nuve"}, "prereq": "q_balcik"},
	{"id": "q_govde","giver": "david",   "name": "HER GÖVDE BİR DERS",  "desc": "Ely'nin kasası tek başına kovanı yormaz — her şasi ayrı ders. Üç farklı gövdeyle zafer kazan; hangi şasiyle dönersen dön, seni bekleyen şeyi çizim yapayım.", "obj": {"type": "heros", "n": 3}, "rew": {"cho": 300, "item": "i_ikiz"}, "prereq": "q_gez"},
	{"id": "q_sefer", "giver": "david",   "name": "SEFER KOMUTANI",      "desc": "Zafer tek düğümle bitmez — zaferin sıcağında bir sonraki düğüme yürümek seferdir. Üç ayaklık bir zincir kur; müfrete geleneği senin adınla yazılır.", "obj": {"type": "sefer", "n": 3}, "rew": {"cho": 340, "rep": 4}, "prereq": "q_anil"},
	{"id": "q_muhur12","giver": "zirkon", "name": "ON İKİNCİ MÜHÜR",     "desc": "Kamp itibarının ardı arkası kesilmez — defterde bir sayfa daha var, ama sadece tanınan ellere açılır. Beyaz Ufuk'u fethet, protokolün kuzeyini kapayalım.", "obj": {"type": "won_node", "id": "beyazufuk", "n": 1}, "rew": {"cho": 500, "rep": 4}, "req_rep": 10},
	{"id": "q_orun",  "giver": "orun",   "name": "NABIZ AVCISI",         "desc": "Kafesten çıktım ama nabız kulağımda duruyor — koronun işaretlediği düğümde zafer kazan, davulunu sustur.", "obj": {"type": "baskin", "n": 1}, "rew": {"cho": 150, "rep": 2}},
	{"id": "q_orun2", "giver": "orun",   "name": "ÇANIN İZİ",            "desc": "Davul sustu ama çan hâlâ yürüyor — üç baskının altında daha zafer kazan, koro yön değiştirsin.", "obj": {"type": "baskin", "n": 3}, "rew": {"cho": 260, "rep": 3}, "prereq": "q_orun"},
	{"id": "q_orun3", "giver": "orun",   "name": "YOL YOLDAŞI",           "desc": "Kafesten çıkanlar yollarda erzak taşır — kulakları bende ama elleri sende. Üç yoldaş karşılaşması geçir; onların sana bıraktıklarını say, haber ağının kıymetini gör.", "obj": {"type": "cameo", "n": 3}, "rew": {"cho": 280, "rep": 3}, "prereq": "q_orun2"}, 
	{"id": "q_orun4", "giver": "orun",   "name": "FIRTINANIN GÖZÜ",        "desc": "Çölde kum fırtınası düşerken koronun gözü kör olur — o yedi saniye avlanma vaktidir. Fırtına eserken yirmi beş kesim yap; sana rüzgâr okumanın tılsımını vereyim.", "obj": {"type": "firtina", "n": 25}, "rew": {"cho": 300, "item": "i_firtina", "rep": 3}, "prereq": "q_orun3"}, 
	{"id": "q_bahis2", "giver": "tegan",  "name": "SİMSARIN SON BAHİSİ", "desc": "Büyük masa büyük bahis ister — ama teklifi herkese açmam. Tek koşuda 6000 skor: tüm kasa senin.", "obj": {"type": "score", "n": 6000}, "rew": {"cho": 400, "item": "i_cengel"}, "req_rep": 6},
	{"id": "q_anit",  "giver": "ehnar",   "name": "ANIT NÖBETİ",         "desc": "Kül tepesinde bir anıt var — kovan oraya saygı duruşuna geliyor. Tek koşuda 500 kesim yaparsan girişi gösteririm.", "obj": {"type": "kills", "n": 500}, "rew": {"cho": 200, "node": "koranit"}, "prereq": "q_kul"},
	{"id": "q_pence", "giver": "saphire", "name": "KOR PENCELER",        "desc": "Külde yürüyen askerler var — pençeleri hâlâ kor gibi yanıyor. On iki Kor Pençe kes; külünden bir kolye döveyim.", "obj": {"type": "kind", "k": "Kor Pençe", "n": 12}, "rew": {"cho": 200, "item": "i_korkul"}, "prereq": "q_anit"},
	{"id": "q_kor",   "giver": "ehnar",   "name": "KÜLLERİN EFENDİSİ",  "desc": "Kül Ovası'nda son efendi oturuyor — imparatorluğunun tahtı hâlâ yanıyor. Kor Yücelten'i düşür; tacını sana miğfer yaparım.", "obj": {"type": "boss", "k": "kor"}, "rew": {"cho": 240, "item": "i_kortac"}, "prereq": "q_kul"},
	{"id": "q_duvar", "giver": "ehnar",   "name": "ESKİ MUHAFIZIN YEMİNİ","desc": "Kalkan kasasını duydum — K-7, benim devriyemin duvar serisiydi. O gövdeyle bir zafer getir; yemin plakasını zırhına işlerim.", "obj": {"type": "hero_won", "id": "k7", "n": 1}, "rew": {"cho": 260, "item": "i_duvar"}},
	{"id": "q_karne", "giver": "mina",    "name": "İKSİR KARNESİ",        "desc": "Şifa içecek şişe değil, disiplin ister. Altı iksir iç — karneni ocak defterine işlerim.", "obj": {"type": "iksir", "n": 6}, "rew": {"cho": 140, "item": "i_kemer_par"}, "prereq": "q_sofra"},
	{"id": "q_sofra", "giver": "mina",    "name": "SOFRANIN BEREKETİ",    "desc": "Sahada düşen her şifa küresi ocak için malzeme — on beşini topla, senin için saklarım.", "obj": {"type": "sifa", "n": 15}, "rew": {"cho": 160, "item": "i_cevher"}},
	{"id": "q_ziyafet","giver": "mina",   "name": "KURTULUŞ ZİYAFETİ",    "desc": "Büyük sofra büyük malzeme ister. Otuz küre daha — karşılığında damlayı veririm, seni geri getirir.", "obj": {"type": "sifa", "n": 30}, "rew": {"cho": 320, "item": "i_neva"}, "prereq": "q_sofra"},
]

# states in meta.data["quests"]: qid -> {"st": "act"|"done"|"claimed", "prog": int}
static func _q() -> Dictionary:
	if not G.meta.data.has("quests"):
		G.meta.data["quests"] = {}
	return G.meta.data["quests"]

static func state(id: String) -> String:
	var st := str(_q().get(id, {}).get("st", ""))
	# meta-seviye objektifler (eşya teslimi, kütük toplama) tembel kontrol edilir —
	# koşu dışında da ilerleyebildikleri için state() okurken tamamlanmayı denetler
	if st == "act":
		var q := def(id)
		var t := str(q.obj.get("type", ""))
		var cur := -1
		if t == "item":
			cur = _item_count(str(q.obj.get("id", "")))
		elif t == "kayit":
			cur = (G.meta.data.get("lore", []) as Array).size()
		elif t == "nodes":
			cur = (G.meta.data.get("won_nodes", []) as Array).size()
		elif t == "bosses":
			cur = (G.meta.data.get("bosses", []) as Array).size()
		elif t == "kinds":
			cur = (G.meta.data.get("seen_kinds", []) as Array).size()
		elif t == "won_node":
			cur = 1 if (G.meta.data.get("won_nodes", []) as Array).has(str(q.obj.get("id", ""))) else 0
		elif t == "over":
			cur = int(G.meta.data.get("over_uses", 0))
		elif t == "keg":
			cur = int(G.meta.data.get("keg_kills", 0))
		elif t == "geo":
			cur = int(G.meta.data.get("geodes", 0))
		elif t == "bets":
			cur = int(G.meta.data.get("bets_won", 0))
		elif t == "heros":
			cur = (G.meta.data.get("hero_wins", {}) as Dictionary).size()
		elif t == "hero_won":
			cur = int((G.meta.data.get("hero_wins", {}) as Dictionary).get(str(q.obj.get("id", "")), 0))
		if cur >= 0:
			_q()[id]["prog"] = maxi(prog(id), cur)
		if cur >= int(q.obj.get("n", 1)):
			_q()[id]["st"] = "done"
			st = "done"
			G.meta.save()
	return st

static func _item_count(iid: String) -> int:
	var n := 0
	for v in (G.meta.data.get("stash", []) as Array):
		if str(v) == iid:
			n += 1
	for s in (G.meta.data.get("equip", {}) as Dictionary).values():
		if str(s) == iid:
			n += 1
	return n

static func prog(id: String) -> int:
	return int(_q().get(id, {}).get("prog", 0))

static func def(id: String) -> Dictionary:
	for q in DEFS:
		if q.id == id:
			return q
	return {}

static func available_for(nid: String) -> Array:
	var out: Array = []
	for q in DEFS:
		if q.giver != nid:
			continue
		if state(q.id) != "":
			continue
		var pre := str(q.get("prereq", ""))
		if pre != "" and state(pre) != "claimed":
			continue
		# itibar kapısı: kampın güvenini kazanmadan sunulmayan görevler
		if int(q.get("req_rep", 0)) > int(G.meta.data.get("rep", 0)):
			continue
		out.append(q)
	return out

# quests this NPC can take back: done but unclaimed
static func claimable_for(nid: String) -> Array:
	var out: Array = []
	for q in DEFS:
		if q.giver == nid and state(q.id) == "done":
			out.append(q)
	return out

static func active() -> Array:
	var out: Array = []
	for q in DEFS:
		if state(q.id) == "act":
			out.append(q)
	return out

# quests this NPC gave that are still being worked
static func active_for(nid: String) -> Array:
	var out: Array = []
	for q in DEFS:
		if q.giver == nid and state(q.id) == "act":
			out.append(q)
	return out

# anything to talk about: new offer, live progress, or a claimable reward
static func has_business(nid: String) -> bool:
	if nid == "ehnar":
		for b in daily():
			if not bool(b.get("done", false)):
				return true
	return not (available_for(nid).is_empty() and claimable_for(nid).is_empty() and active_for(nid).is_empty())

# ---------- günlük ihaleler ----------
# Tarih-seed'li 2 küçük kontrat; koşu bitiminde (tick_all) değerlendirilir.
# stats okumaları tick() match'i ile aynı tutulur.
const BOUNTY_DEFS := [
	{"type": "kills",  "n": 250, "desc": "tek koşuda 250 kesim",        "cho": 80},
	{"type": "elites", "n": 8,   "desc": "tek koşuda 8 elit kes",        "cho": 90},
	{"type": "time",   "n": 480, "desc": "tek koşuda 8 dakika dayan",    "cho": 100},
	{"type": "loot",   "n": 3,   "desc": "tek koşuda 3 ganimet topla",   "cho": 90},
	{"type": "score",  "n": 3500,"desc": "tek koşuda 3500 skor",        "cho": 110},
	{"type": "win",    "n": 1,   "desc": "herhangi bir düğümde zafer",   "cho": 120},
	{"type": "kind",   "k": "Taret",         "n": 6, "desc": "tek koşuda 6 Taret sök",        "cho": 80},
	{"type": "kind",   "k": "Kor Pençe",     "n": 8, "desc": "tek koşuda 8 Kor Pençe kes",    "cho": 110},
	{"type": "kind",   "k": "Gözetmen",      "n": 8, "desc": "tek koşuda 8 Gözetmen düşür",   "cho": 100},
	{"type": "kind",   "k": "Balçık Adam",   "n": 8, "desc": "tek koşuda 8 Balçık Adam erit", "cho": 100},
	{"type": "vein",   "n": 4,   "desc": "tek koşuda 4 choralim damarı kır", "cho": 90},
	{"type": "champ",  "n": 1,   "desc": "tek koşuda 1 şampiyon kes",    "cho": 130},
]

static func daily() -> Array:
	var today := Time.get_date_string_from_system()
	var d: Dictionary = G.meta.data.get("daily", {})
	if str(d.get("date", "")) != today:
		var pool := BOUNTY_DEFS.duplicate()
		var list: Array = []
		for i in 2:
			var i2 := (hash(today) + i * 7919) % pool.size()
			var b: Dictionary = pool[i2].duplicate()
			pool.remove_at(i2)
			b["done"] = false
			list.append(b)
		d = {"date": today, "list": list}
		G.meta.data["daily"] = d
		G.meta.save()
	return d.get("list", [])

static func _bounty_cur(b: Dictionary) -> int:
	match str(b.get("type", "")):
		"kills":  return int(G.run.stats.get("kills", 0))
		"elites": return int(G.run.stats.get("elite_kills", 0))
		"time":   return int(G.run.time)
		"loot":   return (G.run.stats.get("loot", []) as Array).size()
		"score":  return int(G.run.stats.get("score", 0))
		"win":    return 1 if bool(G.run.stats.get("won", false)) else 0
		"kind":   return int(G.run.stats.get("kind_kills", {}).get(str(b.get("k", "")), 0))
		"vein":   return int(G.run.stats.get("veins", 0))
		"champ":  return int(G.run.stats.get("champ_kills", 0))
	return 0

# koşu sonunda (tick_all içinden) — tutan ihaleler choralim öder
static func daily_check() -> void:
	if G.run == null:
		return
	var hit := false
	for b in daily():
		if bool(b.get("done", false)):
			continue
		if _bounty_cur(b) >= int(b.get("n", 1)):
			b["done"] = true
			hit = true
			G.meta.add_choralim(int(b.get("cho", 0)))
			if is_instance_valid(G.ui):
				G.ui.toast("İHALE TUTTU — %s  (◆ +%d)" % [str(b.get("desc", "")), int(b.get("cho", 0))])
	if hit:
		G.meta.save()

# koşu sonunda kalan tüm objektif tiplerini son durumla değerlendir
static func tick_all() -> void:
	var done: Array = []
	for type in ["kills", "time", "elites", "evos", "loot", "biomes", "win", "score", "frag", "quests", "item", "kayit", "champ", "vein", "nodes", "sefer", "koz"]:
		done.append_array(tick(type))
	daily_check()
	for q in DEFS:
		if state(q.id) != "act" or str(q.obj.get("type", "")) != "boss":
			continue
		var need := str(q.obj.get("k", ""))
		if (G.meta.data.get("bosses", []) as Array).has(need):
			_q()[q.id]["st"] = "done"
			_q()[q.id]["prog"] = 1
			done.append(q)
	for q in DEFS:
		if state(q.id) != "act" or str(q.obj.get("type", "")) != "kind":
			continue
		var kk: Dictionary = G.run.stats.get("kind_kills", {})
		var cur := int(kk.get(str(q.obj.k), 0))
		_q()[q.id]["prog"] = cur
		if cur >= int(q.obj.get("n", 1)):
			_q()[q.id]["st"] = "done"
			done.append(q)
	if not done.is_empty():
		G.meta.save()
		_announce(done)

static func _announce(done_now: Array) -> void:
	for q in done_now:
		if is_instance_valid(G.ui):
			G.ui.toast("GÖREV TAMAM: %s — %s yanına dön" % [str(q.name), str(NPC.NAMES.get(str(q.giver), str(q.giver)))])
			G.audio.jingle("boon")

static func accept(id: String) -> void:
	_q()[id] = {"st": "act", "prog": 0}
	G.meta.save()

static func abandon(id: String) -> void:
	_q().erase(id)
	G.meta.save()

# live progress — called from run hooks; returns quests that just finished
static func tick(type: String, arg := "", n := 1) -> Array:
	var done_now: Array = []
	for q in DEFS:
		if state(q.id) != "act":
			continue
		var o: Dictionary = q.obj
		if str(o.type) != type:
			continue
		if str(o.get("k", "")) != "" and arg != str(o.k):
			continue
		# boss/biomes check absolute values, not increments
		var need := int(o.get("n", 1))
		var cur: int
		match type:
			"kills":   cur = int(G.run.stats.get("kills", 0))
			"kind":    cur = int(G.run.stats.get("kind_kills", {}).get(arg, 0))
			"time":    cur = int(G.run.time)
			"elites":  cur = int(G.run.stats.get("elite_kills", 0))
			"evos":    cur = int(G.run.stats.get("evos", 0))
			"loot":    cur = (G.run.stats.get("loot", []) as Array).size()
			"win":     cur = 1 if bool(G.run.stats.get("won", false)) else 0
			"biomes":  cur = (G.meta.data.get("visited", []) as Array).size()
			"nodes":   cur = (G.meta.data.get("won_nodes", []) as Array).size()
			"score":   cur = int(G.run.stats.get("score", 0))
			"frag":    cur = int(G.run.fragments)
			"quests":  cur = _claimed_count()
			"item":    cur = _item_count(str(o.get("id", "")))
			"champ":   cur = int(G.run.stats.get("champ_kills", 0))
			"sefer":   cur = int(G.run.stats.get("sefer", 0))
			"kayit":   cur = (G.meta.data.get("lore", []) as Array).size()
			"koz":     cur = (G.meta.data.get("arcanas_seen", []) as Array).size()
			_:         cur = prog(q.id) + n
		_q()[q.id]["prog"] = maxi(prog(q.id), cur)
		if cur >= need:
			_q()[q.id]["st"] = "done"
			done_now.append(q)
	if not done_now.is_empty():
		G.meta.save()
		_announce(done_now)
	return done_now

# kamp itibarı — BG2 tarzı: görevler kampın gözündeki yerini yükseltir;
# kademe (tier) koşu ödemesine küçük bir çarpan olarak döner
const REP_TIERS := [0, 8, 20, 40, 65]
const REP_NAMES := ["YABANCI", "TANINAN", "GÜVENİLİR", "KAHRAMAN", "EFSANE"]

static func rep() -> int:
	return int(G.meta.data.get("rep", 0))

static func rep_tier() -> int:
	var r := rep()
	var t := 0
	for i in REP_TIERS.size():
		if r >= REP_TIERS[i]:
			t = i
	return t

static func rep_name() -> String:
	return REP_NAMES[rep_tier()]

# kamp itibarı fiyat indirimi: katman başına %4 (EFSANE'de %16)
static func rep_discount() -> float:
	return 1.0 - 0.04 * rep_tier()

static func rep_price(x: int) -> int:
	return maxi(1, int(round(float(x) * rep_discount())))

static func rep_mult() -> float:
	return 1.0 + 0.05 * rep_tier()

static func claim(id: String) -> Dictionary:
	if state(id) != "done":
		return {}
	var q := def(id)
	_q()[id]["st"] = "claimed"
	var rew: Dictionary = q.get("rew", {})
	var t0 := rep_tier()
	G.meta.data["rep"] = rep() + int(rew.get("rep", 1))
	if rep_tier() > t0 and is_instance_valid(G.ui):
		G.ui.toast("kamp itibarın yükseldi: %s  (ödeme +%d%%)" % [rep_name(), int(rep_tier() * 5)])
	if int(rew.get("cho", 0)) > 0:
		G.meta.data["choralim"] = int(G.meta.data.get("choralim", 0)) + int(rew.cho)
	if str(rew.get("item", "")) != "":
		var st: Array = G.meta.data.get("stash", [])
		if not st.has(str(rew.item)):
			st.append(str(rew.item))
		G.meta.data["stash"] = st
	if str(rew.get("node", "")) != "":
		var un: Array = G.meta.data.get("unlocked", [])
		if not un.has(str(rew.node)):
			un.append(str(rew.node))
		G.meta.data["unlocked"] = un
	# eşya teslimi görevi: müşteriye giden parça stoğu/equipten düşer
	if str(q.obj.get("type", "")) == "item":
		var iid := str(q.obj.get("id", ""))
		var st2: Array = G.meta.data.get("stash", [])
		if st2.has(iid):
			st2.erase(iid)
		else:
			var eq: Dictionary = G.meta.data.get("equip", {})
			for sl in eq:
				if str(eq[sl]) == iid:
					eq.erase(sl)
					break
			G.meta.data["equip"] = eq
		G.meta.data["stash"] = st2
	if str(rew.get("wep", "")) != "":
		var wu: Array = G.meta.data.get("wep_unlocked", [])
		if not wu.has(str(rew.wep)):
			wu.append(str(rew.wep))
		G.meta.data["wep_unlocked"] = wu
	G.meta.save()
	return rew

static func rew_text(rew: Dictionary) -> String:
	var parts: Array = []
	if int(rew.get("cho", 0)) > 0:
		parts.append("◆ %d choralim" % int(rew.cho))
	if str(rew.get("item", "")) != "":
		parts.append("eşya: %s" % str(Items.DEFS.get(str(rew.item), {}).get("name", rew.item)))
	if str(rew.get("node", "")) != "":
		parts.append("yeni bölge açıldı")
	if str(rew.get("wep", "")) != "":
		parts.append("silah: %s" % str(Weapons.DEFS.get(str(rew.wep), {}).get("name", rew.wep)))
	if rew.get("cine") is Array and not (rew["cine"] as Array).is_empty():
		parts.append("anı kaydı")
	parts.append("itibar +%d" % int(rew.get("rep", 1)))
	return " + ".join(parts)

static func obj_text(q: Dictionary) -> String:
	var o: Dictionary = q.obj
	var need := int(o.get("n", 1))
	match str(o.type):
		"kills":  return "%d kesim" % need
		"kind":   return "%s x%d" % [str(o.k), need]
		"time":   return "%d sn hayatta kal" % need
		"boss":   return "efendi: %s" % str(o.k).to_upper()
		"win":    return "bir zafer"
		"elites": return "%d elit" % need
		"evos":   return "%d evrim" % need
		"loot":   return "%d eşya" % need
		"biomes": return "%d farklı saha" % need
		"score":  return "%d skor" % need
		"frag":   return "%d parçacık topla" % need
		"totem":  return "%d deneme totemi tamamla" % need
		"fener":  return "%d sinyal feneri kır" % need
		"vein":   return "%d choralim damarı kır" % need
		"quests": return "%d görev teslim et" % need
		"item":   return "%s getir" % str(Items.DEFS.get(str(o.get("id", "")), {}).get("name", str(o.get("id", ""))))
		"kayit":  return "%d veri kütüğü bul" % need
		"koz":    return "%d farklı koz kartı kullan" % need
		"champ":  return "%d şampiyon elit kes" % need
		"won_node": return "%s fethi" % str(Wmap.node(str(o.get("id", ""))).get("name", str(o.get("id", ""))))
		"sefer":  return "%d ayaklık sefer zinciri" % need
		"over":   return "%d aşırı yük kullan" % need
		"keg":    return "%d kesimi fıçıya saydır" % need
		"geo":    return "%d damar jeotu kır" % need
		"hazine": return "%d hazine düğümü yağmala" % need
		"cameo":  return "%d yoldaş karşılaşması geçir" % need
		"firtina": return "%d kesimi kum fırtınasında yap" % need
		"baskin": return "%d baskın altında zafer" % need
	return "?"

static func _claimed_count() -> int:
	var n := 0
	for qid in _q():
		if str(_q()[qid].get("st", "")) == "claimed":
			n += 1
	return n

static func prog_text(q: Dictionary) -> String:
	var o: Dictionary = q.obj
	var need := int(o.get("n", 1))
	return "%d / %d" % [mini(prog(q.id), need), need]

# ---------------------------------------------------------------- veri kütükleri
# Sahada nadiren düşen kalıcı lore parçaları — meta.data["lore"] listesine yazar,
# Zirkon'un kayıtlarındaki ÖYKÜ codex'inde okunur (BG2 kitap/not sistemi).
const LORE := [
	{"id": "l_protokol", "name": "KÜTÜK: PROTOKOLÜN DOĞUŞU", "txt": "Choralim protokolü bir silah değildi — bir vaatti. Viator ilk praetorianı gömdüğünde rezonans bir daha susmadı."},
	{"id": "l_kovan",    "name": "KÜTÜK: KOVANIN İLKİ",     "txt": "Kovan önce böcek değildi. İmparatorluk savas uşaklarını korozyona saldı; korozyon onları geri gönderdi — değişmiş olarak."},
	{"id": "l_alfa05",   "name": "KÜTÜK: ALFA-05'İN SONU",  "txt": "Beşinci praetorian Endusterra'da düştü. Kraterdeki zırh hâlâ sıcak — kovan cesedine dokunmaya korkuyor."},
	{"id": "l_viator",   "name": "KÜTÜK: VIATOR ANDI",      "txt": "'Kırılan geri döner, dönen tekrar kırılır.' Viator kampı bu andın üstüne kuruldu — ateş hiç sönmez."},
	{"id": "l_simithar", "name": "KÜTÜK: SİMİTHAR",         "txt": "Maden cevheri sadece metal değil — damarların içinde eski imparatorluğun belleği saklı. Kes ve anılar sana akar."},
	{"id": "l_masa",     "name": "KÜTÜK: SON MASA",         "txt": "Efendiler bir masanın etrafında oturur: Rex, Host, Nahum & Tuman, Kirin & Constantin. Boş sandalye sizin için ayrılmış."},
	{"id": "l_neva",     "name": "KÜTÜK: NEVA'NIN ŞARKISI", "txt": "Neva'nın türküsü dua değil, talimattır. Rezonans onu dinler — seni geri getiren o frekans."},
	{"id": "l_sis",      "name": "KÜTÜK: SİS PERDESİ",      "txt": "Batıdaki sis hava değil — bataklığın nefesi. Göçebeler oraya 'duvar' der; kistler içinde şarkı söyler."},
]
