class_name Enemy
extends Actor

# Data-driven melee/ranged enemy AI with readable telegraphs.
# States: RISE -> SEEK -> WINDUP -> STRIKE -> RECOVER -> SEEK ...

enum EKind { HUSK, SPITTER, TURRET, DRONE, SENTINEL, VARL, CEREB, KONAKCI, ALFA, CARRIER, MUHFIZ, HERALD, AKREP, BALCIK, GOZETMEN, COPCU, DINAMITCI, KUZGUN, SIVRI, KOCBASI, DAMARGOL, FISILTI, KORP, BUZRUH, TAYF, EMICI, DOL }

# tür-bazlı ölüm patlaması rengi — kesimden kimin öldüğü görsel okunur
const KIND_COL := {EKind.HUSK: "69f0ae", EKind.SENTINEL: "8ea0b5", EKind.SPITTER: "39ff14", EKind.TURRET: "90a4ae", EKind.DRONE: "4dd0e1", EKind.VARL: "e8c468", EKind.CEREB: "b26bff", EKind.KONAKCI: "ff9e4d", EKind.ALFA: "ff5252", EKind.CARRIER: "ffd700", EKind.MUHFIZ: "80d8ff", EKind.HERALD: "e8d060", EKind.AKREP: "e8a050", EKind.BALCIK: "6fbf73", EKind.GOZETMEN: "b388ff", EKind.COPCU: "d7a05a", EKind.DINAMITCI: "ff7043", EKind.KUZGUN: "5e3f8c", EKind.SIVRI: "7fe0b8", EKind.KOCBASI: "c97040", EKind.DAMARGOL: "4dd0e1", EKind.FISILTI: "8be9f5", EKind.KORP: "ff8a50", EKind.BUZRUH: "a8dcff", EKind.TAYF: "7fe8d8", EKind.EMICI: "6fd3c9", EKind.DOL: "9ccc65"}
# biome rengi — sürü sahanın fener/mote paletine oturur (room.gd ile aynı sıra)
const BIOME_TINT := ["ffb74d", "00E676", "ff7722", "c9a227", "66bb6a", "ff5522", "ffaa55", "4dd0e1", "9fd8ff"]
const KIND_NAME := {EKind.HUSK: "Proterian Husk", EKind.SENTINEL: "İmparatorluk Muhafızı", EKind.SPITTER: "Tükürükçü", EKind.TURRET: "Taret", EKind.DRONE: "Vızıltı Dronu", EKind.VARL: "Çölayan Varl", EKind.CEREB: "Cerebellum Kisti", EKind.KONAKCI: "Konakçı Yaratık", EKind.ALFA: "Alfa Şövalye", EKind.CARRIER: "Hamal Taşıyıcı", EKind.MUHFIZ: "Kalkan Muhafızı", EKind.HERALD: "Koro Sözcüsü", EKind.AKREP: "Kum Akrebi", EKind.BALCIK: "Balçık Adam", EKind.GOZETMEN: "Gözetmen", EKind.COPCU: "Çöpçü Kurt", EKind.DINAMITCI: "Dinamitçi Tayf", EKind.KUZGUN: "Tarla Kuzgunu", EKind.SIVRI: "Sivri Bulutu", EKind.KOCBASI: "Kocboynuz", EKind.DAMARGOL: "Damar Golemi", EKind.FISILTI: "Damar Fısıltısı", EKind.KORP: "Kor Pençe", EKind.BUZRUH: "Buz Ruhu", EKind.TAYF: "Ufuk Tayfı", EKind.EMICI: "Parçacık Emicisi", EKind.DOL: "Döl Yuması"}
enum St { RISE, SEEK, WINDUP, STRIKE, RECOVER }

# painted concept-art sets for the new kinds; biome variants fall back to the
# base set automatically in _make_body
const KIND_SET := {
	EKind.VARL: "c_varl", EKind.CEREB: "c_cereb",
	EKind.KONAKCI: "c_konakci", EKind.ALFA: "c_alfa", EKind.CARRIER: "c_carrier",
	EKind.MUHFIZ: "c_alfa", EKind.HERALD: "c_herald", EKind.AKREP: "c_akrep",
	EKind.BALCIK: "c_balcik", EKind.GOZETMEN: "c_gozetmen", EKind.COPCU: "c_copcu",
	EKind.DINAMITCI: "c_dinamitci", EKind.KUZGUN: "c_kuzgun",
	EKind.SIVRI: "c_sivri", EKind.KOCBASI: "c_koc", EKind.DAMARGOL: "c_gol",
	EKind.FISILTI: "c_fisilti", EKind.KORP: "c_pence", EKind.BUZRUH: "c_fisilti",
	EKind.TAYF: "c_tayf", EKind.EMICI: "c_emici", EKind.DOL: "c_dol",
}

# tür lore'u — Zirkon'un kayıtlarında kesim sayısının altında gösterilir
const KIND_LORE := {
	EKind.HUSK: "Protokolün büküp bıraktığı ilk gövde — kovana hâlâ itaat ediyor.",
	EKind.SPITTER: "Boğaz kesesinde proterian asidi birikir; mesafeyi sever.",
	EKind.TURRET: "Sabit nöbetçi — gövdesi zemine kaynaklı, sabrı sonsuz.",
	EKind.DRONE: "Kovanın eşek arısı. Tuzak gibi düşer, yankı gibi ölür.",
	EKind.SENTINEL: "İmparatorluk nöbetçisi — zırhı hâlâ eski emirleri taşır.",
	EKind.VARL: "Çölayan sürü artığı — hızlı, aç, kalabalık gelir.",
	EKind.CEREB: "Yürüyen kist — lobların içinde choralim pişer, uzaktan atar.",
	EKind.KONAKCI: "Taşıdığı yük canlı; ölürken içini boşaltır — arkasında durma.",
	EKind.ALFA: "Kovanın öncü şövalyesi — ilk çizgiyi o kurar, son çizgide o durur.",
	EKind.CARRIER: "Hamal — sırtındaki çuvalda ganimet taşır; öldür, payını al.",
	EKind.MUHFIZ: "Eski alayın kalkanı — önden vurulmaz, yandan çözülür.",
	EKind.HERALD: "Koro'nun ses taşıyıcısı — çanı çaldıkça sürü hızlanır; önce onu kes.",
	EKind.AKREP: "Kızıl kumun altında gezen iğne — gömülünce mermi geçer, çıkınca hamle var.",
	EKind.BALCIK: "Bataklığın biriktirdiği gövde — yarası çamurla kapanır; bırakırsan toparlanır.",
	EKind.GOZETMEN: "Aeterna'nın süzülen gözü — uzaktan ölçer, halkasını açınca ağır mermi gelir.",
	EKind.COPCU: "Enkazın aç çöpçüsü — yere saçılan kristalleri yutar, kesmeden önce hızlı davran.",
	EKind.DINAMITCI: "Madenin barutçusu — fıçıyı yuvarlar, fitil yanınca patlama iki tarafı da vurur. Yakınında durma.",
	EKind.KUZGUN: "Yanık tarlaların çöpçüsü — yüksekten dalışa geçer, pençesi hızlıdır. Uçarken hamlesini oku.",
	EKind.SIVRI: "Bataklığın döl bulutu — tek sinek değil, sürü. Hızlı ve kalabalık gelir; alan silahı olmadan kovalanmaz.",
	EKind.KOCBASI: "Çoraklığın koçbaşı — mesafe bulunca toynak vurur, boynuz şeridi boyunca devrilir. Çizgisinden çık.",
	EKind.DAMARGOL: "Damarın kendi eliyle büyüttüğü bekçi — yavaş yürür, taşıdığı kristal gövdeyi yumrukla indirir. Kredisi ağır basar.",
	EKind.FISILTI: "Çukurun duvarlarından kopup sürülen kristal parçaları — teki önemsiz, sürüsü kistten beter. Alan vurmadan temizlenmez.",
	EKind.KORP: "Praetorian yangınında yanan askerlerin küllerinden doğan hortlak — pençesi hâlâ kor. Hızlı gelir, külü savurur.",
	EKind.BUZRUH: "Çatlağın donmuş nefesi — süzülürken altında buz serilir, ölürken son bir donukluk bırakır. Buzunda durma.",
	EKind.TAYF: "Beyaz Ufuk'un ışık hortlağı — aurora perdelerinden dokunmuş; belirir, dağılır, yeniden belirir. Mermiler dağılmış halinden geçer.",
	EKind.EMICI: "Enkazın kese askeri — huni ağzı parçacık kokar, teması kesenden ◈ emer. Öldürürsen kesesini sana döker.",
	EKind.DOL: "Bataklığın gömülü kuluçkası — kımıldamaz ama yavru kusar; yok edilmedikçe sürüyü sonsuz besler. Önce onu bul.",
}

var kind: int = EKind.HUSK
var elite := false
var champ := false        # nadir altın katman — ×5 can, garanti eşya + ekstra sandık
var affix := ""            # elite modifier: armored / volatile / swift / sparked
var _spk_t := 0.0
var _sum_t := 0.0   # çağırıcı elit: döl saçma sayacı
var _mend_t := 0.0  # şifalı elit: alan onarımı sayacı
var _lead_pulse := 0.0  # sürücü elit: hız aurası sayacı
var lead_t := 0.0       # bu düşmanın üstündeki kalan sürücü buffı
var _trail_t := 0.0     # iz süren elit: kor izi bırakma sayacı
var _warp_t := 0.0      # ışınlanan elit: teleport sayacı
var _herald_t := 3.0    # koro sözcüsü: çan aurası sayacı
var _yanki_t := 0.0     # yankıcı elit: şok halkası sayacı
var _hay_cd := 0.0      # hayalet elit: faz geçişi bekleme sayacı
var _hay_t := 0.0       # hayalet elit: hayalet penceresi kalan süre
var _yanki_hit := 0.0   # yankıcı elit: halkanın ineceği an
var _muhur_t := 0.0     # mühürlü elit: sonraki mühür penceresine kalan süre
var _muhur_win := 0.0   # mühür penceresi açıkken kalan süre (hasar yemez)
var _muhur_sp: Sprite2D = null
var _sum_n := 0     # bu elitin saldığı döl sayısı
var _balcik_cd := 0.0  # balçık adam: hasar sonrası rejenerasyon beklemesi
var _stolen := 0.0     # çöpçü kurt: yuttuğu kristal değeri
var _cil_t := 0.0      # çılgın elit: öfke kıvılcımı sayacı
var _dol_t := 2.5      # döl yuması: yavru kusma sayacı
var _dol_kids: Array = []  # döl yuması: canlı yavrular (adet sınırı için)
var _scav_t := 0.0     # çöpçü kurt: kristal tarama sayacı
var _regen_fx := 0.0   # rejenerasyon parıltısı sayacı
var speed := 100.0
var touch_dmg := 10.0
var touch_r := 36.0
var windup_t := 0.45
var recover_t := 0.55
var attack_cd := 0.9
var burst_n := 0
var burst_gap := 0.12
var proj_spd := 230.0
var proj_dmg := 9.0
var keep_min := 0.0
var keep_max := 9999.0
var kamikaze := false
var splits := 0             # on death, burst into this many parasite runners

var _st: int = St.RISE
var _rise_t := 0.55
var _burrowed := false    # akrep: kumda gömülü — vurulmaz, hızlı
var _burrow_t := 0.0
var _burrow_cd := 2.5
var _dive_t := 0.0        # kuzgun: dalış hamlesi — kısa süre çok hızlı
var _phased := false      # tayf: dağılmış hal — vurulamaz, hızlı
var _phase_t := 0.0
var _phase_cd := 4.0
var _dive_cd := 2.4
var _charge_w := 0.0      # kocbası: telegraph aşaması (toynak vurma)
var _charge_t := 0.0      # kocbası: şarj süresi
var _charge_cd := 1.2
var _charge_dir := Vector2.RIGHT
var _charge_hit := false  # bu şarjda vuruldu mu
var _ctele := {}
var _state_t := 0.0
var _cd_t := 0.0
var _frost_t := 0.0   # buz ruhu: buz serme sayacı
var _strike_dir := Vector2.ZERO
var _tele := {}
var _has_tok := false          # holds an attack-director token
var _revived := false          # hortlak elit: diriliş hakkı harcandı
var _revive_pending := false   # hortlak elit: diriliş sayacı dönüyor
var _orbit := 1.0              # strafe direction while waiting for a token

static func spawn(p_kind: int, p_pos: Vector2, p_elite: bool, hp_scale: float, dmg_scale: float, parent: Node) -> Enemy:
	var e := Enemy.new()
	e.kind = p_kind
	e.elite = p_elite
	e.team = G.Team.ENEMY
	parent.add_child(e)
	e.global_position = p_pos
	e._setup_stats(hp_scale, dmg_scale)
	e.init()
	G.enemies.append(e)
	# ilk karşılaşma: tür Zirkon'un kayıtlarına düşer
	var sk: Array = G.meta.data.get("seen_kinds", [])
	if not sk.has(p_kind):
		sk.append(p_kind)
		G.meta.data["seen_kinds"] = sk
		G.meta.save()
		if is_instance_valid(G.ui):
			G.ui.toast("KAYIT: %s — yeni tür deftere işlendi" % KIND_NAME.get(p_kind, "?"))
	# elit/şampiyon belirişi: yerde yanan halka + ışık — kalabalığın içinden okunur
	if p_elite:
		G.fx.tele_circle(p_pos, 46.0, 0.55, Color(1.0, 0.62, 0.15, 0.30))
		G.fx.light_flash(p_pos + Vector2(0, -14), Px.C("ffb74d"), 1.3, 2.2, 0.22)
	return e

func _setup_stats(hs: float, ds: float) -> void:
	match kind:
		EKind.HUSK:
			max_hp = 34; speed = 108; touch_dmg = 8; radius = 13; hit_radius = 16
			windup_t = 0.45; recover_t = 0.55; attack_cd = 1.15; touch_r = 36
			actor_name = "Proterian Husk"
		EKind.SENTINEL:
			max_hp = 55; speed = 135; touch_dmg = 14; radius = 14; hit_radius = 17
			windup_t = 0.5; recover_t = 0.6; attack_cd = 1.1; touch_r = 40
			actor_name = "İmparatorluk Muhafızı"
		EKind.SPITTER:
			max_hp = 26; speed = 75; touch_dmg = 6; radius = 14; hit_radius = 17
			windup_t = 0.55; recover_t = 0.8; attack_cd = 1.7; keep_min = 150; keep_max = 260
			proj_spd = 230; proj_dmg = 9; burst_n = 1
			actor_name = "Tükürükçü"
		EKind.TURRET:
			max_hp = 40; speed = 0; touch_dmg = 0; radius = 15; hit_radius = 17
			windup_t = 0.6; recover_t = 2.2; attack_cd = 2.4; keep_min = 0; keep_max = 9999
			proj_spd = 260; proj_dmg = 7; burst_n = 4; burst_gap = 0.12
			actor_name = "Taret"
			knock_resist = 100.0
		EKind.DRONE:
			max_hp = 12; speed = 165; touch_dmg = 12; radius = 10; hit_radius = 13
			windup_t = 0.55; recover_t = 0.4; attack_cd = 0.8; touch_r = 34; kamikaze = true
			actor_name = "Vızıltı Dronu"
		EKind.VARL:
			max_hp = 16; speed = 192; touch_dmg = 7; radius = 11; hit_radius = 14
			windup_t = 0.35; recover_t = 0.4; attack_cd = 0.9; touch_r = 30
			actor_name = "Çölayan Varl"
		EKind.CEREB:
			max_hp = 34; speed = 62; touch_dmg = 7; radius = 15; hit_radius = 18
			windup_t = 0.6; recover_t = 0.9; attack_cd = 2.2; keep_min = 170; keep_max = 300
			proj_spd = 175; proj_dmg = 13; burst_n = 1
			actor_name = "Cerebellum Kisti"
		EKind.KONAKCI:
			max_hp = 150; speed = 60; touch_dmg = 20; radius = 19; hit_radius = 22
			windup_t = 0.7; recover_t = 0.8; attack_cd = 1.6; touch_r = 48
			actor_name = "Konakçı Yaratık"
			knock_resist = 60.0
			splits = 2
		EKind.ALFA:
			max_hp = 88; speed = 128; touch_dmg = 16; radius = 15; hit_radius = 18
			windup_t = 0.5; recover_t = 0.55; attack_cd = 1.0; touch_r = 42
			actor_name = "Alfa Şövalye"
		EKind.CARRIER:
			max_hp = 130; speed = 66; touch_dmg = 12; radius = 18; hit_radius = 21
			windup_t = 0.65; recover_t = 0.8; attack_cd = 1.5; touch_r = 44
			actor_name = "Hamal Taşıyıcı"
			knock_resist = 80.0
		EKind.MUHFIZ:
			max_hp = 110; speed = 52; touch_dmg = 17; radius = 17; hit_radius = 20
			windup_t = 0.65; recover_t = 0.85; attack_cd = 1.5; touch_r = 46
			actor_name = "Kalkan Muhafızı"
			knock_resist = 85.0
		EKind.HERALD:
			max_hp = 70; speed = 74; touch_dmg = 6; radius = 15; hit_radius = 17
			windup_t = 0.6; recover_t = 1.0; attack_cd = 3.0; keep_min = 230; keep_max = 360
			proj_spd = 190; proj_dmg = 12; burst_n = 1
			actor_name = "Koro Sözcüsü"
		EKind.AKREP:
			max_hp = 48; speed = 155; touch_dmg = 12; radius = 13; hit_radius = 15
			windup_t = 0.4; recover_t = 0.5; attack_cd = 1.0; touch_r = 32
			actor_name = "Kum Akrebi"
		EKind.BALCIK:
			max_hp = 190; speed = 50; touch_dmg = 16; radius = 18; hit_radius = 22
			windup_t = 0.75; recover_t = 0.9; attack_cd = 1.7; touch_r = 46
			actor_name = "Balçık Adam"
			knock_resist = 70.0
		EKind.GOZETMEN:
			max_hp = 80; speed = 92; touch_dmg = 10; radius = 14; hit_radius = 17
			windup_t = 0.8; recover_t = 0.8; attack_cd = 2.1; keep_min = 300; keep_max = 430
			proj_spd = 330; proj_dmg = 22; burst_n = 1
			actor_name = "Gözetmen"
		EKind.COPCU:
			max_hp = 88; speed = 120; touch_dmg = 9; radius = 14; hit_radius = 16
			windup_t = 0.4; recover_t = 0.5; attack_cd = 0.9; touch_r = 34
			actor_name = "Çöpçü Kurt"
		EKind.DINAMITCI:
			max_hp = 64; speed = 74; touch_dmg = 7; radius = 13; hit_radius = 15
			windup_t = 0.9; recover_t = 0.9; attack_cd = 2.6; touch_r = 30
			keep_min = 210; keep_max = 340; proj_spd = 300; proj_dmg = 16
			actor_name = "Dinamitçi Tayf"
		EKind.KUZGUN:
			max_hp = 34; speed = 190; touch_dmg = 8; radius = 11; hit_radius = 13
			windup_t = 0.3; recover_t = 0.4; attack_cd = 1.4; touch_r = 36
			actor_name = "Tarla Kuzgunu"
		EKind.SIVRI:
			max_hp = 9; speed = 205; touch_dmg = 4; radius = 8; hit_radius = 11
			windup_t = 0.28; recover_t = 0.3; attack_cd = 0.7; touch_r = 26
			actor_name = "Sivri Bulutu"
		EKind.KOCBASI:
			max_hp = 62; speed = 105; touch_dmg = 12; radius = 15; hit_radius = 17
			windup_t = 0.5; recover_t = 0.7; attack_cd = 1.5; touch_r = 44
			actor_name = "Kocboynuz"
		EKind.DAMARGOL:
			max_hp = 95; speed = 58; touch_dmg = 16; radius = 17; hit_radius = 19
			windup_t = 0.65; recover_t = 0.9; attack_cd = 1.9; touch_r = 50
			actor_name = "Damar Golemi"
		EKind.FISILTI:
			max_hp = 14; speed = 185; touch_dmg = 5; radius = 9; hit_radius = 12
			windup_t = 0.3; recover_t = 0.35; attack_cd = 0.8; touch_r = 28
			actor_name = "Damar Fısıltısı"
		EKind.KORP:
			max_hp = 58; speed = 132; touch_dmg = 11; radius = 14; hit_radius = 16
			windup_t = 0.45; recover_t = 0.55; attack_cd = 1.2; touch_r = 42
			actor_name = "Kor Pençe"
		EKind.BUZRUH:
			max_hp = 34; speed = 148; touch_dmg = 8; radius = 11; hit_radius = 13
			windup_t = 0.4; recover_t = 0.5; attack_cd = 1.1; touch_r = 36
			actor_name = "Buz Ruhu"
		EKind.TAYF:
			max_hp = 46; speed = 128; touch_dmg = 9; radius = 12; hit_radius = 14
			windup_t = 0.38; recover_t = 0.45; attack_cd = 1.0; touch_r = 34
			actor_name = "Ufuk Tayfı"
		EKind.EMICI:
			max_hp = 40; speed = 148; touch_dmg = 6; radius = 12; hit_radius = 14
			windup_t = 0.4; recover_t = 0.5; attack_cd = 1.0; touch_r = 32
			actor_name = "Parçacık Emicisi"
		EKind.DOL:
			max_hp = 95; speed = 0; touch_dmg = 0; radius = 16; hit_radius = 19
			windup_t = 0.6; recover_t = 1.0; attack_cd = 4.0; keep_min = 0; keep_max = 9999
			actor_name = "Döl Yuması"
			knock_resist = 95.0
	if elite:
		max_hp *= 2.6; touch_dmg *= 1.35; proj_dmg *= 1.3; speed *= 1.1
		actor_name = "Elit " + actor_name
		affix = ["armored", "volatile", "swift", "sparked", "caller", "vampir", "mender", "split", "surucu", "iz", "warp", "koruyucu", "yansi", "muhur", "bile", "kristal", "hortlak", "dev", "cazibe", "ambarli", "kacak", "fanatik", "bozucu", "soguk", "yanki", "hayalet", "cilgin"][randi() % 27]
		# KAÇAK GÜZERGÂHI kozu: elitlerin yarısı kaçak çıkar
		if is_instance_valid(G.run) and G.run.kacak_plus and G.chance(0.5):
			affix = "kacak"
		# NARA KADERİ kozu: fanatiklerin de kendi yoğunluğu var
		elif is_instance_valid(G.run) and G.run.fanatik_plus and G.chance(0.4):
			affix = "fanatik"
		match affix:
			"armored":
				armor += 5.0
				actor_name = "ZIRHLI " + actor_name
			"volatile":
				actor_name = "PATLAYICI " + actor_name
			"swift":
				speed *= 1.45; attack_cd *= 0.8
				actor_name = "HIZLI " + actor_name
			"sparked":
				_spk_t = 1.2
				actor_name = "ŞİMŞEKLİ " + actor_name
			"caller":
				_sum_t = 5.0
				actor_name = "ÇAĞIRICI " + actor_name
			"vampir":
				actor_name = "VAMPİR " + actor_name
			"mender":
				_mend_t = 1.6
				actor_name = "ŞİFALI " + actor_name
			"split":
				actor_name = "BÖLÜCÜ " + actor_name
			"surucu":
				_lead_pulse = 0.8
				actor_name = "SÜRÜCÜ " + actor_name
			"iz":
				_trail_t = 0.6
				actor_name = "İZ SÜREN " + actor_name
			"warp":
				_warp_t = 2.5
				actor_name = "IŞINLANAN " + actor_name
			"koruyucu":
				actor_name = "KORUYUCU " + actor_name
			"yansi":
				actor_name = "YANSITICI " + actor_name
			"bile":
				max_hp *= 0.6
				touch_dmg *= 1.6
				proj_dmg *= 1.6
				actor_name = "BİLEYLİ " + actor_name
			"muhur":
				_muhur_t = 3.5
				actor_name = "MÜHÜRLÜ " + actor_name
			"kristal":
				actor_name = "KRİSTALLİ " + actor_name
			"hortlak":
				actor_name = "HORTLAK " + actor_name
			"dev":
				max_hp *= 1.8; touch_dmg *= 1.25; proj_dmg *= 1.25; speed *= 0.72
				radius *= 1.55; hit_radius *= 1.5
				actor_name = "DEV " + actor_name
			"cazibe":
				actor_name = "CAZİBELİ " + actor_name
			"ambarli":
				actor_name = "AMBARLI " + actor_name
			"fanatik":
				actor_name = "FANATİK " + actor_name
			"kacak":
				actor_name = "KAÇAK " + actor_name
			"bozucu":
				actor_name = "BOZUCU " + actor_name
			"soguk":
				actor_name = "AYAZLI " + actor_name
			"yanki":
				actor_name = "YANKICI " + actor_name
			"hayalet":
				actor_name = "HAYALET " + actor_name
			"cilgin":
				actor_name = "CILGIN " + actor_name
		# affix kaydı — LANET KIRANI başarımını besler
		var seen: Array = G.meta.data.get("affix_seen", [])
		if not seen.has(affix):
			seen.append(affix)
			G.meta.data["affix_seen"] = seen
			G.meta.save()
	max_hp *= hs
	touch_dmg *= ds
	proj_dmg *= ds
	if G.run != null and G.run.slow_all:
		speed *= 0.9
	hp = max_hp

# dakika 8+ nadir altın katman: daha büyük/sert, ölünce garanti eşya + ikinci sandık
func promote_champ() -> void:
	champ = true
	max_hp *= 5.0
	hp = max_hp
	touch_dmg *= 1.35
	proj_dmg *= 1.3
	actor_name = "ŞAMPİYON " + actor_name
	base_color = Color(1.0, 0.8, 0.3)
	if is_instance_valid(body):
		Px.fit(body, 150.0)
	G.fx.mk_light(self, Vector2(0, -18), Px.C("ffd700"), 0.85, 2.2)
	G.fx.flash(Px.C("ffd700"), 0.18)
	G.audio.play("roar", 0.5, 0.55)
	# kan davası: bazı şampiyonlar geri dönen KOPUZ olur — her kesim bir sonrakini büyütür
	if G.chance(0.30):
		var nl: int = int(G.meta.data.get("nemesis_lvl", 0)) + 1
		set_meta("nemesis", nl)
		max_hp *= 1.0 + 0.35 * nl
		hp = max_hp
		touch_dmg *= 1.0 + 0.12 * nl
		actor_name = "KOPUZ (kan davası %d)" % nl
		base_color = Color(1.0, 0.45, 0.2)
		G.fx.mk_light(self, Vector2(0, -30), Px.C("ff5252"), 0.7, 2.8)
		if is_instance_valid(G.ui):
			G.ui.toast("KOPUZ geri döndü — kan davası %d. perde" % nl)

func init() -> void:
	super.init()
	_make_body()
	G.fx.burst(pos + Vector2(0, -6), Px.C("7B1FA2") if elite else Color(0.3, 0.5, 0.2), 12, 90.0, 4.0, 0.5)

func _make_body() -> void:
	body = Sprite2D.new()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	G.upright(self).add_child(body)
	var kn: String = KIND_SET.get(kind, EKind.keys()[kind].to_lower())
	if kind == EKind.BALCIK:
		base_color = Color(0.82, 1.0, 0.85)
	if is_instance_valid(G.room) and G.room.biome > 0:
		var bk := "%s_%d" % [kn, G.room.biome]
		if not Px._ext_frames(bk).is_empty():
			kn = bk
	_load_frames(kn, 5.0)
	Px.fit(body, (150.0 if affix == "dev" else 118.0) if elite else (112.0 if kind == EKind.DAMARGOL else (108.0 if kind == EKind.KONAKCI or kind == EKind.BALCIK else 86.0)))
	if kind == EKind.CARRIER and not elite:
		base_color = Color(1.0, 0.85, 0.45)
		G.fx.mk_light(self, Vector2(0, -18), Px.C("ffb74d"), 0.4, 1.4)
	if kind == EKind.MUHFIZ and not elite:
		base_color = Color(0.72, 0.88, 1.0)
		G.fx.mk_light(self, Vector2(0, -18), Px.C("80d8ff"), 0.35, 1.2)
	if elite:
		base_color = Color(0.9, 0.65, 1.0)
		var lc: String = {"armored": "8ea0b5", "volatile": "ff5533", "swift": "00E5FF", "sparked": "ffe066", "caller": "4dd0e1", "vampir": "d32f2f", "mender": "69f0ae", "split": "ff9e4d", "surucu": "c0ca33", "iz": "ff7043", "warp": "b388ff", "koruyucu": "80cbc4", "yansi": "ff8a65", "muhur": "7fdbff", "bile": "e1f5fe", "kristal": "80ffd4", "hortlak": "90a4ae", "dev": "ffab40", "cazibe": "ff6ee7", "ambarli": "c8e6c9", "kacak": "ffd54f", "fanatik": "ff5252", "bozucu": "ce93d8", "soguk": "bfe8ff", "yanki": "7986cb", "hayalet": "eceff1", "cilgin": "ff3d00"}.get(affix, "7B1FA2")
		G.fx.mk_light(self, Vector2(0, -18), Px.C(lc), 0.5, 1.6)
		if affix == "koruyucu":
			var aura := Sprite2D.new()
			aura.texture = Px.S("ring")
			aura.scale = Vector2.ONE * (420.0 / 72.0)
			aura.modulate = Color(0.5, 0.8, 0.77, 0.16)
			aura.z_index = -40
			add_child(aura)
		if affix == "muhur":
			_muhur_sp = Sprite2D.new()
			_muhur_sp.texture = Px.S("ring")
			_muhur_sp.scale = Vector2.ONE * ((radius * 2.4) / 72.0)
			_muhur_sp.modulate = Color(0.55, 0.85, 1.0, 0.0)
			_muhur_sp.z_index = 25
			add_child(_muhur_sp)
		_hp_bg = ColorRect.new()
		_hp_bg.color = Color(0.04, 0.02, 0.06, 0.85)
		_hp_bg.position = Vector2(-24, -80)
		_hp_bg.size = Vector2(48, 6)
		_hp_bg.z_index = 30
		add_child(_hp_bg)
		_hp_fg = ColorRect.new()
		_hp_fg.color = Px.C("ffb74d")
		_hp_fg.position = Vector2(1, 1)
		_hp_fg.size = Vector2(46, 4)
		_hp_bg.add_child(_hp_fg)
	# biome uyumu: sürü sahanın renk şemasına karışır
	if is_instance_valid(G.room) and G.room.biome >= 0:
		base_color = base_color.lerp(Px.C(BIOME_TINT[clampi(G.room.biome, 0, BIOME_TINT.size() - 1)]), 0.16)
	body.modulate = Color(0.2, 0.2, 0.2, 0)
	_orbit = -1.0 if G.chance(0.5) else 1.0

var _hp_bg: ColorRect
var _hp_fg: ColorRect

func _process(_d: float) -> void:
	if dead:
		return
	if is_instance_valid(_hp_fg):
		_hp_fg.size.x = 46.0 * clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var d := get_process_delta_time()
	tick(d)
	# balçık adam: son 2.5sn'dir hasar yemediyse çamurla kapanır (12 can/sn)
	if kind == EKind.BALCIK and not dead:
		_balcik_cd -= d
		if _balcik_cd <= 0.0 and hp < max_hp:
			hp = minf(hp + 12.0 * d, max_hp)
			_regen_fx -= d
			if _regen_fx <= 0.0:
				_regen_fx = 0.9
				G.fx.burst(pos + Vector2(0, -14), Px.C("6fbf73"), 4, 60.0, 2.2, 0.3)
	# çöpçü kurt: yakındaki kristalleri yutar — yuttuğu her parça onu besler
	if kind == EKind.COPCU and not dead and is_instance_valid(G.room):
		_scav_t -= d
		if _scav_t <= 0.0:
			_scav_t = 0.2
			for pk in G.room.pickups_node.get_children():
				if not is_instance_valid(pk) or str(pk.get_meta("kind", "")) != "xp":
					continue
				var pv := float(pk.get_meta("val", 0.0))
				if pos.distance_to(pk.position) < 32.0:
					_stolen += pv
					pk.queue_free()
					max_hp += minf(6.0, pv * 0.3)
					hp = minf(hp + minf(6.0, pv * 0.3), max_hp)
					G.fx.burst(pos + Vector2(0, -10), Px.C("d7a05a"), 5, 90.0, 2.0, 0.3)
					G.fx.float_text(pos + Vector2(0, -34), "yuttu", Px.C("d7a05a"), 0.7)
	if stagger > 0:
		_cancel_attack()
		return
	if G.state != G.State.ROOM or G.player == null or G.player.dead:
		return
	match _st:
		St.RISE:
			_rise_t -= d
			if is_instance_valid(body):
				var a := clampf(1.0 - _rise_t / 0.55, 0.0, 1.0)
				body.modulate = Color(a, a, a, a)
			if _rise_t <= 0:
				_st = St.SEEK
				body.modulate = base_color
				if _revive_pending:
					_revive_pending = false
					hp = max_hp * 0.4
					G.fx.burst(pos, Px.C("90a4ae"), 18, 160.0, 4.0, 0.5)
					G.fx.float_text(pos + Vector2(0, -44), "HORTLAK", Px.C("90a4ae"), 0.9)
					G.audio.play("roar", 0.7, 0.4)
		St.SEEK: _seek(d)
		St.WINDUP: _windup(d)
		St.STRIKE: _strike(d)
		St.RECOVER:
			_state_t -= d
			if _state_t <= 0:
				_st = St.SEEK
				_release_tok()
				_set_anim("idle", 5.0)
	# sparked elite: periodic lightning strike on a close player
	if affix == "sparked":
		_spk_t -= d
		if _spk_t <= 0.0:
			_spk_t = 2.4
			if pos.distance_to(G.player.pos) < 240.0:
				G.player.take_hit({"dmg": maxf(4.0, touch_dmg * 0.5), "type": G.DamageType.SHOCK, "from": pos + Vector2(0, -40), "knock": 0.0, "source": self})
				G.fx.light_flash(G.player.pos + Vector2(0, -24), Px.C("ffe066"), 1.2, 1.6, 0.12)
				G.fx.directional(G.player.pos + Vector2(0, -60), Vector2.DOWN, Px.C("ffe066"), 4, 200.0, 2.5, 0.14)
	# yankıcı elit: periyodik şok halkası — telegraph sonrası genişleyen itme dalgası
	if affix == "yanki":
		_yanki_t -= d
		if _yanki_t <= 0.0:
			_yanki_t = 4.2
			_yanki_hit = 0.7
			G.fx.tele_circle(pos, 175.0, 0.7, Color(0.47, 0.53, 0.8, 0.32))
			G.audio.play("ui", 0.5, 0.3)
		if _yanki_hit > 0.0:
			_yanki_hit -= d
			if _yanki_hit <= 0.0:
				G.fx.burst(pos, Px.C("7986cb"), 16, 220.0, 3.4, 0.35)
				G.fx.light_flash(pos, Px.C("7986cb"), 1.4, 1.8, 0.16)
				if G.player != null and not G.player.dead and pos.distance_to(G.player.pos) < 185.0:
					G.player.take_hit({"dmg": maxf(4.0, touch_dmg * 0.4), "type": G.DamageType.SHOCK, "from": pos, "knock": 20.0, "source": self})
	# çağırıcı elit: periyodik olarak varl dölleri saçar — öncelik hedef olur
	if affix == "caller" and _sum_n < 8:
		_sum_t -= d
		if _sum_t <= 0.0:
			_sum_t = 6.5
			_sum_n += 2
			for i in 2:
				var off := Vector2.RIGHT.rotated(TAU * i / 2.0 + G.rf(0, 0.8)) * 42.0
				Enemy.spawn(EKind.VARL, pos + off, false, G.run.hp_scale() * 0.6, G.run.dmg_scale() * 0.8, G.room)
			G.fx.burst(pos + Vector2(0, -14), Px.C("4dd0e1"), 10, 120.0, 4.0, 0.4)
			G.audio.play("roar", 1.6, 0.3)
	# şifalı elit: yakın sürü üyelerini periyodik onarır — öncelik hedef olur
	if affix == "mender":
		_mend_t -= d
		if _mend_t <= 0.0:
			_mend_t = 2.0
			var mn := 0
			for e in G.enemies:
				if e != self and is_instance_valid(e) and not e.dead and pos.distance_to(e.pos) < 180.0 and e.hp < e.max_hp:
					e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.05)
					mn += 1
			if mn > 0:
				G.fx.burst(pos + Vector2(0, -14), Px.C("69f0ae"), 10, 140.0, 4.0, 0.4)
	# sürücü elit: yakın sürüye hız aurası yayar — öncelik hedef olur
	if lead_t > 0.0:
		lead_t -= d
	if affix == "surucu":
		_lead_pulse -= d
		if _lead_pulse <= 0.0:
			_lead_pulse = 0.6
			var ln := 0
			for e in G.enemies:
				if e != self and is_instance_valid(e) and not e.dead and pos.distance_to(e.pos) < 220.0:
					e.lead_t = 0.75
					ln += 1
			if ln >= 3:
				G.fx.tele_ring(pos, 220.0, 0.45, Color(0.75, 0.8, 0.2, 0.35))
	# buz ruhu: süzülürken altında kısa ömürlü buz serer — zemini kayganlaştırır
	if kind == EKind.BUZRUH and _st == St.SEEK and is_instance_valid(G.room):
		_frost_t -= d
		if _frost_t <= 0.0:
			_frost_t = 3.4
			G.room.add_slowzone(pos, 46.0, 6.5, Color(0.55, 0.85, 1.0, 0.25))
	# koro sözcüsü: çan aurası — yakın sürüye hız yükler, arka hattan tollar
	if kind == EKind.HERALD and _st == St.SEEK:
		_herald_t -= d
		if _herald_t <= 0.0:
			_herald_t = 5.5
			var bn := 0
			for e in G.enemies:
				if e != self and is_instance_valid(e) and not e.dead and pos.distance_to(e.pos) < 250.0:
					e.lead_t = maxf(e.lead_t, 2.4)
					bn += 1
			if bn >= 2:
				G.fx.tele_ring(pos, 250.0, 0.5, Color(1.0, 0.85, 0.35, 0.35))
				G.audio.play("boon", 0.7, 0.3)
	# iz süren elit: ardında kısa ömürlü kor birikintileri bırakır — pozisyon baskısı
	if affix == "iz" and _st == St.SEEK:
		_trail_t -= d
		if _trail_t <= 0.0 and is_instance_valid(G.room) and pos.distance_to(G.player.pos) < 620.0:
			_trail_t = 0.9
			var ds2: float = G.director._dmg_scale() if G.director != null else 1.0
			G.room.add_hazard(pos + Vector2(G.rf(-8, 8), G.rf(-8, 8)), 26.0, 8.0 * ds2, 2.6, Color(1.0, 0.45, 0.15, 0.5))
	# mühürlü elit: döngüsel hasarsızlık penceresi — halka belirirken vurma
	if affix == "muhur":
		if _muhur_win > 0.0:
			_muhur_win -= d
			if is_instance_valid(_muhur_sp):
				_muhur_sp.modulate.a = minf(0.5, _muhur_sp.modulate.a + d * 6.0)
		else:
			_muhur_t -= d
			if is_instance_valid(_muhur_sp) and _muhur_sp.modulate.a > 0.0:
				_muhur_sp.modulate.a = 0.0
			if _muhur_t <= 0.0:
				_muhur_t = 5.5
				_muhur_win = 1.6
				G.fx.tele_ring(pos, radius * 2.8, 0.35, Color(0.55, 0.85, 1.0, 0.5))
				G.audio.play("parry", 0.8, 0.3)
	# hayalet elit: döngüsel faz geçişi — saydamlaşır, vurulamaz, sürünün içinden akar
	if affix == "hayalet":
		if _hay_t > 0.0:
			_hay_t -= d
			if is_instance_valid(body):
				body.modulate = Color(base_color.r, base_color.g, base_color.b, 0.3)
			if _hay_t <= 0.0 and is_instance_valid(body):
				body.modulate = base_color
		else:
			_hay_cd -= d
			if _hay_cd <= 0.0:
				_hay_cd = 6.0
				_hay_t = 1.7
				G.fx.burst(pos, Px.C("eceff1"), 8, 110.0, 2.8, 0.3)
				G.audio.play("dash", 0.5, 0.22)
	# ışınlanan elit: uzak kalırsa oyuncunun yanına teleport eder — arka hat güvenli değil
	if affix == "warp" and _st == St.SEEK and is_instance_valid(G.room):
		_warp_t -= d
		if _warp_t <= 0.0 and pos.distance_to(G.player.pos) > 340.0:
			_warp_t = 3.8
			G.fx.burst(pos, Px.C("b388ff"), 10, 120.0, 4.0, 0.3)
			G.audio.play("dash", 2.6, 0.3)
			pos = G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * G.rf(160.0, 230.0)
			pos = G.room.clamp_pos(pos, radius)
			G.fx.burst(pos, Px.C("b388ff"), 10, 120.0, 4.0, 0.3)
	# cazibe elit: saçılan kristalleri kendine çeker ve yutar — her kristal onu onarır,
	# oyuncunun XP hasadını keser; öldürmek için öncelik hedefi
	if affix == "cazibe" and is_instance_valid(G.room) and is_instance_valid(G.room.pickups_node):
		for pk in G.room.pickups_node.get_children():
			if str(pk.get_meta("kind", "")) != "xp":
				continue
			var gd: float = pk.position.distance_to(pos)
			if gd < 300.0:
				pk.position = pk.position.move_toward(pos + Vector2(0, -10), 240.0 * d)
				if gd < 18.0:
					hp = minf(max_hp, hp + max_hp * 0.04 + float(pk.get_meta("val", 1.0)))
					G.fx.float_text(pos + Vector2(0, -30), "YUTTU", Px.C("ff6ee7"), 0.8)
					G.fx.burst(pos + Vector2(0, -14), Px.C("ff6ee7"), 5, 100.0, 3.0, 0.25)
					pk.queue_free()
	if _cd_t > 0:
		_cd_t -= d
	_tick_anim(d)

func _seek(d: float) -> void:
	# konvoy hamalı: oyuncuyu değil geçiş hattını izler — çıkışa varırsa ganimetiyle kaçar
	if has_meta("convoy_dir"):
		var cdir: Vector2 = get_meta("convoy_dir")
		pos += cdir * speed * 1.15 * d
		if is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
		if cdir.x != 0.0:
			body.flip_h = cdir.x < 0.0
		if pos.distance_to(get_meta("convoy_exit")) < 60.0:
			G.fx.float_text(pos + Vector2(0, -34), "ganimet kaçtı", Px.C("ffd700"), 0.7)
			G.fx.burst(pos, base_color, 8, 90.0, 3.0, 0.3)
			G.enemies.erase(self)
			queue_free()
		return
	# KAÇAK elit: oyuncudan köşeye kaçar — yakalanana dek baskı yok, ganimeti bol
	if affix == "kacak" and is_instance_valid(G.player):
		var fdir: Vector2 = (pos - G.player.pos).normalized()
		pos += fdir * speed * 1.2 * d
		if is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
		if fdir.x != 0.0:
			body.flip_h = fdir.x < 0.0
		return
	var to_p: Vector2 = G.player.pos - pos
	var dist := to_p.length()
	# arena leash: far stragglers recycle back onto the off-screen ring
	if dist > 1500.0 and G.room is Arena:
		pos = G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * G.rf(700.0, 860.0)
		pos = G.room.clamp_pos(pos, radius)
		to_p = G.player.pos - pos
		dist = to_p.length()
	var dir := to_p.normalized()
	# separation — bounded checks, hordes stay O(n)
	var _seen := 0
	for o in G.enemies:
		if o == self or o.dead:
			continue
		_seen += 1
		if _seen > 10:
			break
		var away: Vector2 = pos - o.pos
		var dd := away.length()
		if dd < radius + o.radius + 5.0 and dd > 0.01:
			dir += away.normalized() * (1.2 - dd / 40.0) * 1.4
	if kind == EKind.SPITTER or kind == EKind.CEREB:
		if dist < keep_min:
			dir = -dir
		elif dist < keep_max:
			dir = dir.rotated(PI / 2 * sin(Time.get_ticks_msec() * 0.0008))
	var spd := speed * (1.28 if lead_t > 0.0 else 1.0) * (1.4 if (affix == "hayalet" and _hay_t > 0.0) else 1.0) * ((1.0 + (1.0 - hp / maxf(1.0, max_hp)) * 0.9) if affix == "cilgin" else 1.0) * (2.3 if _burrowed else 1.0) * (2.2 if _dive_t > 0.0 else 1.0) * (1.55 if _phased else 1.0) * (0.5 if chill_t > 0.0 else 1.0) * (0.72 if (is_instance_valid(G.player) and G.player.has_meta("wall") and pos.distance_to(G.player.pos) < 150.0) else 1.0)
	var mdir := dir
	if kind == EKind.KOCBASI:
		if _charge_t > 0.0:
			mdir = _charge_dir; spd = 640.0
		elif _charge_w > 0.0:
			mdir = Vector2.ZERO
	if spd > 0 and mdir != Vector2.ZERO:
		pos += mdir.normalized() * spd * d
		if is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
	_face_p()
	# akrep: uzaktayken kuma gömülür — gömülüyken vurulamaz, iki kat hızlı
	if kind == EKind.AKREP:
		if _burrowed:
			_burrow_t -= d
			if _burrow_t <= 0.0:
				_burrowed = false
				hit_radius = 15.0
				_cd_t = 0.0   # yüzeye çıkar çıkmaz hamleye hazır
				if is_instance_valid(body):
					body.modulate = base_color
				G.fx.burst(pos, Px.C("e8a050"), 14, 120.0, 3.5, 0.4)
		else:
			_burrow_cd -= d
			if _burrow_cd <= 0.0 and dist > 260.0:
				_burrowed = true
				_burrow_t = 1.1
				_burrow_cd = 4.5
				hit_radius = 0.0
				if is_instance_valid(body):
					body.modulate = Color(1.0, 0.85, 0.5, 0.3)
				G.fx.burst(pos, Px.C("e8a050"), 10, 100.0, 3.0, 0.35)
	# kocbası: 200-430 mesafede telegraph'lı şarj — 0.7sn durur, sonra sabit yönde devrilir
	if kind == EKind.KOCBASI:
		if _charge_w > 0.0:
			_charge_w -= d
			if _charge_w <= 0.0:
				_charge_t = 0.85
				_charge_hit = false
				G.fx.kill_tele(_ctele)
				_ctele = {}
				G.audio.play("dash", 0.7, 0.5)
		elif _charge_t > 0.0:
			_charge_t -= d
			if not _charge_hit and is_instance_valid(G.player) and not G.player.dead and pos.distance_to(G.player.pos) < radius + G.player.hit_radius + 8.0:
				_charge_hit = true
				G.player.take_hit({"dmg": touch_dmg * 1.4, "type": G.DamageType.MELEE, "from": pos, "knock": 12.0, "source": self})
		elif _st == St.SEEK and dist > 190.0 and dist < 440.0:
			_charge_cd -= d
			if _charge_cd <= 0.0:
				_charge_cd = 3.4
				_charge_w = 0.7
				_charge_dir = (G.player.pos - pos).normalized()
				var ang := rad_to_deg(_charge_dir.angle())
				_ctele = G.fx.tele_wedge(pos, ang, 330.0, 0.7)
	# kuzgun: uzaktayken dalışa geçer — 0.55sn boyunca iki kat hızla üstüne gelir
	if kind == EKind.KUZGUN:
		if _dive_t > 0.0:
			_dive_t -= d
		elif dist > 180.0:
			_dive_cd -= d
			if _dive_cd <= 0.0:
				_dive_t = 0.55
				_dive_cd = 2.4
				G.fx.directional(pos, dir, Px.C("5e3f8c"), 8, 140.0, 3.0, 0.3)
	# ufuk tayfı: periyodik olarak dağılıp belirir — dağılmışken vurulamaz, daha hızlı süzülür
	if kind == EKind.TAYF:
		if _phased:
			_phase_t -= d
			if _phase_t <= 0.0:
				_phased = false
				_phase_cd = 5.5
				hit_radius = 14.0
				if is_instance_valid(body):
					body.modulate = base_color
				G.fx.burst(pos, Px.C("7fe8d8"), 12, 110.0, 3.2, 0.4)
		else:
			_phase_cd -= d
			if _phase_cd <= 0.0:
				_phased = true
				_phase_t = 1.3
				hit_radius = 0.0
				if is_instance_valid(body):
					body.modulate = Color(0.6, 1.0, 0.9, 0.32)
				G.fx.burst(pos, Px.C("7fe8d8"), 8, 90.0, 2.6, 0.3)
	# çılgın elit: can yarısının altına düşünce öfkelenir — kırmızı kıvılcım püskürtür
	if affix == "cilgin" and hp < max_hp * 0.5:
		_cil_t -= d
		if _cil_t <= 0.0:
			_cil_t = 0.8
			G.fx.burst(pos + Vector2(0, -14), Px.C("ff3d00"), 3, 60.0, 2.0, 0.2)
		if _st == St.SEEK and is_instance_valid(body):
			body.modulate = Color(1.6, 0.7, 0.55) if hp < max_hp * 0.25 else base_color
	# döl yuması: sabit kuluçka — periyodik yavru kusar, yok edilene dek sürüyü besler
	if kind == EKind.DOL:
		_dol_t -= d
		if _dol_t <= 0.0:
			_dol_t = 4.2
			_dol_kids = _dol_kids.filter(func(c): return is_instance_valid(c) and not c.dead)
			if _dol_kids.size() < 5 and is_instance_valid(G.run) and is_instance_valid(G.room):
				var doff := Vector2.RIGHT.rotated(G.rf(0, TAU)) * 30.0
				var kid := Enemy.spawn(EKind.VARL, pos + doff, false, G.run.hp_scale() * 0.5, G.run.dmg_scale() * 0.7, G.room)
				if is_instance_valid(kid):
					_dol_kids.append(kid)
				G.fx.burst(pos + Vector2(0, -10), Px.C("9ccc65"), 9, 80.0, 2.6, 0.4)
				G.audio.play("hurt", 1.4, 0.2)
	# stealth: player hidden briefly after dash
	var seen := G.player.stealth_t <= 0
	if _cd_t <= 0 and seen and not _burrowed:
		match kind:
			EKind.TURRET:
				if dist < 400.0: _begin_windup()
			EKind.SPITTER, EKind.CEREB, EKind.HERALD, EKind.GOZETMEN, EKind.DINAMITCI:
				if dist < keep_max + 40.0: _begin_windup()
			EKind.DRONE:
				if dist < 55.0: _begin_windup()
			EKind.HUSK, EKind.SENTINEL, EKind.VARL, EKind.KONAKCI, EKind.ALFA, EKind.AKREP, EKind.BALCIK, EKind.COPCU, EKind.KUZGUN, EKind.KOCBASI, EKind.DAMARGOL, EKind.SIVRI, EKind.FISILTI, EKind.KORP, EKind.TAYF, EKind.EMICI:
				if dist < 110.0:
					if _has_tok or G.melee_tokens > 0:
						if not _has_tok:
							_has_tok = true
							G.melee_tokens -= 1
						_begin_windup()
					else:
						# attack director full — orbit the player instead of crowding
						pos += dir.rotated(PI / 2 * _orbit) * spd * 0.55 * d
						pos = G.room.clamp_pos(pos, radius) if is_instance_valid(G.room) else pos

func _begin_windup() -> void:
	_st = St.WINDUP
	_state_t = windup_t
	_set_anim("windup", 6.0)
	if is_instance_valid(body):
		body.modulate = Color(1.5, 0.45, 0.35)
	if kind == EKind.DRONE:
		_tele = G.fx.tele_circle(pos, 55.0, windup_t, Color(1, 0.3, 0.1, 0.3))
		_tele["follow"] = self
	elif kind in [EKind.HUSK, EKind.SENTINEL, EKind.VARL, EKind.KONAKCI, EKind.ALFA, EKind.AKREP, EKind.BALCIK, EKind.COPCU, EKind.KOCBASI, EKind.DAMARGOL, EKind.KORP, EKind.EMICI]:
		var ang := rad_to_deg((G.player.pos - pos).angle())
		var wlen := 96.0 if kind == EKind.BALCIK else (104.0 if kind == EKind.KONAKCI else 78.0)
		_tele = G.fx.tele_wedge(pos, ang, wlen, windup_t)
	G.audio.play("ui", 0.6, 0.3)

func _windup(d: float) -> void:
	_state_t -= d
	_face_p()
	if _state_t <= 0:
		_st = St.STRIKE
		_state_t = 0.22
		_strike_dir = (G.player.pos - pos).normalized()
		G.fx.kill_tele(_tele)
		_tele = {}
		_set_anim("strike", 8.0)
		if is_instance_valid(body):
			body.modulate = base_color
		_do_strike()

func _strike(d: float) -> void:
	_state_t -= d
	if kind in [EKind.HUSK, EKind.SENTINEL, EKind.VARL, EKind.KONAKCI, EKind.ALFA, EKind.BALCIK, EKind.COPCU, EKind.KOCBASI, EKind.DAMARGOL, EKind.SIVRI, EKind.FISILTI, EKind.KORP, EKind.EMICI]:
		var lunge := 320.0
		match kind:
			EKind.SENTINEL: lunge = 420.0
			EKind.VARL: lunge = 400.0
			EKind.ALFA: lunge = 470.0
			EKind.KONAKCI: lunge = 240.0
			EKind.BALCIK: lunge = 210.0
			EKind.COPCU: lunge = 380.0
			EKind.KOCBASI: lunge = 250.0
			EKind.SIVRI: lunge = 400.0
			EKind.FISILTI: lunge = 380.0
			EKind.KORP: lunge = 390.0
		pos += _strike_dir * lunge * d
		if is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
		if G.player != null and not G.player.dead and pos.distance_to(G.player.pos) < radius + G.player.hit_radius + 8.0:
			G.player.take_hit({"dmg": touch_dmg * (1.5 if (affix == "cilgin" and hp < max_hp * 0.4) else 1.0), "type": G.DamageType.MELEE, "from": pos, "knock": 5.0, "source": self})
			if affix == "vampir":
				hp = minf(hp + touch_dmg * 0.6, max_hp)
			# EMICI: teması parçacık emer — kesince kesesi geri döker
			if kind == EKind.EMICI and is_instance_valid(G.run) and G.player.invuln <= 0.0:
				var steal := minf(4.0, G.run.fragments)
				if steal > 0.0:
					G.run.fragments -= steal
					_stolen += steal
					G.fx.float_text(pos + Vector2(0, -34), "◈-%d" % int(steal), Px.C("6fd3c9"), 0.9)
					G.fx.burst(pos + Vector2(0, -8), Px.C("6fd3c9"), 6, 80.0, 2.4, 0.25)
			_state_t = 0
	if _state_t <= 0:
		_st = St.RECOVER
		_state_t = recover_t
		_cd_t = attack_cd

func _do_strike() -> void:
	match kind:
		EKind.SPITTER:
			_shoot_at(G.player.pos, proj_spd, proj_dmg, Px.C("39ff14"), 9.0)
		EKind.CEREB:
			_lob(G.player.pos)
		EKind.HERALD:
			_shoot_at(G.player.pos, proj_spd, proj_dmg, Px.C("e8d060"), 9.0)
		EKind.GOZETMEN:
			_shoot_at(G.player.pos, proj_spd, proj_dmg, Px.C("b388ff"), 13.0)
		EKind.DINAMITCI:
			_lob_keg(G.player.pos)
		EKind.TURRET:
			_burst_co()
		EKind.DRONE:
			_explode()

func _burst_co() -> void:
	for i in burst_n:
		if dead or G.player == null or G.player.dead:
			return
		var dir := (G.player.pos - pos).normalized().rotated(deg_to_rad(G.rf(-6, 6)))
		_shoot_dir(dir, proj_spd, proj_dmg, Px.C("ff4444"), 7.0)
		await get_tree().create_timer(burst_gap).timeout

func _shoot_at(target: Vector2, spd: float, dmg: float, col: Color, rad: float) -> void:
	_shoot_dir((target - pos).normalized(), spd, dmg, col, rad)

# mortar lob: mark the landing zone, the glob bursts there in an AoE
func _lob(target: Vector2) -> void:
	var dist := pos.distance_to(target)
	var flight := clampf(dist / proj_spd, 0.5, 1.6)
	var blast_r := 62.0
	G.fx.tele_circle(target, blast_r, flight, Color(0.6, 0.2, 1.0, 0.3))
	var p := Projectile.new()
	G.game.world.add_child(p)
	var dir := (target - pos).normalized()
	p.setup(G.Team.ENEMY, pos + dir * 16.0, dir * (dist / flight), proj_dmg, 12.0, Px.C("7B1FA2"), "dot")
	p.life = flight
	p.aoe = blast_r
	p.source = self
	G.audio.play("shoot", G.rf(0.7, 0.9), 0.5)

# dinamitçi fıçısı: barut iki tarafı da vurur — sürüye karşı kullanılabilir
func _lob_keg(target: Vector2) -> void:
	var dist := pos.distance_to(target)
	var flight := clampf(dist / 300.0, 0.5, 1.5)
	G.fx.tele_circle(target, 90.0, flight, Color(1.0, 0.55, 0.2, 0.3))
	var p := Projectile.new()
	G.game.world.add_child(p)
	var dir := (target - pos).normalized()
	p.setup(G.Team.ENEMY, pos + dir * 14.0, dir * (dist / flight), proj_dmg, 10.0, Px.C("ff7043"), "dot")
	p.life = flight
	p.aoe = 90.0
	p.both_sides = true
	p.source = self
	G.audio.play("shoot", 0.6, 0.5)

func _shoot_dir(dir: Vector2, spd: float, dmg: float, col: Color, rad: float) -> void:
	var p := Projectile.new()
	G.game.world.add_child(p)
	p.setup(G.Team.ENEMY, pos + dir * 16.0, dir * spd, dmg, rad, col, "dot")
	p.source = self
	G.audio.play("shoot", G.rf(0.9, 1.2), 0.4)

func _explode() -> void:
	G.audio.play("explode", 1.1, 0.7)
	G.fx.burst(pos + Vector2(0, -8), Px.C("ff7722"), 26, 220.0, 6.0, 0.5)
	G.fx.shake(0.2, 0.2)
	if G.player != null and not G.player.dead and pos.distance_to(G.player.pos) < 62.0:
		G.player.take_hit({"dmg": touch_dmg, "type": G.DamageType.EXPLOSION, "from": pos, "knock": 7.0, "source": self})
	die({"dmg": 9999.0, "type": G.DamageType.PURE, "from": pos, "source": self})

func _face_p() -> void:
	if is_instance_valid(body) and G.player != null:
		body.flip_h = G.player.pos.x < pos.x

func _release_tok() -> void:
	if _has_tok:
		_has_tok = false
		G.melee_tokens = mini(G.melee_tokens + 1, G.MELEE_TOKENS_MAX)

func _cancel_attack() -> void:
	if _st == St.WINDUP or _st == St.STRIKE:
		_st = St.SEEK
		_release_tok()
		_set_anim("idle", 5.0)
		G.fx.kill_tele(_tele)
		_tele = {}
		if is_instance_valid(body):
			body.modulate = base_color

# Kalkan Muhafızı: cepheden gelen darbe kalkana çarpar — arkadan vur
func take_hit(h: Dictionary) -> void:
	if affix != "koruyucu":
		for e2 in G.enemies:
			if is_instance_valid(e2) and not e2.dead and e2.affix == "koruyucu" and e2 != self and e2.pos.distance_to(pos) < 210.0:
				h["dmg"] = float(h.get("dmg", 0.0)) * 0.5
				if not h.has("_ward_fx"):
					h["_ward_fx"] = true
					G.fx.burst(pos + Vector2(0, -16), Px.C("80cbc4"), 5, 70.0, 2.6, 0.22)
				break
	# MÜHÜRLÜ: mühür penceresi açıkken gelen hasar sıfırlanır — zamanlamayı oku
	if affix == "muhur" and _muhur_win > 0.0:
		h["dmg"] = 0.0
		if not h.has("_muhur_fx"):
			h["_muhur_fx"] = true
			G.fx.burst(pos + Vector2(0, -16), Px.C("7fdbff"), 4, 70.0, 2.4, 0.2)
			G.audio.play("parry", 1.4, 0.18)
	# HAYALET: faz geçişindeyken vurulamaz — saydam hali gör, pencere kapanınca yanıtla
	if affix == "hayalet" and _hay_t > 0.0:
		h["dmg"] = 0.0
		if not h.has("_hay_fx"):
			h["_hay_fx"] = true
			G.fx.burst(pos + Vector2(0, -16), Px.C("eceff1"), 4, 60.0, 2.2, 0.2)
			G.audio.play("dash", 1.8, 0.14)
	if kind == EKind.MUHFIZ and is_instance_valid(G.player) and h.has("from"):
		var fw := (G.player.pos - pos).normalized()
		var aw := (Vector2(h.get("from")) - pos).normalized()
		if fw.dot(aw) > 0.35:
			h["dmg"] = float(h.get("dmg", 0.0)) * 0.25
			if not h.has("_shield_fx"):
				h["_shield_fx"] = true
				G.fx.burst(pos + aw * 20.0 + Vector2(0, -10), Px.C("80d8ff"), 6, 90.0, 3.0, 0.25)
				G.audio.play("dash", 2.2, 0.25)
	super.take_hit(h)
	if kind == EKind.BALCIK and float(h.get("dmg", 0.0)) > 0.0:
		_balcik_cd = 2.5
	if _st == St.RISE:
		_rise_t = minf(_rise_t, 0.15)
	# YANSITICI: hasarın %12'si saldırana geri sıçrar
	if affix == "yansi" and h.get("source") == G.player and is_instance_valid(G.player):
		var rd := float(h.get("dmg", 0.0)) * 0.12
		if rd > 0.5 and not dead:
			G.player.take_hit({"dmg": rd, "type": G.DamageType.SHOCK, "from": pos, "source": self})
			G.fx.burst(pos + Vector2(0, -18), Px.C("ff8a65"), 4, 80.0, 2.4, 0.2)

func die(h: Dictionary) -> void:
	if dead:
		return
	# HORTLAK elit: ilk ölümde çöker, 1.6sn sonra %40 canla dirilir — yükselirken vurulursa kalıcı ölür
	if affix == "hortlak" and not _revived and is_instance_valid(G.room):
		_revived = true
		_revive_pending = true
		affix = ""
		hp = 0.0
		_release_tok()
		G.fx.kill_tele(_tele)
		_st = St.RISE
		_rise_t = 1.6
		G.fx.tele_circle(pos, 58.0, 1.6, Color(0.45, 0.55, 0.7, 0.3))
		G.fx.float_text(pos + Vector2(0, -44), "hortlak diriliyor", Px.C("90a4ae"), 0.9)
		G.audio.play("ui", 0.5, 0.4)
		return
	if kind == EKind.BUZRUH and is_instance_valid(G.room):
		G.room.add_slowzone(pos, 58.0, 8.0, Color(0.55, 0.85, 1.0, 0.28))
		G.fx.burst(pos, Px.C("a8dcff"), 12, 160.0, 4.0, 0.5)
	_release_tok()
	G.fx.kill_tele(_tele)
	super.die(h)
	G.enemies.erase(self)
	G.meta.data.kills += 1
	if bool(h.get("keg", false)):
		G.meta.data["keg_kills"] = int(G.meta.data.get("keg_kills", 0)) + 1
		G.fx.float_text(pos + Vector2(0, -44), "kovanın ateşi", Px.C("ff7043"), 0.7)
	if is_instance_valid(G.run):
		G.run.stats.kills = int(G.run.stats.get("kills", 0)) + 1
		var kk: Dictionary = G.run.stats.get("kind_kills", {})
		var kn := str(KIND_NAME.get(kind, actor_name))
		kk[kn] = int(kk.get(kn, 0)) + 1
		G.run.stats["kind_kills"] = kk
		G.run.on_kill(elite)
		Quests.tick("kind", kn)
		if is_instance_valid(G.room) and float(G.room.storm_t) > 0.0:
			if G.room.biome == 8:
				Quests.tick("bora")      # donmus bora altinda kesim
			else:
				Quests.tick("firtina")   # kum firtinasi sirasinda kesim
		# zehir tuzagi: gaz havuzunun icinde dusenler sayilir
		if is_instance_valid(G.room):
			for hz in G.room.hazards:
				if str(hz.get("kind", "")) == "toxic" and pos.distance_to(hz.pos) < float(hz.get("r", 0.0)):
					Quests.tick("zehir")
					break
		if bool(h.get("ark", false)):
			Quests.tick("ark")   # Sol Primus zincir yildirimiyla dusen kesim
		if bool(h.get("sarkit", false)):
			Quests.tick("sarkit")   # maden sarkıtının altında düşen kesim
		# gizli bataklık olayı: 30 sivri kesilirse bulutun kalbi kızar
		if kind == EKind.SIVRI and int(kk.get(kn, 0)) == 30 and not bool(G.run.stats.get("dol_anasi", false)) and G.run.biome == 4 and is_instance_valid(G.room):
			G.run.stats["dol_anasi"] = true
			G.ui.banner("DÖL ANASI", "bulutun kalbi seni buldu")
			G.audio.play("roar", 1.0, 0.6)
			var anasi := Enemy.spawn(EKind.KONAKCI, G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * 380.0, true, 1.4, 1.2, G.room)
			if anasi != null:
				anasi.promote_champ()
				anasi.actor_name = "DÖL ANASI"
	G.audio.play("die", G.rf(0.9, 1.2), 0.6)
	G.fx.light_flash(pos + Vector2(0, -12), Color(1, 0.5, 0.3), 1.4, 2.4, 0.2)
	var kcol := Px.C(str(KIND_COL.get(kind, "801020")))
	G.fx.burst(pos + Vector2(0, -10), kcol.darkened(0.45), 30 if elite else 16, 190.0, 5.0, 0.6, 6.0)
	G.fx.burst(pos + Vector2(0, -10), kcol.lerp(Color(1, 0.9, 0.6), 0.4), 8 if elite else 4, 210.0, 3.0, 0.3)
	if elite:
		G.fx.hitstop(0.05)
		G.fx.boom(pos, Px.C("ffb74d"), 80.0)
	G.fx.splat(pos + Vector2(0, 4), kcol.darkened(0.6), 1.4 if elite else 0.8)
	if kind == EKind.DRONE or kind == EKind.SPITTER:
		G.fx.burst(pos + Vector2(0, -6), Px.C("00E676"), 12, 130.0, 4.0, 0.5)
	if splits > 0 and is_instance_valid(G.room) and G.state == G.State.ROOM:
		for i in splits:
			var off := Vector2.RIGHT.rotated(TAU * float(i) / float(splits) + G.rf(0, 0.6)) * 30.0
			Enemy.spawn(EKind.VARL, pos + off, false, 0.5, 0.7, G.room)
		G.fx.burst(pos, Px.C("8dc63f"), 14, 150.0, 4.0, 0.4)
	if is_instance_valid(G.room):
		# XP gem every kill; elites also drop a chest; rare heal orb
		var xp_tbl := [1.0, 2.0, 3.0, 1.0, 3.0, 1.0, 3.0, 6.0, 5.0, 7.0, 6.0, 5.0, 3.0, 7.0, 5.0, 4.0, 4.0, 2.0, 0.5, 4.0, 6.5, 0.5, 4.5, 4.5, 5.0, 4.5]
		var xp_val: float = (float(xp_tbl[kind]) if kind < xp_tbl.size() else 4.0) + (10.0 if elite else 0.0)
		G.room.spawn_gem(pos, xp_val)
		if _stolen > 0.0:
			# yuttuğu kristaller faiziyle geri döner
			G.room.spawn_gem(pos + Vector2(G.rf(-14, 14), 0), _stolen * 1.25)
			G.fx.burst(pos, Px.C("d7a05a"), 10, 120.0, 3.0, 0.4)
			G.fx.float_text(pos + Vector2(0, -40), "ganimet geri alındı", Px.C("d7a05a"), 0.9)
		if elite:
			G.room.spawn_chest(pos)
			G.run.drop_fragments(pos, G.ri(8, 14))
			if champ:
				# altın katman ödülü: ikinci sandık + garanti eşya + ağır parçacık
				G.room.spawn_chest(pos + Vector2(30, 0))
				G.run.drop_fragments(pos + Vector2(0, 12), G.ri(30, 45))
				var iid2 := Items.roll(G.run.luck + 0.4)
				if iid2 != "":
					G.room.spawn_loot(iid2, pos + Vector2(0, -26))
				G.run.stats["champ_kills"] = int(G.run.stats.get("champ_kills", 0)) + 1
				G.meta.data["champs"] = int(G.meta.data.get("champs", 0)) + 1
				if has_meta("midboss"):
					Quests.tick("orta")
				if has_meta("duel"):
					Quests.tick("duel")
				# EFSANEVİ düşüş: r4 parça sadece altın şampiyon katmanından kopar
				var leg_p := 0.10 + (0.25 if has_meta("midboss") else 0.0)
				var lids := Items.legendary_ids()
				if not lids.is_empty() and G.chance(leg_p):
					G.room.spawn_loot(G.pick(lids), pos + Vector2(-30, 0))
					G.ui.toast("EFSANEVİ PARÇA düştü")
					G.audio.play("roar", 0.8, 0.5)
				G.fx.shake(0.3, 0.45)
			if has_meta("nemesis"):
				var nl2 := int(get_meta("nemesis"))
				G.meta.data["nemesis_lvl"] = nl2
				G.meta.data["nemesis_kills"] = int(G.meta.data.get("nemesis_kills", 0)) + 1
				G.meta.save()
				G.run.drop_fragments(pos + Vector2(0, 24), 20 + nl2 * 8)
				G.ui.toast("KOPUZ düştü — kovan onu yeniden kuracak")
				# üç perdelik kan davası çözülünce KOPUZ mirasını bırakır
				if nl2 >= 3:
					var lids2 := Items.legendary_ids()
					if not lids2.is_empty():
						G.room.spawn_loot(G.pick(lids2), pos + Vector2(-44, 10))
						G.ui.toast("KOPUZ'un mirası — EFSANEVİ PARÇA düştü")
			G.run.stats["elite_kills"] = int(G.run.stats.get("elite_kills", 0)) + 1
			if affix != "":
				var ak: Dictionary = G.run.stats.get("affix_kills", {})
				ak[affix] = int(ak.get(affix, 0)) + 1
				G.run.stats["affix_kills"] = ak
				Quests.tick("affix", affix)
			Quests.tick("elites")
			G.fx.flash(Px.C("ffd75f"), 0.13)
			G.fx.shake(0.16, 0.25)
			# eşya düşüşü — node "loot" modu şansı büyütür
			var loot_mod := float(G.run.node_mods.get("loot", 1.0)) if is_instance_valid(G.run) else 1.0
			if G.chance(0.14 * loot_mod):
				var iid := Items.roll(G.run.luck)
				if iid != "":
					G.room.spawn_loot(iid, pos + Vector2(0, -18))
			if is_instance_valid(G.player) and G.player.has_meta("elite_heal"):
				G.player.heal(8.0)
			if has_meta("patrol"):
				var iid3 := Items.roll(G.run.luck + 0.2)
				if iid3 != "":
					G.room.spawn_loot(iid3, pos + Vector2(-20, 14))
				G.run.drop_fragments(pos + Vector2(20, 10), 12)
				G.ui.toast("devriye başı düştü — zula açıldı")
				Quests.tick("devriye")
			if actor_name.contains("HASATÇI"):
				G.meta.data["reapers"] = int(G.meta.data.get("reapers", 0)) + 1
				G.meta.save()
			if G.chance(0.12):
				G.room.spawn_special(G.pick(["vacuum", "bomb", "freeze", "boost", "guard", "iksir", "sarap"]), pos)
			# altın nüve: nadir kalıcı güç düşüşü (VS golden egg)
			if G.chance(0.03):
				G.room.spawn_special("egg", pos)
			# veri kütüğü: ÖYKÜ codex'ini besleyen lore parçası
			if G.chance(0.07) and (G.meta.data.get("lore", []) as Array).size() < Quests.LORE.size():
				G.room.spawn_special("lore", pos + Vector2(0, 16))
			# lanetli sandık: ödülü pusuya bağlı riskli ganimet (BG2 mimic)
			if G.chance(0.05):
				G.room.spawn_special("cursed", pos + Vector2(-18, 0))
			# ambarlı elit: erzak taşır — garanti iksir + kristal saçılımı
			if affix == "ambarli":
				G.room.spawn_special("iksir", pos + Vector2(0, 12))
				G.room.spawn_special(G.pick(["boost", "guard", "vacuum"]), pos + Vector2(-20, 0))
				for gi in 3:
					G.room.spawn_gem(pos + Vector2(G.rf(-30, 30), G.rf(-24, 24)), G.rf(4.0, 8.0))
		elif G.chance(0.12):
			G.run.drop_fragments(pos, G.ri(1, 3))
	# volatile elite: telegraphed blast after death
	if elite and affix == "volatile":
		var warn := Sprite2D.new()
		warn.texture = Px.S("ring")
		warn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		warn.modulate = Color(1.0, 0.35, 0.2, 0.8)
		warn.position = pos
		warn.z_index = 40
		var host: Node = G.room if is_instance_valid(G.room) else G.game.world
		host.add_child(warn)
		var blast_pos := pos
		var bd := touch_dmg * 1.2
		var tw := warn.create_tween()
		tw.tween_property(warn, "scale", Vector2.ONE * (236.0 / 72.0), 0.55)
		tw.tween_callback(func():
			if is_instance_valid(warn):
				warn.queue_free()
			if is_instance_valid(G.player) and not G.player.dead and G.player.pos.distance_to(blast_pos) < 118.0:
				G.player.take_hit({"dmg": bd, "type": G.DamageType.EXPLOSION, "from": blast_pos, "knock": 14.0, "source": null})
			G.fx.burst(blast_pos, Color(1.0, 0.45, 0.15), 26, 240.0, 6.0, 0.5)
			G.fx.boom(blast_pos, Color(1.0, 0.5, 0.2), 110.0)
			G.fx.light_flash(blast_pos, Color(1, 0.6, 0.2), 2.2, 3.0, 0.25)
			G.audio.play("explode", 0.9, 0.7)
			G.fx.shake(0.18, 0.2))
	# bölücü elit: ölünce iki husk'a ayrılır
	if elite and affix == "split" and is_instance_valid(G.room):
		var hs2 := G.run.hp_scale() if is_instance_valid(G.run) else 1.0
		var ds2 := G.run.dmg_scale() if is_instance_valid(G.run) else 1.0
		for i in 2:
			var sp := Enemy.spawn(EKind.HUSK, pos + Vector2(G.rf(-26.0, 26.0), G.rf(-26.0, 26.0)), false, hs2, ds2, G.room)
			if sp != null:
				sp.speed *= 1.15
		G.fx.float_text(pos, "BÖLÜNDÜ", Color(1.0, 0.62, 0.3), 16)
	# nadir şifa küresi — her kesimde %4.5 (mina yemeğiyle ×2, node "heal" moduyla ölçeklenir), KARANLIK'ta hiç
	var _noheal := G.run.dark or (is_instance_valid(G.run) and bool(G.run.node_mods.get("noheal", false)))
	var _heal_mod := float(G.run.node_mods.get("heal", 1.0)) if is_instance_valid(G.run) else 1.0
	if is_instance_valid(G.room) and G.chance(0.045 * (2.0 if is_instance_valid(G.player) and G.player.has_meta("heal_luck") else 1.0) * _heal_mod) and not _noheal:
		G.room.spawn_heal(pos)
	# HASAT ŞENLİĞİ kozu: kesim başına küçük parçacık damlası
	if is_instance_valid(G.run) and is_instance_valid(G.player) and G.player.has_meta("harvest") and G.chance(0.02):
		G.run.drop_fragments(pos, 1)
	# kaçak elit: yakalanan ganimet — bol parçacık + ekstra eşya zararı
	if elite and affix == "kacak" and is_instance_valid(G.run):
		G.run.drop_fragments(pos, G.ri(14, 22))
		G.room.spawn_special(G.pick(["iksir", "boost", "guard", "vacuum", "cursed"]), pos + Vector2(G.rf(-30, 30), G.rf(-24, 24)))
		G.fx.burst(pos, Px.C("ffd54f"), 20, 170.0, 5.0, 0.5)
		G.fx.float_text(pos + Vector2(0, -52), "KAÇAK YAKALANDI", Px.C("ffd54f"), 0.95)
		G.run.stats["kacak_kills"] = int(G.run.stats.get("kacak_kills", 0)) + 1
		Quests.tick("kacak")
	# fanatik elit: ölüm narası — yakın sürü çılgına döner (kısa güçlü hız buffı)
	if elite and affix == "fanatik":
		for e4 in G.enemies:
			if is_instance_valid(e4) and not e4.dead and e4 != self and e4.pos.distance_to(pos) < 300.0:
				e4.lead_t = maxf(e4.lead_t, 6.0)
		G.fx.float_text(pos + Vector2(0, -52), "FANATİK NARASI", Px.C("ff5252"), 0.95)
		G.fx.tele_ring(pos, 300.0, 0.5, Color(1, 0.32, 0.2, 0.45))
		G.fx.burst(pos, Px.C("ff5252"), 16, 200.0, 5.0, 0.45)
	# kristalli elit: ölünce çevreye parçacık yağmuru saçar — damar yemi
	if elite and affix == "kristal" and is_instance_valid(G.run):
		G.run.drop_fragments(pos, G.ri(8, 14))
		G.fx.burst(pos, Px.C("80ffd4"), 18, 160.0, 5.0, 0.5)
		G.fx.float_text(pos + Vector2(0, -52), "DAMAR SAÇILDI", Px.C("80ffd4"), 0.9)
	# hamal taşıyıcı yükünü düşürür — rastgele saha kalıntısı
	if kind == EKind.CARRIER and is_instance_valid(G.room):
		G.room.spawn_special(G.pick(["vacuum", "bomb", "freeze", "boost", "guard", "iksir", "sarap"]), pos)
		G.fx.float_text(pos + Vector2(0, -40), "YÜK DÜŞTÜ", Px.C("ffb74d"), 0.9)
		# konvoy hamalı kesildi — çıkışa varmadan düşürülen ganimet
		if has_meta("convoy_dir"):
			G.run.drop_fragments(pos + Vector2(16, 8), 10)
			G.run.stats["convoy_kills"] = int(G.run.stats.get("convoy_kills", 0)) + 1
			Quests.tick("konvoy")
	if is_instance_valid(G.room):
		G.room.on_enemy_dead(self)
	queue_free()
