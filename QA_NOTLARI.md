# DÜŞÜŞ — Acımasız QA eleştiri turu

Bu liste, oyunun baştan sona görsellik/ses/hata açısından yerden yere vurulan
incelemesinden çıktı. Her madde ya düzeltildi ya da açıkça not edildi.

## Kullanıcının bildirdiği hatalar — doğrulandı ve düzeltildi

1. **İlk kamp NPC diyalogları bugda** — `dialogue()` tek bir replik gösterip
   hemen NPC'nin paneline atlıyordu (otomata hissi). Ayrıca portre karanlık
   kalıyordu.
   **Fix:** Diyalog artık 2 satıra kadar atmosfer repliği sıralıyor
   (`rest` kuyruğu, `_advance_overlay` önce kuyruğu boşaltır, sonra panel).
   Portre parlaklığı +%22.

2. **Açılış sinematiği görselleri hatalı** — iki katmanlı bozukluk:
   a) `cine_0..3` kartları eski konsept-art'ları gösteriyordu: içlerine
      metin basılmış ("KAZA VADİSİ" gibi yarım/bozuk Türkçe) slaytlar —
      üzerine oyunun kendi başlığı binince çift yazı/yanlış etiket.
   b) `cine_4..8` kartları doğrudan **zemin dokusunu** kart olarak
      gösteriyordu (gen_manifest g_gr_* mapping).
   **Fix:** 13 yeni boyanmış sinematik vista üretildi (metinsiz):
   9 biome vistasi + mahzen + 3 özel intro kartı (kovan istilası,
   protokol kapısı, Alfa-04 silüeti). `cine_<b>_<v>` tüm varyantlar
   artık temiz vistaya bakar; intro `cine_i0..i2` kullanır.

3. **Kamera izometrik hissettirmiyordu** — dünya eğimi zaten vardı
   (x'−0.10y, y×0.86) ama karakterler de aynı eğime katılıp yatık
   duruyordu; eksik olan BG2'nin billboard tekniğiydi.
   **Fix:** `G.upright()` — aktör sprite'ları (oyuncu, düşman, boss, NPC,
   tüccar, kayıp şasi) artık karşı-eğimli tutucunun içinde çizilir:
   zemin eğik kalır, figürler dik durur. Hasar rakamları ve NPC üst
   yazıları da dik tutuldu. İzometrik okunuş belirginleşti.

4. **Vuruş efektleri basit renk dumanıydı** — düz daire sprite'ları.
   **Fix:** Kenney Particle Pack (CC0) sprite'ları bağlandı: duman/alev/
   kıvılcım/iz ikonları impact/boom/parry/beam efektlerinde kullanılıyor.

## Probe/screenshot avında bulunan ek kusurlar — düzeltildi

5. **HUD sinematik kartın üstüne çiziliyordu** — SEV/kesim/süre/ipucu
   katmanı cine kartının üstünde kalıyordu.
   **Fix:** cine sırasında `_hud` gizlenir, banner sıfırlanır,
   overlay'e `z_index=400`; `_close_overlay` HUD'u geri açar.

6. **Toast yığılması** — koşu başında 7+ satır üst üste birikiyordu.
   **Fix:** en fazla 4 toast, kompakt 20px aralık, eskiyen düşünce
   kalanlar yukarı kayar.

7. **Bölge etiketi ikonların altında kalıyordu** — silah/lütuf ikon
   sırası "ÇÜRÜK BATAKLIK" etiketinin üstüne biniyordu.
   **Fix:** `_room_lbl` 134→148, `_quest_lbl` 152→166.

8. **Arena sağ kenarında şerit artefaktı** — eğik dünyada yan duvar
   kolonları çapraz "chevron" deseni oluşturuyordu.
   **Fix:** yan duvar kolonları kaldırıldı; kenarlar BG2 tarzı vignette
   kararmasına bırakıldı.

## Bilerek bırakılanlar / izlenenler

- `cine_<b>_<v>` varyantları artık biome başına tek vistaya iner —
  eski metinli kartlar tamamen emekliye ayrıldı.
- `Px.S` PNG'leri editor'de `Image.load_from_file` ile yükler; export
  build'ler için `godot --import` geçişi gerekli (build scriptte var).
- Elit olmayan düşmanlarda can barı yok — okunabilirlik açısından
  yeterli bulundu (elitlerde var).
