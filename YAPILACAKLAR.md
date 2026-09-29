# DÜŞÜŞ — Yapılacaklar

Bu dosya `duzeltmeler` dalıyla gelir. Önce **A** bölümündeki testleri yap, sonra
**B** bölümündeki kalan işlere geç. Kutucukları bitirdikçe işaretle.

> Not: Bu daldaki değişiklikler oynanarak test edilmedi. Yalnızca betiklerin
> hatasız derlendiği kontrol edildi. Oyunda bir sorun görürsen ilgili dosyaya
> bakarak geri alabilirsin (her değişikliğin yanında Türkçe bir açıklama var).

---

## A. Bu dalda yapılan düzeltmeler — TEST ET

### Görsel / okunabilirlik
- [ ] **Parlaklık** (`game.gd` → `set_dark` / `apply_brightness`)
  - Varsayılan parlaklık artık %130. Bataklık ve Kristal Çukur'a gir, oyuncu ve düşmanlar zeminden ayrılıyor mu?
  - ESC → "Parlaklık" butonu 100 → 115 → 130 → 145 → 160 arasında dönüyor mu, değişiklik anında görünüyor mu?
  - Oyunu kapatıp açınca ayar korunuyor mu?
  - Çok parlak ya da soluk görünen bir biome varsa, `room.gd` içindeki `DARK` listesinden o biome'u ayrıca ayarla.
- [ ] **Arena kenarındaki siyah blok** (`arena.gd` → `_vignette_arena`)
  - Arenanın 4 kenarına da yürü. Kenarın dışı artık düz karanlık olmalı. Siyah şerit ile parlak backdrop arasındaki keskin geçiş kaybolmalı.
  - Üst kenardaki testere dişli yarı saydam şerit hâlâ duruyorsa, `_edge_walls()` fonksiyonuna ayrıca bak. Bu dalda ona dokunulmadı.
- [ ] **Oyuncu halkası ve aura** (`player.gd`)
  - Oyuncunun ayağının altında cyan bir halka var mı, kalabalıkta oyuncu kolayca bulunuyor mu?
  - Halka düşmanların ya da efektlerin üstüne çizilmemeli. Çiziliyorsa `ring.z_index` değerini düşür.
- [ ] **Kamp kamerası** (`game.gd` → `ZOOM_HUB`)
  - Kamp ekranı doldurmalı, alt yarı boş kalmamalı.
  - Kampın her köşesine yürü: NPC'ler ve kapı ekranda kalıyor mu?
  - Portaldan arenaya geçince zoom yumuşakça 0.72'ye dönüyor mu?
- [ ] **Kampta HUD** (`ui.gd`): Kampta "00:00", "SEV 1", "0 kesim" ve ilerleme çubuğu görünmemeli. Arenada hepsi görünmeli.
- [ ] **Toast çakışması** (`ui.gd` → `toast` / `_relayout_toasts`)
  - Koşu başında birçok mesaj aynı anda çıkıyor. Hiçbiri üst üste binmemeli.
  - Aynı mesaj iki kez gelirse ikinci kopya eklenmemeli, sadece süresi uzamalı.
- [ ] **Yazı boyutu ve kontrast** (`ui.gd` → `_lbl`, `MIN_FONT := 12`)
  - Bütün panelleri tek tek aç: techizat, takas, dünya haritası, günlük (J), tüccar, ölüm ekranı, pause. Yazılar büyüdüğü için taşan ya da kesilen metin var mı?
  - Taşma olursa ya o panelin boyutunu büyüt ya da `MIN_FONT` değerini 11'e çek.
- [ ] **Ekran flaşları ayarı**: ESC → "Ekran flaşları: KAPALI" seçilince hasar alırken kırmızı flaş çıkmamalı.

### Hatalar
- [ ] **Koşudan koşuya sızan bayraklar** (`run.gd` → `start_run`): Lena'nın rotasını kullan, sonraki koşuda ekstra sandık ve kalıntı olmamalı. KAÇAK arcana'sı da bir sonraki koşuya taşınmamalı.
- [ ] **Pause'da ilerleyen olaylar** (`room.gd`, `boss.gd`, `enemy.gd`, `player.gd` — `create_timer(…, false)`):
  - Boss dövüşünde ESC'ye bas ve 10 saniye bekle. Boss saldırı deseni ilerlememeli.
  - Seviye atlama kartları açıkken yeni dalga gelmemeli.
  - Taret düşmanlarının seri ateşi pause'da durmalı.
- [ ] **Hitstop donması** (`fx.gd` → `clear_hitstop`, `ui.gd` → `_pause`): Elit ya da boss öldürdüğün anda seviye atlarsan kart paneli normal hızda açılmalı, ağır çekimde takılı kalmamalı.
- [ ] **Diyalog sonrası dash** (`ui.gd` → `_pause`): NPC diyaloğunu SPACE ile kapat. Karakter istemsiz dash atmamalı.
- [ ] **Düşman yığılması** (`enemy.gd` ayrışma döngüsü)
  - Kalabalıkta düşmanlar tek noktada üst üste binmemeli, biraz yayılmalı.
  - 150 ve üzeri düşmanda FPS'i kontrol et. Düşerse `16` sayısını 10'a indir.
- [ ] **Kayıt güvenliği** (`meta.gd` → `save` / `load`)
  - Kayıt klasöründe (`user://`) artık `.bak` dosyası da oluşmalı.
  - Ana kayıt dosyasını silip oyunu aç: ilerleme `.bak` dosyasından geri gelmeli.
  - Eski bir kayıtla aç: yeni ayarlar (parlaklık, flaş) varsayılan değerleriyle gelmeli, eski ayarlar kaybolmamalı.
- [ ] **Ses** (`audio.gd`, `ui.gd`)
  - Müzik seviyesini değiştir: ses sıçramamalı. Ayar ekranında ve oyun içinde aynı seviye duyulmalı.
  - Müzik "Music", efektler "SFX" bus'ından çalıyor. Hiçbir ses kaybolmamış olmalı.
- [ ] **Oyundan çık butonu** (`ui.gd`, `game.gd` → `quit_game`, `run.gd` → `bank_on_quit`)
  - Başlık ekranında ve pause menüsünde "OYUNDAN ÇIK" butonu var mı?
  - Koşu ortasında çık, tekrar gir: toplanan parçacıklar bankaya yatmış olmalı.
  - Pencerenin X tuşuyla kapatınca da aynı şey olmalı.
- [ ] **Numpad**: Kart seçerken numpad 1/2/3 tuşları da çalışmalı.
- [ ] **AZERTY klavye ve gamepad** (`player.gd` → `_read_input`)
  - Klavye düzenini Fransızca yap: fiziksel WASD tuşlarıyla hareket edilebilmeli.
  - Gamepad bağla: sol çubukla hareket, A tuşuyla dash çalışmalı.
- [ ] **Ekonomi tavanları** (`run.gd` → `SEFER_CAP = 8`, `REWARD_MULT_CAP = 6.0`)
  - Uzun bir sefer zinciri oyna: 8. ayaktan sonra zorluk ve ödül artışı durmalı.
  - Dengeyi oynayarak ayarla. İki sayı da dosyanın başında sabit olarak duruyor.

### Repo
- [ ] Tasarım dosyaları (ChatGPT görselleri, docx, pdf, Rena.gif) `docs/tasarim/` klasörüne taşındı. `docs/.gdignore` sayesinde Godot bunları import etmiyor ve export'a koymuyor. Editörü açınca eksik referans uyarısı çıkmamalı.

---

## B. Kalan işler — sıradaki adımlar

### Yüksek öncelik
- [ ] **Input Map'e geçiş:** Tüm `Input.is_key_pressed(KEY_…)` çağrılarını Proje Ayarları → Input Map eylemlerine (`move_up`, `dash`, `interact`…) taşı. Bu tuş atama menüsünün ve tam gamepad desteğinin ön şartı. Menüler şu an gamepad ile gezilemiyor.
- [ ] **Ayarlar menüsü:** çözünürlük/pencere modu, VSync, gerçek ses kaydırıcıları (şu an %25'lik adımlarla dönen buton), tuş atama, yazı boyutu, renk körlüğü modu.
- [ ] **Efekt okunabilirliği:** Düşman saldırıları için sabit bir renk kodu (örn. kırmızı/turuncu = tehlike, cyan/mor = oyuncu). Zehir ve nova bulutlarının kenarlarını netleştir, yarıçaplarını küçült.
- [ ] **Bildirimleri sadeleştir:** "KAYIT: … deftere işlendi" gibi ikincil mesajları ekran ortasından sol alttaki kısa bir log'a taşı.
- [ ] **Arena üst duvar şeridi:** Testere dişli yarı saydam bandı `_edge_walls()` içinde incele.

### Görsel kimlik
- [ ] Konsept art'taki grimdark çerçeve dilini (koyu metal paneller, kırmızı vurgu, ağır başlık fontu) bir Godot `Theme` kaynağına (`.tres`) taşı. Tüm panellere tek yerden uygula. Neon mor/cyan UI ile konsept arasındaki kopukluğu kapatır.
- [ ] Dünya haritasında düğüm etiketlerinin çakışmasını çöz (etiketleri kaydır ya da sadece üzerine gelince göster).
- [ ] Techizat ve takas panellerinde kontrastı artır.

### Kod
- [ ] `ui.gd` (≈4300 satır) dosyasını böl: `hud.gd`, `panels/*.gd`, `cinematic.gd`, `minimap.gd`.
- [ ] Sabit 1280×720 konumları anchor/container yapısına çevir (ultrawide için).
- [ ] Metinleri `tr()` ile çeviri tablosuna taşı (İngilizce sürüm için).
- [ ] Rastgelelik için her yerde `G.rng` kullan (`randi()` / `randf()` yerine). Seed'li günlük koşu için gerekli.
- [ ] Eski oda/kapı akışını (`next_room`, `ROOMS_PER_BIOME`) kullanılmıyorsa sil.
- [ ] Hasar sayıları için Label havuzu kur (`fx.gd`). Minimap'i her karede değil, 10 Hz'de çiz.

### Repo ve build
- [ ] Git LFS kur: `git lfs install` ve `git lfs track "*.png" "*.wav"`. Repo ~259 MB.
- [ ] `art_src/` içindeki `check_*`, `cand*`, `sel*`, `chk_*` deneme görsellerini sil. Sadece build scriptlerini tut.
- [ ] `export_presets.cfg` içindeki `C:/Users/PC/...` mutlak yolunu kaldır, bir oyun ikonu ekle.
- [ ] Büyük görselleri küçült: sinematik kartlar ~3 MB, portreler 1145×1374.
