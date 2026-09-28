extends SceneTree

# Pixel-art post-processor for AI-generated sprites on magenta (#FF00FF) bg.
# Modes:
#   godot --headless --path . --script tools/pix_proc.gd -- one in.png out.png <height>
#   godot --headless --path . --script tools/pix_proc.gd -- sheet in.png <N> <height> <outprefix>
# sheet mode splits the image into N sprites at low-occupancy column gutters.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		print("usage: one in.png out.png h | sheet in.png N h outprefix")
		quit(1)
		return
	var img := Image.load_from_file(args[1])
	if img == null or img.is_empty():
		print("cannot load ", args[1])
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	_key(img)
	_strip_labels(img)
	if args[0] == "one":
		var c := _crop(img)
		if c == null:
			quit(1)
			return
		_emit(c, int(args[3]), args[2])
		quit()
		return
	# sheet mode: sheet <in> <N> <height> <outprefix> [ymaxfrac]
	var n := int(args[2])
	var th := int(args[3])
	if args.size() > 5:
		var yf := float(args[5])
		if yf < 1.0:
			img = img.get_region(Rect2i(0, 0, img.get_width(), int(img.get_height() * yf)))
	var cells := _cells(img, n)
	if cells.size() != n:
		print("gutter split gave %d cells, expected %d" % [cells.size(), n])
		quit(1)
		return
	for i in cells.size():
		_emit(cells[i], th, "%s_%d.png" % [args[4], i])
	quit()

# Flood-fill the border-connected background instead of per-pixel hue keying:
# the generator's "magenta" varies per sheet (pink/violet/blue), so we sample
# the dominant corner colour and erase only pixels connected to the border —
# same-hued pixels inside the emblem survive untouched.
func _key(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var corners := [
		img.get_pixel(0, 0), img.get_pixel(w - 1, 0),
		img.get_pixel(0, h - 1), img.get_pixel(w - 1, h - 1)]
	var bg: Color = corners[0]
	if bg.a < 0.5:
		return  # already keyed
	# flat-bg sanity: corners must roughly agree (sprite reaching the frame edge
	# would give mixed corners — then fall back to nothing rather than eat it)
	var tol := 0.22
	var mark := {}
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		var k := p.y * w + p.x
		if mark.has(k):
			continue
		mark[k] = true
		var c := img.get_pixel(p.x, p.y)
		if Vector3(c.r - bg.r, c.g - bg.g, c.b - bg.b).length() > tol:
			continue
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))

# erase a caption band: a sparse text line floats below an empty gap near the
# bottom of the sheet — find the lowest occupied row, then the gap above it,
# and clear everything below the gap
func _strip_labels(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var cnt := PackedInt32Array()
	cnt.resize(h)
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.1:
				cnt[y] += 1
	var low := -1
	for y in range(h - 1, -1, -1):
		if cnt[y] > 0:
			low = y
			break
	if low < 0:
		return
	# walk up from the bottom; each empty gap with a thin band below it is a
	# caption label line — keep clearing until the band below the gap is tall
	# (real sprite content) or we're above mid-image
	var y := low
	while y > int(h * 0.4):
		if cnt[y] > 0:
			y -= 1
			continue
		var above := y - 1
		while above >= 0 and cnt[above] == 0:
			above -= 1
		if above < int(h * 0.4):
			return
		if float(cnt[above]) > w * 0.05 and low - y < h * 0.14:
			for yy in range(y + 1, h):
				for xx in w:
					img.set_pixel(xx, yy, Color(0, 0, 0, 0))
				cnt[yy] = 0
			low = above
			y = above
			continue
		return

func _crop(img: Image) -> Image:
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
		print("empty after keying")
		return null
	return img.get_region(Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1))

# split into n cells: near each ideal equal-width boundary, pick the closest
# empty column (or lowest-occupancy one) so poses straddling a band edge stay whole
func _cells(img: Image, n: int) -> Array:
	var w := img.get_width()
	var h := img.get_height()
	var occ := PackedInt32Array()
	occ.resize(w)
	for x in w:
		for y in h:
			if img.get_pixel(x, y).a > 0.1:
				occ[x] += 1
	var cuts: Array = []
	var win := int(float(w) / n * 0.4)
	for k in range(1, n):
		var ideal := int(float(w) * k / n)
		var best := ideal
		var bestv := 1 << 30
		for x in range(maxi(ideal - win, 8), mini(ideal + win, w - 8)):
			if occ[x] < bestv:
				bestv = occ[x]
				best = x
			if bestv == 0:
				break
		if not cuts.has(best):
			cuts.append(best)
	while cuts.size() < n - 1:
		var added := false
		for k in range(1, n):
			var ideal := int(float(w) * k / n)
			var ok := true
			for c2 in cuts:
				if abs(c2 - ideal) < 16:
					ok = false
					break
			if ok:
				cuts.append(ideal)
				added = true
		if not added:
			break
	cuts.sort()
	var bounds: Array = [0]
	bounds.append_array(cuts)
	bounds.append(w)
	var out: Array = []
	for i in bounds.size() - 1:
		var sub := img.get_region(Rect2i(bounds[i], 0, bounds[i + 1] - bounds[i], h))
		var c := _crop(sub)
		if c != null:
			_strip_cell_label(c)
			out.append(c)
	return out

# per-cell caption strip: sprite = tallest contiguous content band from the top;
# a short band dangling below an empty gap is a caption
func _strip_cell_label(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var cnt := PackedInt32Array()
	cnt.resize(h)
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.1:
				cnt[y] += 1
	var low := -1
	for y in range(h - 1, -1, -1):
		if cnt[y] > 0:
			low = y
			break
	if low < 0:
		return
	var top := 0
	while top < h and cnt[top] == 0:
		top += 1
	# find the last empty gap; if the band under it is short, it's a caption
	var y := low
	while y > top:
		if cnt[y] == 0:
			var above := y - 1
			while above >= top and cnt[above] == 0:
				above -= 1
			if above < top:
				return
			# band height below the gap vs total sprite height
			if low - y < (low - top) * 0.30 and low - y < h * 0.2:
				for yy in range(y + 1, h):
					for xx in w:
						img.set_pixel(xx, yy, Color(0, 0, 0, 0))
					cnt[yy] = 0
				low = above
				y = above
				continue
			return
		y -= 1

func _emit(img: Image, th: int, path: String) -> void:
	var tw := int(round(float(th) * float(img.get_width()) / float(img.get_height())))
	img.resize(tw, th, Image.INTERPOLATE_NEAREST)
	img.save_png(path)
	print("wrote %s (%dx%d)" % [path, tw, th])
