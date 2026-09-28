extends SceneTree

# Alpha-trim portrait PNGs in place: crops to the opaque bounding box (+margin)
# so off-center/half-empty portraits fill the dialogue frame.
#   godot --headless --path . --script tools/trim_por.gd -- <dir> [<dir>...]
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: trim_por <dir> [<dir>...]")
		quit(1)
		return
	for i in args.size():
		var dpath := args[i]
		var prefix := ""
		if i + 1 < args.size() and args[i + 1].begins_with("prefix="):
			prefix = args[i + 1].substr(7)
		var d := DirAccess.open(dpath)
		if d == null:
			print("no dir: ", dpath)
			continue
		for fn in d.get_files():
			if not fn.ends_with(".png"):
				continue
			if prefix != "" and not fn.begins_with(prefix):
				continue
			var p := dpath.path_join(fn)
			var img := Image.load_from_file(p)
			if img == null or img.is_empty():
				print("cannot load ", p)
				continue
			img.convert(Image.FORMAT_RGBA8)
			var bb := _bbox(img)
			if bb.size.x <= 0 or bb.size.y <= 0:
				print("empty ", p)
				continue
			var mx := int(maxf(4.0, bb.size.x * 0.03))
			var my := int(maxf(4.0, bb.size.y * 0.03))
			var w := img.get_width()
			var h := img.get_height()
			var r := Rect2i(maxi(0, bb.position.x - mx), maxi(0, bb.position.y - my),
				mini(w - maxi(0, bb.position.x - mx), bb.size.x + 2 * mx),
				mini(h - maxi(0, bb.position.y - my), bb.size.y + 2 * my))
			if r == Rect2i(0, 0, w, h):
				continue
			var out := img.get_region(r)
			out.save_png(p)
			print("%s %dx%d -> %dx%d" % [p, w, h, out.get_width(), out.get_height()])
	quit()

func _bbox(img: Image) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var minx := w
	var miny := h
	var maxx := -1
	var maxy := -1
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.1:
				if x < minx: minx = x
				if x > maxx: maxx = x
				if y < miny: miny = y
				if y > maxy: maxy = y
	if maxx < 0:
		return Rect2i()
	return Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1)
