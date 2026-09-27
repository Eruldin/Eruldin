class_name Wmap
extends RefCounted

# BG2-style world map: node graph of areas. Each node is a destination —
# either the camp hub or an arena run with its own biome art, modifiers and
# unlock rule. Travel happens through the map screen (David / world key).

# node def:
#   id, name, icon, pos (map px on 1180x660 space), col
#   biome  — arena art/hazard set to reuse
#   mods   — run modifiers: frag, elite_t (elite interval mult), miniboss, final
#   unlock — "open" | "quest" (meta.unlocked contains id) | "bosses n"
#   desc   — flavor + rule text
const NODES := [
	{"id": "kamp",   "name": "VIATOR KAMPI",      "icon": "ico_camp",    "pos": Vector2(300, 360), "col": "c9a227", "kind": "hub",  "unlock": "open",   "desc": "Son güvenli toprak. NPC'ler, yükseltmeler, görevler."},
	{"id": "b0",     "name": "ENDUSTERRA BARRENS", "icon": "ico_run",     "pos": Vector2(520, 240), "col": "00E5FF", "kind": "arena", "biome": 0, "unlock": "open",   "desc": "Proterian çoraklığı. Efendi: Alfa-05.", "mods": {}},
	{"id": "b1",     "name": "SIMITHAR MINE",      "icon": "icn_mine",    "pos": Vector2(760, 200), "col": "00E676", "kind": "arena", "biome": 1, "unlock": "boss rex","desc": "Simithar damarları. Efendi: Proterian Host.", "mods": {}},
	{"id": "b2",     "name": "SOL PRIMUS ENKAZI",  "icon": "ico_run",     "pos": Vector2(940, 340), "col": "ffb74d", "kind": "arena", "biome": 2, "unlock": "boss host","desc": "İmparatorluk enkazı. Efendiler: Nahum & Tuman.", "mods": {}},
	{"id": "b3",     "name": "AETERNA SPIRE",      "icon": "icn_crown",   "pos": Vector2(760, 520), "col": "c26bff", "kind": "arena", "biome": 3, "unlock": "boss twins","desc": "Protokolün kalbi. Efendiler: Kirin & Constantin.", "mods": {}},
	{"id": "yol",    "name": "PUSLU GEÇİT",        "icon": "icn_dash",    "pos": Vector2(430, 130), "col": "8fd4ff", "kind": "arena", "biome": 1, "unlock": "node", "desc": "Elitler sık doğar, ganimet bol — keşif koşusu.", "lore": "Kervanların kaybolduğu geçit. Sis perdesi arkasında elit sürüler dönüyor — cesareti olan ganimeti kapar.", "mods": {"elite_t": 0.55, "frag": 1.2, "dusk": true}},
	{"id": "tarla",  "name": "YANIK TARLALAR",     "icon": "ico_frag",    "pos": Vector2(600, 430), "col": "ff9e4d", "kind": "arena", "biome": 0, "unlock": "node", "desc": "Kül tarlaları — parçacık bereketi, kovan seyrek.", "lore": "Eski imparatorluğun tahıl ambarı. Küllerin altında hâlâ choralim kristalleri çiçek açıyor.", "mods": {"spawn": 1.25, "frag": 1.5, "hp": 0.85}},
	{"id": "karakol","name": "KIRIK KARAKOL",      "icon": "ico_run",     "pos": Vector2(360, 300), "col": "8fd4ff", "kind": "arena", "biome": 0, "unlock": "node", "desc": "Düşmüş sınır karakolu — sürü seyrek ama devamlı, parçacık bereketli kasılma sahası.", "lore": "Viator'ın batı sınır karakolu — çatısı çöktü, alarmı hâlâ vızıldıyor. Praetorian nöbetçileri burada son mesajlarını kazıdı; kovan enkazı sevdi, parçacıklar çatlaklarda birikti.", "mods": {"spawn": 1.15, "frag": 1.25, "hp": 0.9}},
	{"id": "pazar",  "name": "HURDA PAZARI",       "icon": "ico_boon",    "pos": Vector2(180, 180), "col": "c9a227", "kind": "arena", "biome": 2, "unlock": "node", "desc": "Yıkık çarşı — eşya düşüşü yoğun, sürü zayıf.", "lore": "Tüccarların son durağı. Raflar devrildi ama eşya hâlâ orada — kovanın artıkları arasında.", "mods": {"loot": 2.5, "hp": 0.75, "frag": 0.8}},
	{"id": "kuyu",   "name": "DERİN KUYU",         "icon": "icn_skull",   "pos": Vector2(980, 560), "col": "ff5533", "kind": "arena", "biome": 3, "unlock": "node", "desc": "Aeterna'nın dibi — en sert kovan, en iyi ganimet.", "lore": "Kulenin temel kuyusu. Aşağıda ışık yok; kovanın kalbi burada atıyor. Geri dönüş garanti değil.", "mods": {"hp": 1.5, "dmg": 1.3, "loot": 2.0, "frag": 1.6}},
	{"id": "yuvalar","name": "KOVAN YUVALARI",     "icon": "icn_kovan",   "pos": Vector2(760, 60),  "col": "ff5c5c", "kind": "arena", "biome": 2, "unlock": "node", "desc": "Kovanın üreme ocağı — sürü kesintisiz, frag bereketli.", "lore": "Enkazın altında kovan kuluçkası. Duvarlar nabız atıyor; her çatlaktan yeni bir sürü doğuyor.", "mods": {"spawn": 1.45, "elite_t": 0.8, "frag": 1.4, "hp": 1.1}},
	{"id": "sinyal", "name": "SİNYAL KULESİ",      "icon": "icn_skull",   "pos": Vector2(1080, 200), "col": "4dd0e1", "kind": "arena", "biome": 2, "unlock": "node", "desc": "Enkazın üstünde hâlâ yayın yapan radyo kulesi — sinyali kesmeye gelen elitler sık, ganimet iyi.", "lore": "İmparatorluğun son vericisi; yüzyıldır aynı mesajı döndürüyor: 'hattı tutun'. Kovan sinyali kesmeye gelir, sinyal kesilmez. Kule etrafında elit nöbetçi kalabalığı en yoğun olan yer.", "mods": {"elite_t": 0.6, "spawn": 1.1, "frag": 1.3, "loot": 1.5}},
	{"id": "vatika", "name": "SESSİZ VATİKA",      "icon": "icn_crown",   "pos": Vector2(600, 620), "col": "9be8ff", "kind": "arena", "biome": 3, "unlock": "node", "desc": "Protokolün sessiz sığınağı — alacakaranlık, bol choralim.", "lore": "Neva'nın bahsettiği sığınak. Işık burada ölür ama choralim şarkısı çift yankılanır.", "mods": {"hp": 1.3, "frag": 2.0, "dusk": true, "loot": 1.4}},
	{"id": "mabed",  "name": "KIRILMIŞ MABED",     "icon": "icn_crown",   "pos": Vector2(420, 560), "col": "ffd75f", "kind": "arena", "biome": 0, "unlock": "node", "desc": "Yıkık tapınak — ganimet çift kat, elitler nöbette.", "lore": "Viator'ın eski dua yeri. Sunak kırık ama kutsamalar hâlâ taşın içinde — kovan da bunu biliyor.", "mods": {"loot": 2.2, "elite_t": 0.6, "spawn": 0.8, "frag": 1.2}},
	{"id": "mezarlik","name": "DÜŞMÜŞLER MEZARI",  "icon": "icn_skull",   "pos": Vector2(950, 150), "col": "90a4ae", "kind": "arena", "biome": 3, "unlock": "node", "desc": "Efendilerin eski çöplüğü — elit kaynağı, sert kovan.", "lore": "Protokolün reddettiği gövdeler buraya atıldı. Şimdi hepsi kalkmış, mezarlarında nöbet tutuyor.", "mods": {"hp": 1.25, "elite_t": 0.5, "dmg": 1.15, "frag": 1.35}},
	{"id": "batak",  "name": "ÇÜRÜK BATAKLIK",    "icon": "ico_boon",    "pos": Vector2(1120, 430), "col": "66bb6a", "kind": "arena", "biome": 4, "unlock": "node", "desc": "İmparatorluğun unuttuğu bataklık — çeken balçık, mantarlı karanlık, bol ganimet.", "lore": "Protokol buraya hiç bakmadı; bataklık da kimseyi geri vermedi. Suların altında efendilerin artıkları, üstünde küsen sürüler.", "mods": {"hp": 1.05, "spawn": 1.15, "frag": 1.3, "loot": 1.6, "dusk": true}},
	{"id": "muhkasa","name": "MUHAFIZ KASASI",    "icon": "ico_loot",    "pos": Vector2(610, 130),  "col": "ffd75f", "kind": "hazine","biome": 0, "unlock": "node", "desc": "Karakolun kuzeyinde gömülü praetorian kasası — efendi yok; mühür 6 dakika sonra açılır, içi muhafız teçhizatı.", "lore": "Kırık Karakol'un komutanının son emri: 'kasa benimle gömülsün'. Karakol düştü ama kasa gömüldüğü yerde duruyor — mühür hâlâ praetorian eli tanıyor; seninkini de sayar.", "mods": {"loot": 2.4, "frag": 1.9, "hp": 0.95, "spawn": 1.05, "elite_t": 0.75}},
	# kind "story": savaşsız tek seferlik hikaye durağı — sinematik + ödül, sonra tükenir
	{"id": "kayalik","name": "YANKI KAYASI",        "icon": "icn_skull",   "pos": Vector2(300, 520), "col": "8fd4ff", "kind": "story", "unlock": "open",    "desc": "Kampın güneyinde koro taşı — bir kez dinlenir.", "rew": {"cho": 60},
	 "cards": [
	 	{"tex": "cine_0_1", "title": "YANKI KAYASI", "sub": "Taş, düşen her praetorianın son sinyalini saklar. Parmağını değdir — binlerce yankı aynı anda senin adını söyler."},
	 	{"tex": "por_neva", "title": "NEVA", "sub": "Bunu hissettin değil mi? Kaya korosuna katıldın — artık düşersen bir kaydın var. Parçacıklarını al, git."},
	 ]},
	{"id": "sisgecidi", "name": "SİS GEÇİDİ",      "icon": "icn_dash",    "pos": Vector2(160, 480), "col": "a5d6a7", "kind": "arena", "biome": 4, "unlock": "node", "desc": "Batıdaki sis perdesi — kasılmak isteyenlerin geçidi: sürü bol, frag ve ganimet bereketli.", "lore": "Bataklığın sisi burada duvar gibi. İçinde kistler şarkı söylüyor; göçebe Ahusk bu yolu gençliğinde kaçarak geçti.", "mods": {"spawn": 1.25, "frag": 1.45, "loot": 1.4, "dusk": true}},
	{"id": "sarnic", "name": "BATIK SARNIÇ",      "icon": "ico_frag",    "pos": Vector2(1000, 430), "col": "4a7c59", "kind": "arena", "biome": 4, "unlock": "node", "desc": "Bataklığın yuttuğu su sarnıcı — hazinesi hâlâ içeride, bekçisi de.", "lore": "Efendiler ganimetlerini su altındaki sarnıçlarda saklardı. Bu sarnıç devrildiği gün battı; paraları, küfeleri ve bekçisi birlikte çürüdü. Su artık yaşıyor — içeri gireni sarar.", "mods": {"hp": 1.45, "dmg": 1.2, "spawn": 1.1, "frag": 1.6, "loot": 1.9, "dusk": true}},
	{"id": "gozyuva","name": "SİS GÖZYUVA",       "icon": "ico_loot",    "pos": Vector2(1010, 570), "col": "9ccc65", "kind": "arena", "biome": 4, "unlock": "node", "desc": "Bataklığın sisin en koyu olduğu çukur — hamalların istif yaptığı çamur yuva. Loot bereketli, görüş kısa.", "lore": "Hamal Taşıyıcılar çaldıklarını burada gömer — sis taşınan her sandığın izini örter. Göçebe ataları bu çukura 'gözyuva' dermiş: içine bakan göz, içindeki gözü görmeden ölmezmiş.", "mods": {"spawn": 1.2, "hp": 1.1, "dmg": 1.05, "frag": 1.5, "loot": 1.8, "elite_t": 0.85, "dusk": true}},
	{"id": "avlis",  "name": "EFENDİ AVLISI",   "icon": "icn_crown",   "pos": Vector2(1230, 90),  "col": "ffd75f", "kind": "arena", "biome": 5, "unlock": "boss twins", "desc": "Boss-rush: altı efendi arka arkaya — zincirin sonu zafer.", "lore": "Kirin ve Constantin düştükten sonra açılan arena: protokolün bütün efendileri burada nöbet sırası bekliyor. Altısını da tek koşuda düşür.", "mods": {"rush": 1, "frag": 2.0, "loot": 2.0}},
	{"id": "kulovasi", "name": "KÜL OVASI",        "icon": "icn_mine",    "pos": Vector2(1160, 260), "col": "ff7722", "kind": "arena", "biome": 5, "unlock": "node", "desc": "Praetorian yangınının külü — lav püskürtücüler, kor hücreleri, çok sert kovan.", "lore": "İmparatorluk burasını yakarak temizledi; kül hâlâ sıcak. Yerdeki her çatlak kor saklıyor — kovan ateşi sevdiği için burada en kalını.", "mods": {"hp": 1.55, "dmg": 1.35, "spawn": 1.2, "frag": 1.7, "loot": 1.8}},
	{"id": "koranit","name": "KOR ANITI",        "icon": "icn_skull",   "pos": Vector2(1090, 100), "col": "ff6e40", "kind": "arena", "biome": 5, "unlock": "node", "desc": "Kül Ovası'nın tepesinde efendi külleriyle örülü anıt — kor nabzı sürüyü keskinleştirir, külleri verimli.", "lore": "Praetorian yangınının ilk kurbanları için dikilmiş. Anıt hâlâ sıcak; kül etrafında döner, kovan başında nöbet tutar. Tepede yanan şey sönmedi — sadece bekliyor.", "mods": {"hp": 1.4, "dmg": 1.3, "elite_t": 0.7, "frag": 1.8, "loot": 1.7, "dusk": true}},
	{"id": "kaos",   "name": "KAOS DAMARI",       "icon": "icn_skull",   "pos": Vector2(1240, 620), "col": "ff5cff", "kind": "arena", "biome": 7, "unlock": "node", "desc": "Kararsız choralim damarı — her koşu başka bir mutasyonla sızıyor.", "lore": "Çukurun güney ucunda protokolün okuyamadığı bir damar atıyor: aynı yere iki kez aynı koşu yapılmaz. Kovan da kestiremiyor — sürüsü bazen zırhlı, bazen seyrek, ganimeti hep fazla.", "mods": {"kaos": true, "frag": 1.3}},
	{"id": "yemin",   "name": "YEMİN DARESİ",      "icon": "icn_skull",   "pos": Vector2(330, 660),  "col": "ff3355", "kind": "arena", "biome": 3, "unlock": "node", "desc": "Eski praetorian yemini — şifa küresi düşmez, tek yaşamla sınanırsın; bedeli çift öder.", "lore": "Viator'ın en eski meydan okuması: hiçbir yankı sana küre taşımayacak. Geçersen darénin haracı krallık ölçeğindedir.", "mods": {"noheal": true, "hp": 1.25, "dmg": 1.2, "frag": 2.2, "loot": 1.5}},
	{"id": "krater", "name": "DÜŞÜK KRATER",       "icon": "icn_mine",    "pos": Vector2(860, 650), "col": "ffb74d", "kind": "story", "unlock": "boss rex","desc": "İlk efendinin düştüğü yerde bir krater — içinde hâlâ ışık yanıyor. Zırh parçaları kratere saçılmış; küller huzursuz.", "choices": [
		{"label": "PARLAYANI AL — krateri sömür", "sub": "Kor parçalar choralim değerinde — ama efendinin külleri huzursuz: sonraki koşun biraz daha sert geçer.", "rew": {"cho": 180, "omen": {"dmg": 1.08, "frag": 1.2}, "cine": [
			{"tex": "cine_0_2", "title": "DÜŞÜK KRATER", "sub": "Alfa-05 burada düştü. Kraterin dibinde henüz çürümemiş bir zırh parçası duruyor — kovan bile ona dokunmamış."},
			{"tex": "por_rhasa", "title": "RHASA", "sub": "Onun parçasını taşıyorsun artık. Kraterin kenarında bir şey parlıyor — al ve git, koku burada da sürer."},
		]}},
		{"label": "KÜLLERİ ÖRT — ona yalnızlık bırak", "sub": "Efendi buraya düşmeden önce de bir müfretenin parçasıydı. Külü ört, izcilik geleneğini sürdür.", "rew": {"cho": 60, "rep": 2, "item": "i_palto", "cine": [
			{"tex": "cine_0_2", "title": "KÜL ÖRTÜLDÜ", "sub": "Kratere bir taş diktin — yazı yok, sadece izci nişanı. Bir parçan burada rahat buldu."},
			{"tex": "por_rhasa", "title": "RHASA", "sub": "Bunu yapmak zorunda değildin. Müfrete bunu unutmaz."},
		]}},
	]},
	{"id": "tasocagi","name": "ÇATLAK OCAK",       "icon": "icn_mine",    "pos": Vector2(560, 70),  "col": "ffab91", "kind": "arena", "biome": 1, "unlock": "node", "desc": "Çatlakların altında ocak — elit kaynağı, kovan kesintisiz.", "lore": "Simithar'ın ilk ocağı; damarın çatlağı hâlâ yanıyor. Elitler çatlağın nabzını nöbet tutar gibi koruyor.", "mods": {"elite_t": 0.5, "spawn": 1.1, "dmg": 1.1, "loot": 1.3, "frag": 1.1}},
	{"id": "kum",     "name": "KIZIL ÇÖL",        "icon": "ico_run",     "pos": Vector2(70, 300),  "col": "e8a050", "kind": "arena", "biome": 6, "unlock": "node", "desc": "Kızıl kum denizi — çölayan varl sürüleri, kum fırtınaları, seyrek ama sert kovan.", "lore": "İmparatorluk haritalarında burası boş bırakılmış — 'kızıl' denip geçilmiş. Kumun altında choralim kaktüsleri çiçek açıyor; varller izlerini rüzgâra gömer.", "mods": {"spawn": 0.9, "hp": 1.2, "dmg": 1.1, "frag": 1.5, "loot": 1.2}},
	{"id": "sondurme","name": "SÖNDÜRÜLMÜŞ FIRIN",  "icon": "ico_frag",    "pos": Vector2(1120, 640), "col": "b0bec5", "kind": "story", "unlock": "boss twins","desc": "İmparatorluğun son fırını — gövdesi soğuk, içi hâlâ dolu.", "lore": "Efendiler burada dövüldü. Fırın söndü ama korları — içlerinde kilitli bir Hisar Kalkanı, kovanın eli değmemiş halde.", "choices": [
		{"label": "FIRINI KURTAR — kalkanı al", "sub": "Hisar Kalkanı korlarda bekliyor — ama fırını açmak külü havalandırır: sonraki koşunda sürü biraz daha yoğun.", "rew": {"cho": 140, "item": "i_hisar", "omen": {"spawn": 1.12, "frag": 1.15}, "cine": [{"tex": "cine_5_0", "title": "FIRIN AÇILDI", "sub": "Korların arasından bir kalkan çıkardın — hâlâ dövülmüş metal sıcaklığında. Küller kabardı, sonra duruldu."}]}},
		{"label": "KAPAĞI MÜHÜRLE — fırın sönsün", "sub": "Bazı korlar kapalı kalmalı. Kalkanı bırakırsın ama fırın bir daha açılmaz — kamp bunu duyar.", "rew": {"cho": 90, "rep": 2, "cine": [{"tex": "cine_5_0", "title": "FIRIN MÜHÜRLENDİ", "sub": "Kapağı kapadın, külü düzledin. Efendilerin ocağı artık sadece taş — ve sende bir sessizlik payı var."}]}},
	]},
	{"id": "fisilti", "name": "FISILTI SARNICI",   "icon": "icn_kovan",   "pos": Vector2(90, 640),  "col": "e8a050", "kind": "story", "unlock": "node", "desc": "Kızıl Çöl'ün dibinde gömülü sarnıç — duvarları hâlâ fısıldıyor.", "lore": "Su taşıyanlar buraya susuzluktan değil, sesten kaçmak için indi. Sarnıç Koro'nun ilk prova odasıydı — her damla aynı notayı tekrarlıyor.", "choices": [
		{"label": "SUDAN İÇ — damlayı kutsasın", "sub": "Choralim suyu keseni besler — ama sarnıç içmeyi duyar; Koro'nun ilk prova odası seni ezberler. Sonraki koşunda sürü sık akar.", "rew": {"cho": 220, "omen": {"spawn": 1.1, "frag": 1.25}, "cine": [{"tex": "cine_6_0", "title": "FISILTI SARNICI", "sub": "Duvarlardaki çatlaklardan aynı üç hece: KA-LI-NA. Kum bile ezberledi. Sen içince bir hece daha eklendi: SEN."}]}},
		{"label": "NOTA EZBERLE — duvarları oku", "sub": "İçme — sadece dinle. Suyun aynı üç hecesi prova notasıdır; kampta söylemeye değer.", "rew": {"cho": 80, "rep": 2, "cine": [{"tex": "cine_6_0", "title": "ÜÇ HECE", "sub": "KA-LI-NA. Yüz yıl duvarlara çizildi; ilk kez dinleyen biri oldu. Sarnıç biraz daha az fısıldıyor."}]}},
	]},
	{"id": "vaha",   "name": "SESSİZ VAHA",        "icon": "ico_frag",    "pos": Vector2(40, 470),  "col": "5eead4", "kind": "arena", "biome": 6, "unlock": "node", "desc": "Çölün tek yeşilliği — şifa küreleri bol düşer, kovan yavaş ama sert.", "lore": "Kızıl kumun altında sığ bir akifer — choralim suyu. Kaktüsler burada daha uzun, varller daha sabırlı. Kim konaklarsa iyileşir; kim kalırsa gömülür.", "mods": {"spawn": 0.8, "hp": 1.25, "heal": 2.5, "frag": 1.4, "loot": 1.1}},
	{"id": "batik",  "name": "ÇÖL BATIĞI",         "icon": "ico_loot",    "pos": Vector2(150, 585), "col": "c8a860", "kind": "arena", "biome": 6, "unlock": "node", "desc": "Kuma gömülü imparatorluk kervan gemisi — ganimet zengin, akrep yuvası.", "lore": "Viator göçünün en büyük kazası: yedi kervan tek fırtınada gömüldü. Güverte hâlâ kumun üstünde; ambarlar hâlâ dolu. Akrepler lojmayı yuva yaptı — yükü alan, iğneyi de alır.", "mods": {"spawn": 0.85, "hp": 1.4, "dmg": 1.15, "frag": 1.35, "loot": 1.6, "elite_t": 0.8}},
	{"id": "degirmen","name": "YEL DEĞİRMENLERİ",    "icon": "icn_dash",    "pos": Vector2(235, 415), "col": "d8c56a", "kind": "arena", "biome": 6, "unlock": "node", "desc": "Kum denizinde duran antik yel değirmenleri — rüzgâr hâlâ dönüyor, sürü onunla geliyor.", "lore": "Kızıl Çöl kurumadan önce bu değirmenler kumu un ederdi. Kanatları hâlâ dönüyor; her dönüş bir sürüyü buraya sürüklüyor — akrepler gölgelerinde yuva yaptı.", "mods": {"spawn": 1.2, "hp": 1.2, "dmg": 1.05, "frag": 1.4, "loot": 1.3, "elite_t": 0.9}},
	{"id": "kervansaray","name": "GÖMÜLÜ KERVANSARAY","icon": "ico_loot",   "pos": Vector2(330, 560), "col": "ffd75f", "kind": "hazine","biome": 6, "unlock": "node", "desc": "Kumun altında gömülü han — efendi yok; mahzen 6 dakika sonra açılır, bütün iş yağmalamak.", "lore": "Tegan'ın kayıp kervanının son durağı — fırtına hanı yutmuş ama mahzenler hâlâ dolu. Kapıyı tutan bir nöbetçi yok; kasanın kilidi zamana bağlı.", "mods": {"loot": 2.6, "frag": 2.0, "hp": 0.9, "spawn": 1.1, "elite_t": 0.7}},
	{"id": "madenkasa","name": "MADEN KASASI", "icon": "ico_loot",   "pos": Vector2(690, 310), "col": "ffd75f", "kind": "hazine","biome": 1, "unlock": "node", "desc": "Simithar'ın mühürlü deposu — efendi yok; kasa 6 dakika sonra çözülür, içi ganimet dolu.", "lore": "İmparatorluk madeni boşaltırken kilitleyip gittiği depo. Mühür mekanik — geri sayım bittiğinde kapı kendinden açılır; o ana dek kasanın bekçisi yok, sadece kovanın merakı var.", "mods": {"loot": 2.4, "frag": 1.9, "hp": 1.0, "spawn": 1.15, "elite_t": 0.8}},
	{"id": "korkasa", "name": "KOR KASASI",     "icon": "ico_loot",   "pos": Vector2(1245, 175), "col": "ff9e4d", "kind": "hazine","biome": 5, "unlock": "node", "desc": "Kül Ovası'nın yanık mahzeni — efendi yok; kasa 6 dakika sonra açılır, içi küle gömülü ganimet.", "lore": "Praetorian yangını burayı da yuttu — ama kasayı değil. Kor zemin mahzeni sıcak tutuyor; içeridekiler külün altında hâlâ sayılabilir durumda. Kovan külleri eşeler ama kasaya dokunamaz: mühür ısıyla besleniyor.", "mods": {"loot": 2.5, "frag": 2.1, "hp": 1.15, "spawn": 1.1, "elite_t": 0.75}},
	{"id": "cukur",  "name": "KRİSTAL ÇUKUR",       "icon": "icn_mine",    "pos": Vector2(1210, 560), "col": "4dd0e1", "kind": "arena", "biome": 7, "unlock": "node", "desc": "Aeterna'nın altındaki kristal kuyu — ham choralim damarları, süzülen gözler, dibinde atan bir kalp.", "lore": "Kule temelinin altına inen tek yol burası — ve buraya inenler 'damarların şarkısı yukarıdan daha gürültülü' diyor. Gözetmenler çukurun üstünde dönüyor; kimse nedenini bilmiyor.", "mods": {"frag": 1.7, "loot": 1.5, "hp": 1.35, "dmg": 1.2, "elite_t": 0.8, "dusk": true}},
	{"id": "damar",  "name": "DAMAR YATAĞI",        "icon": "ico_frag",    "pos": Vector2(1150, 420), "col": "80ffd4", "kind": "arena", "biome": 7, "unlock": "node", "desc": "Çukurun ana damarı — kristalin doğrudan kabuğa bastığı yatak. Sürü sık ama saçılan parçacık zengin.", "lore": "Maden defterlerinde 'ana yatak' diye geçer — imparatorluğun choralim'in yarısını buradan çektiği söylenir. Damar hâlâ dolu; kovan da bunu biliyor.", "mods": {"spawn": 1.25, "frag": 2.1, "loot": 1.3, "hp": 1.3, "dmg": 1.15, "elite_t": 0.85}},
	{"id": "baraka", "name": "MADENCİ BARAKASI",    "icon": "icn_kovan",   "pos": Vector2(1080, 490), "col": "90a4ae", "kind": "story", "unlock": "node", "desc": "Çukur girişinde terk edilmiş madenci barakası — son vardiyanın defteri hâlâ masada.", "lore": "Defterin son satırı: 'Damar bugün kendi bekçisini çıkardı. Kristal yürüdü. Kimse inanmadı.' Vardiya o gün inmedi; baraka kilitli kaldı.", "choices": [
		{"label": "DEFTERİ YAĞMALA — çekmeceleri karıştır", "sub": "Vardiyanın kalan payı hâlâ masada — ama baraka kırılınca çukurun fısıltısı sana da kulağını çevirir.", "rew": {"cho": 240, "omen": {"elite_t": 0.9, "dmg": 1.08}, "cine": [{"tex": "cine_7_0", "title": "MADENCİ BARAKASI", "sub": "Masadaki defterin son sayfasında tek cümle: 'Kristal yürüyorsa, damar yaşıyor — ve damar kimseyi sevmez.'"}]}},
		{"label": "VARDİYA LİSTESİNİ TESLİM ET", "sub": "On bir isim, hepsi 'son iniş' yazıyor. Listeyi Lena'nın arşivine kat — madenciler kampta anılsın.", "rew": {"cho": 90, "rep": 2, "cine": [{"tex": "cine_7_0", "title": "VARDİYA LİSTESİ", "sub": "On bir ismi saydın — hepsini. Baraka kapanırken masada bir bardak daha az kaldı; listedeki hiçbir isim silinmedi."}]}},
	]},
	{"id": "buzul",  "name": "DONMUŞ ÇATLAK",      "icon": "icn_dash",    "pos": Vector2(1380, 500), "col": "9fd8ff", "kind": "arena", "biome": 8, "unlock": "node", "desc": "Kuzeyin buzulu — kar yağışı altında don patlamaları çatırdar, kaygan zemin koşuyu zorlaştırır.", "lore": "Protokol kuzeyi 'düşük değer' diye geçti — kimse bakmadı, kimse dönmedi. Buzun altında donmuş sürüler hâlâ ayakta; çatlak onları tek tek uyandırıyor.", "mods": {"hp": 1.3, "dmg": 1.15, "spawn": 1.1, "frag": 1.6, "loot": 1.4, "elite_t": 0.8, "dusk": true}},
	{"id": "beyazufuk","name": "BEYAZ UFUK",        "icon": "icn_dash",    "pos": Vector2(1430, 300), "col": "eaf6ff", "kind": "arena", "biome": 8, "unlock": "node", "desc": "Buzulun en kuzeyi — karın içinde gökyüzü bile yok; Buz Anası'nın taht odası burada görüldü.", "lore": "Lena'nın haritasında bu köşe çizilmemiş — 'ufuk beyazsa harita biter' yazmış. Kırk gün kar durmadı; durunca sürülerin hepsi aynı yere baktı: içeri.", "mods": {"hp": 1.55, "dmg": 1.35, "spawn": 1.15, "frag": 2.0, "loot": 1.7, "elite_t": 0.65, "dusk": true}},
	{"id": "batikfener", "name": "BATIK FENER",      "icon": "icn_dash",   "pos": Vector2(1195, 495), "col": "9ccc65", "kind": "story", "unlock": "node", "desc": "Bataklığa yarı batmış eski yol feneri — fitili hâlâ yanıyor, kulesi hâlâ eğik.", "lore": "Kervanlar bu feneri bataklığın tek kılavuzu sayardı. Koro geldiğinde feneri susturamadı; alev choralim'e döndü. Şimdi yanmak değil, şarkı söylüyor — ve söylediği nota sürüyü buraya çekiyor.", "choices": [
		{"label": "YAĞI BOŞALT — fenerin kandilini söndür", "sub": "Kandil hâlâ dolu — choralim yağı parasal değer taşır. Ama fener susunca bataklık seni işaretler; sürü seni uzaktan tanır.", "rew": {"cho": 260, "omen": {"spawn": 1.1, "dmg": 1.05}, "cine": [{"tex": "cine_4_0", "title": "BATIK FENER", "sub": "Alev sönerken bir nota bıraktı — bataklığın bütün kurbağaları aynı anda sustu. Şimdi su altında bir şey senin yönüne döndü."}]}},
		{"label": "FİTİLİ ONAR — feneri geri yak", "sub": "Fener bataklığın kılavuzuydu; tekrar yanarsa yollar güvenli kalır. Kamp bunu duyar — itibar artar.", "rew": {"cho": 90, "rep": 3, "omen": {"heal": 1.15}, "cine": [{"tex": "cine_4_0", "title": "FENER YENİDEN", "sub": "Fitil tutuştu; bataklık aynı kaldı ama yollar biraz daha aydınlık. Kamp istikametinde bir vaha gözün gibi açıldı."}]}},
	]},
	{"id": "vahde", "name": "KÜL VAHDESİ",         "icon": "icn_skull",   "pos": Vector2(1370, 80),  "col": "ff9e5c", "kind": "story", "unlock": "node", "desc": "Kor Anıtı'nın ardında küle gömülü bir vahde — Praetorian nöbet defterinin son sayfası hâlâ burada.", "lore": "Anıtın gölgesinde düz bir taş: altında yangın gününün nöbetçisinin vahdesi gömülü. Defterin son satırı: 'Kül yürüdüğünde nöbet bitmez — sadece yön değiştirir.' Vahdenin içinde pençe zırhı ve bir avuç sönmemiş kor var.", "choices": [
		{"label": "VAHDEYİ AÇ — pençe zırhını al", "sub": "Nöbetçinin miğferi külün altında sağlam kaldı — ama vahdeyi açmak korları havalandırır: sonraki koşunda kovan daha sert vurur, karşılığında bereket artar.", "rew": {"cho": 150, "item": "i_vahde", "omen": {"dmg": 1.08, "frag": 1.15}, "cine": [{"tex": "cine_5_0", "title": "VAHDE AÇILDI", "sub": "Miğfer külden çıktı — içindeki kor hâlâ turuncu. Nöbetçinin son sayfası sende; kül bir an durup sonra sana döndü."}]}},
		{"label": "KÜLLERİ ÖRT — nöbeti onurlandır", "sub": "Bazı nöbetler bitmez. Vahdeyi olduğu gibi gömersin; kamp bunu duyar, kül de seni unutmaz.", "rew": {"cho": 90, "rep": 2, "cine": [{"tex": "cine_5_0", "title": "NÖBET SÜRDÜ", "sub": "Külleri örttün, taşı düzledin. Kor Anıtı'nın nabzı bir dakika yavaşladı — sanki biri nöbeti devraldı."}]}},
	]},
	{"id": "prova", "name": "PROVA SALONU",      "icon": "icn_kovan",   "pos": Vector2(1160, 120), "col": "c26bff", "kind": "story", "unlock": "node", "desc": "Sinyal Kulesi'nin dibinde yarı gömülü bir salon — duvarlarında notalar değil, çentikler var. Koro'nun ilk prova odası.", "lore": "Sözcüler burada şarkıya değil, emre çalışırdı: her çentik bir sürü hareketi, her sütun bir imparatorluk şehri. Son sütunun başlığı hâlâ okunuyor: 'KAMP'. Sırası gelmemiş tek satır — onu senin kesmen için bıraktılar.", "choices": [
		{"label": "ÇENTİKLERİ SÖK — salonu sömür", "sub": "Çentik taşları choralim değerinde — ama prova odasını açmak sözcülerin dikkatini çeker: sonraki koşunda elitler sık doğar.", "rew": {"cho": 190, "omen": {"elite_t": 0.85, "loot": 1.2}, "cine": [
			{"tex": "cine_2_1", "title": "PROVA SALONU", "sub": "Son sütunu duvardan söktün. Çentiklerin arasında sürü hareketlerinin takvimi var — kampın adı 'yaklaşan' diye işaretli."},
			{"tex": "por_orun", "title": "ORUN", "sub": "O taşları okudun, değil mi? Koro prova ettiği şarkıyı hiç yarıda bırakmez — dikkatli ol, artık seni dinliyorlar."},
		]}},
		{"label": "SALONU MÜHÜRLE — prova bitsin", "sub": "Bazı şarkılar söylenmemeli. Kapıyı kilitlersin; kamp bunu duyar, sözcüler de yeni bir salon arar.", "rew": {"cho": 90, "rep": 2, "item": "i_merdiven", "cine": [
			{"tex": "cine_2_2", "title": "SALON KAPANDI", "sub": "Kapağı mühürledin. İçeride hâlâ bir metronom sesi var ama artık kimseye ulaşmıyor — sütunlar karanlıkta saymaya devam edecek."},
		]}},
	]},
	{"id": "kutuphane","name": "KORO ARŞİVİ",    "icon": "icn_kovan",   "pos": Vector2(800, 200),  "col": "b39ddb", "kind": "story", "unlock": "node", "desc": "Mezarlığın üstünde kemerli bir salon — Protokol düşen herkesin adını burada tutar; raflar hâlâ dolu.", "lore": "Vezir'in defterinin aslı buradan kopyalandı: arşivci automatonlar her düşeni kayda geçirdi — isim, düştüğü düğüm, son sinyal. Koro arşivi susturamadı; sadece kayıtların sonunu kesmeye yemin etti. Zirkon'un istediği fihrist tam şu rafta.", "choices": [
		{"label": "FİHRİSTİ KOPYALA — arşiv kampta yaşasın", "sub": "Düşenlerin listesi kampın kaydına geçer; koro not alır ama arşiv artık iki yerde yaşar. Kamp bunu unutmaz.", "rew": {"cho": 80, "rep": 3, "omen": {"loot": 1.25}, "cine": [
			{"tex": "cine_3_1", "title": "KORO ARŞİVİ", "sub": "Sayfaları kopyaladın — binlerce isim, hepsi 'düştü' diye bitiyor. Son sayfa boş; arşivci henüz senin adını yazmadı."},
			{"tex": "por_zirkon", "title": "VEZİR ZİRKON", "sub": "Fihristi getirdin — bu isimler artık kampta yaşayacak. Koro'nun silmesini beklediği tek arşiv, artık iki yerde var."},
		]}},
		{"label": "ARŞİVİ YAK — kayıtlar Koro'da kalmasın", "sub": "Koro'nun tek çalışan arşivi kül olur — düşenler özgürleşir ama sözcüler yangını görür: sonraki koşunda sürü kalınlaşır, ganimet de bereketlenir.", "rew": {"cho": 170, "omen": {"spawn": 1.15, "frag": 1.3}, "cine": [{"tex": "cine_3_3", "title": "ARŞİV YANDI", "sub": "Raflar tek tek çöktü; kül yaprakları kemerlerin arasında kar gibi savruldu. Yukarıda bir yerde koro, notasını kaybetti."}]}},
	]},
	{"id": "kervan", "name": "DONMUŞ KERVAN",      "icon": "ico_loot",    "pos": Vector2(1345, 395), "col": "bfe8ff", "kind": "story", "unlock": "node", "desc": "Çatlağın kuzeyinde donmuş imparatorluk kervanı — yük ve yolcular hâlâ ayakta, hâlâ yürür vaziyette.", "lore": "Kervan defterinin son satırı: 'Hanım şarkı söyledi, atlar durdu, kar üstümüze kapandı. Yükü kimseye vermeyin — damarın içinde taşıdığımız şey buzda kalsın.' İçerideki sandık hâlâ mühürlü; mühür şimdi bizde.", "choices": [
		{"label": "MÜHRÜ KIR — sandığı aç", "sub": "Sandık choralim dolu — ama defterin uyarısı gerçek: yük açılınca kovan kokuyu alır. Sonraki koşun daha sert geçecek.", "rew": {"cho": 320, "omen": {"hp": 1.12, "dmg": 1.1, "frag": 1.35}, "cine": [{"tex": "cine_8_0", "title": "MÜHÜR KIRILDI", "sub": "Sandık açıldı — içinde choralim dolu fişekler ve bir koro damgasının mührü. Kuzeyde bir şey yerinden kıpırdadı."}]}},
		{"label": "KERVANI GÖM — yüke dokunma", "sub": "Defterin dediği gibi: bazı yükler buzda kalmalı. Kervanı kar altında göm, itibarın artsın, buzdan bir kalp hatıra kalsın.", "rew": {"cho": 100, "rep": 2, "item": "i_buzkalp", "cine": [{"tex": "cine_8_0", "title": "KERVAN GÖMÜLDÜ", "sub": "On iki deve ve dört arabacı kar altında. Buzda bekleyen yüke kimse dokunmadı — ve kuzey, seni ilk kez selamladı."}]}},
	]},
	{"id": "buzkasa","name": "BUZ KASASI",       "icon": "ico_loot",   "pos": Vector2(1505, 445), "col": "9fd8ff", "kind": "hazine","biome": 8, "unlock": "node", "desc": "Buzulun karnına gömülü imparatorluk kasası — efendi yok; buz mührü 6 dakika sonra çatlar, içi donmuş ganimet.", "lore": "Kervan defterinin kastettiği 'yük' bu kasaydı — imparatorluk choralim stokunu buza emanet etti. Buz Anası düşünce mühürdeki sesten pay alamadı; şimdi kasa sadece sabır istiyor.", "mods": {"loot": 2.7, "frag": 2.2, "hp": 1.2, "spawn": 1.15, "elite_t": 0.7}},
	{"id": "damarkasa","name": "DAMAR KASASI",  "icon": "ico_loot",   "pos": Vector2(1300, 640), "col": "80ffd4", "kind": "hazine","biome": 7, "unlock": "node", "desc": "Çukurun dibinde damara gömülü zula — efendi yok; kristal mühür 6 dakika sonra düşer, içi ham choralim.", "lore": "Maden barakasının defterinde 'ana kasa damarın göbeğine gömüldü — mühür damardan besleniyor' yazar. Kasa kristalin içinde büyümüş; altı dakikalık sessizlik onu çözüyor.", "mods": {"loot": 2.6, "frag": 2.3, "hp": 1.15, "spawn": 1.2, "elite_t": 0.75, "dusk": true}},
	{"id": "ayaz",   "name": "AYAZ KUYUSU",      "icon": "icn_dash",   "pos": Vector2(1270, 620), "col": "bfe8ff", "kind": "arena", "biome": 8, "unlock": "node", "desc": "Buzulun güneyinde dibi görünmeyen dikey kuyu — bora buradan iner, donmuş sürüler buradan tırmanır.", "lore": "İzcilerin son notu: 'kuyu nefes alıyor — bora onun nefesi, sürüler onun öksürüğü.' Kuyunun dibinde koro'nun ilk şarkısı buzda saklı; buz Anası o şarkıyı duymak için bekliyordu.", "mods": {"hp": 1.4, "dmg": 1.2, "spawn": 1.15, "frag": 1.7, "loot": 1.5, "elite_t": 0.75, "dusk": true}},
]

# günlük protokol: tarihe göre deterministik saha mutasyonu (roguelite daily run)
const DAILY := [
	{"name": "KALABALIK GÜN", "desc": "sürü %25 daha kalabalık akar", "mods": {"spawn": 1.25}, "rew": 1.1},
	{"name": "ZIRHLI SÜRÜ",   "desc": "kovan %20 daha dayanıklı",      "mods": {"hp": 1.2}, "rew": 1.15},
	{"name": "ACIMASIZ GÜN",  "desc": "kovan %20 daha sert vurur",     "mods": {"dmg": 1.2}, "rew": 1.15},
	{"name": "BEREKET",       "desc": "parçacık düşüşü +%40",          "mods": {"frag": 1.4}, "rew": 1.0},
	{"name": "ŞANSLI GÜN",    "desc": "eşya/kalite şansı +0.2",        "luck": 0.2, "rew": 1.0},
	{"name": "ELİT NÖBETİ",   "desc": "elitler sık doğar",             "mods": {"elite_t": 0.7}, "rew": 1.1},
]

static func daily() -> Dictionary:
	var dk := Time.get_date_string_from_system()
	return DAILY[abs(dk.hash()) % DAILY.size()]

# harita üstünde çizilen seyahat hatları (BG2 bağlantıları)
const EDGES := [
	["kamp", "b0"], ["kamp", "pazar"], ["kamp", "tarla"], ["kamp", "yol"],
	["b0", "yol"], ["b0", "tarla"], ["yol", "b1"], ["b1", "b2"],
	["tarla", "b3"], ["b2", "b3"], ["b3", "kuyu"], ["b2", "kuyu"],
	["pazar", "yuvalar"], ["b1", "yuvalar"], ["b3", "vatika"], ["kuyu", "vatika"],
	["tarla", "mabed"], ["mabed", "vatika"], ["yuvalar", "mezarlik"], ["b1", "mezarlik"],
	["b2", "batak"], ["batak", "kuyu"], ["batak", "sarnic"], ["kuyu", "sarnic"],
	["sarnic", "gozyuva"], ["batak", "gozyuva"],
	["tarla", "kayalik"], ["kamp", "kayalik"],
	["mabed", "krater"], ["vatika", "krater"],
	["kayalik", "sisgecidi"], ["kamp", "sisgecidi"],
	["kuyu", "kulovasi"], ["mezarlik", "kulovasi"],
	["kulovasi", "avlis"],
	["vatika", "yemin"], ["kayalik", "yemin"],
	["yol", "tasocagi"], ["tasocagi", "yuvalar"],
	["avlis", "sondurme"], ["kulovasi", "sondurme"],
	["b0", "kum"], ["pazar", "kum"], ["kum", "fisilti"],
	["kum", "vaha"], ["vaha", "fisilti"], ["vaha", "batik"],
	["kum", "degirmen"], ["vaha", "degirmen"],
	["degirmen", "kervansaray"], ["batik", "kervansaray"], ["b1", "madenkasa"], ["tarla", "madenkasa"],
	["kulovasi", "korkasa"], ["koranit", "korkasa"],
	["cukur", "buzul"], ["damar", "buzul"], ["buzul", "kervan"],
	["buzul", "beyazufuk"], ["kervan", "beyazufuk"],
	["beyazufuk", "buzkasa"], ["buzul", "buzkasa"],
	["cukur", "ayaz"], ["buzul", "ayaz"], ["beyazufuk", "ayaz"],
	["batak", "batikfener"], ["damar", "batikfener"],
	["cukur", "damarkasa"], ["damar", "damarkasa"], ["kaos", "damarkasa"],
	["kamp", "karakol"], ["karakol", "b0"],
	["karakol", "muhkasa"], ["b0", "muhkasa"],
	["mezarlik", "sinyal"], ["b2", "sinyal"],
	["sinyal", "prova"], ["b2", "prova"],
	["mezarlik", "kutuphane"], ["sinyal", "kutuphane"],
]

# harita komşuları — sefer zinciri ve rota önerisi için
static func neighbors(id: String) -> Array:
	var out: Array = []
	for e in EDGES:
		if e[0] == id:
			out.append(str(e[1]))
		elif e[1] == id:
			out.append(str(e[0]))
	return out

static func node(id: String) -> Dictionary:
	for n in NODES:
		if n.id == id:
			return n
	return {}

static func _unlocked() -> Array:
	return G.meta.data.get("unlocked", [])

# canlı harita: kampa dönüşte işaretlenen baskın düğümü ("" = yok)
static func hot_node() -> String:
	return str(G.meta.data.get("hot_node", ""))

# ikinci canlı işaret: sessiz verim düğümü — baskınsız frag/loot bereketi
static func yield_node() -> String:
	return str(G.meta.data.get("yield_node", ""))

# is this node reachable? "open" / "node" (quest-unlocked) / "boss <id>"
static func can_enter(id: String) -> bool:
	var n := node(id)
	if n.is_empty():
		return false
	if str(n.get("kind", "")) == "story" and (G.meta.data.get("story_done", []) as Array).has(id):
		return false
	match str(n.get("unlock", "open")):
		"open":
			return true
		"node":
			return _unlocked().has(id)
		_:
			var u := str(n.unlock)  # "boss rex"
			if u.begins_with("boss "):
				return (G.meta.data.get("bosses", []) as Array).has(u.substr(5))
			return false

# görev ödülüyle node açılınca oynatılan tek kartlık sinematik
static func unlock_cine(id: String) -> void:
	var n := node(id)
	if n.is_empty():
		return
	var bi := int(n.get("biome", 0))
	var lore := str(n.get("lore", n.get("desc", "")))
	G.ui.cinematic("cine_%d_0" % bi, str(n.name) + " — AÇILDI", lore, 3.4)

static func unlock_text(id: String) -> String:
	var n := node(id)
	if str(n.get("kind", "")) == "story" and (G.meta.data.get("story_done", []) as Array).has(id):
		return "tamamlandı"
	match str(n.get("unlock", "open")):
		"open": return ""
		"node": return "görevle açılır"
		_:
			var u := str(n.unlock)
			if u.begins_with("boss "):
				var bid := u.substr(5)
				var names := {"rex": "ALFA-05", "host": "PROTERYAN KONAKÇI", "twins": "NAHUM & TUMAN", "final": "KİRİN & CONSTANTİN", "damar": "DAMAR KALBİ"}
				return "önce %s düşmeli" % str(names.get(bid, bid))
			return "?"
