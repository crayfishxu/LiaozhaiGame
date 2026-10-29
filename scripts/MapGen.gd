class_name MapGen
extends RefCounted

## ==================================================================
## 地图生成
##
## 每层是一张自下而上的有向无环图：
##   第 0 行（起点，全部战斗）→ … → 休息行（1 个）→ Boss 行（1 个）
##
## 硬约束（对应 doc/01 的 C1–C11）：
##   C1 第一行全战斗     C2 Boss 前一行只有 1 个休息
##   C3 精英不在前 2 行  C4 商店不在最后 2 行
##   C5 休息 ≥ 1         C6 商店恰好 1 个
##   C7 同行相邻不同类（战斗除外）
##   C8/C9 出入度 1–2    C10/C11 全连通
## ==================================================================

const TYPE_WEIGHT := {
	"battle": 45, "event": 20, "elite": 12, "shop": 8, "rest": 12, "treasure": 3,
}

static func generate(layer: int, rng: RandomNumberGenerator) -> Dictionary:
	var cfg: Dictionary = EnemyDB.LAYERS[layer]
	var normal_rows := int(cfg["rows"])
	var total := normal_rows + 1
	var best: Dictionary = {}

	for attempt in 16:
		var rows := _skeleton(cfg, total, rng)
		_fill_types(rows, cfg, layer, rng)
		_link(rows, rng)
		var pc := _path_count(rows)
		if pc >= int(cfg["min_paths"]):
			_attach_payload(rows, layer, rng)
			return {"layer": layer, "rows": rows, "paths": pc}
		if best.is_empty() or pc > int(best["paths"]):
			best = {"layer": layer, "rows": rows, "paths": pc}

	_attach_payload(best["rows"], layer, rng)
	return best


# ------------------------------------------------------------------
# 骨架
# ------------------------------------------------------------------
static func _skeleton(cfg: Dictionary, total: int, rng: RandomNumberGenerator) -> Array:
	var rows: Array = []
	var cmin := int(cfg["cols_min"])
	var cmax := int(cfg["cols_max"])
	for r in total:
		var count := 1
		if r == 0:
			count = rng.randi_range(cmin, mini(cmax, cmin + 1))
		elif r == total - 2 or r == total - 1:
			count = 1                     # 休息行 / Boss 行
		else:
			count = rng.randi_range(cmin, cmax)
		var row: Array = []
		for c in count:
			row.append({
				"id": "L%d_R%d_C%d" % [int(cfg.get("layer", 0)), r, c],
				"type": "battle",
				"row": r, "col": c,
				"next": [],
				"payload": {},
				"visited": false,
			})
		rows.append(row)
	return rows


# ------------------------------------------------------------------
# 填充类型
# ------------------------------------------------------------------
static func _fill_types(rows: Array, cfg: Dictionary, layer: int, rng: RandomNumberGenerator) -> void:
	var normal_rows := int(cfg["rows"])
	var total := rows.size()

	for r in total:
		var row: Array = rows[r]
		if r == 0:
			for n in row:
				n["type"] = "battle"
			continue
		if r == total - 2:
			for n in row:
				n["type"] = "rest"
			continue
		if r == total - 1:
			for n in row:
				n["type"] = "boss"
			continue

		for n in row:
			var weights := TYPE_WEIGHT.duplicate()
			if r < 2:
				weights["elite"] = 0
			if r >= normal_rows - 2:
				weights["shop"] = 0
			if layer == 0:
				weights["treasure"] = 0
			n["type"] = _pick(weights, rng)

	# ---- C6 商店恰好 1 个 ----
	var shops: Array = []
	for r in range(1, normal_rows):
		for n in rows[r]:
			if str(n["type"]) == "shop":
				shops.append(n)
	if shops.is_empty():
		var cand := _first_of(rows, "battle", 2, normal_rows - 2)
		if not cand.is_empty():
			cand["type"] = "shop"
	else:
		for i in range(1, shops.size()):
			shops[i]["type"] = "event"

	# ---- C5 休息 ≥ 1（中间行）----
	var has_rest := false
	for r in range(1, normal_rows - 1):
		for n in rows[r]:
			if str(n["type"]) == "rest":
				has_rest = true
	if not has_rest:
		var cand := _first_of(rows, "battle", 2, normal_rows - 2)
		if not cand.is_empty():
			cand["type"] = "rest"

	# ---- 精英 ≥ 1 ----
	var has_elite := false
	for r in range(2, normal_rows - 1):
		for n in rows[r]:
			if str(n["type"]) == "elite":
				has_elite = true
	if not has_elite:
		var cand := _first_of(rows, "battle", 2, normal_rows - 2)
		if not cand.is_empty():
			cand["type"] = "elite"

	# ---- C7 同行相邻不同类 ----
	for r in range(1, total - 2):
		var row: Array = rows[r]
		for c in range(1, row.size()):
			if str(row[c]["type"]) == str(row[c - 1]["type"]) and str(row[c]["type"]) != "battle":
				row[c]["type"] = "battle"


static func _first_of(rows: Array, type: String, from_row: int, to_row: int) -> Dictionary:
	for r in range(max(0, from_row), mini(to_row, rows.size() - 1)):
		for n in rows[r]:
			if str(n["type"]) == type:
				return n
	return {}


static func _pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for v in weights.values():
		total += int(v)
	if total <= 0:
		return "battle"
	var roll := rng.randi_range(1, total)
	for k in ["battle", "event", "elite", "shop", "rest", "treasure"]:
		roll -= int(weights.get(k, 0))
		if roll <= 0:
			return k
	return "battle"


# ------------------------------------------------------------------
# 连线
# ------------------------------------------------------------------
static func _link(rows: Array, rng: RandomNumberGenerator) -> void:
	for r in range(0, rows.size() - 1):
		var upper: Array = rows[r]
		var lower: Array = rows[r + 1]
		for n in upper:
			var want := 1 if rng.randf() < 0.45 else 2
			var cands := lower.duplicate()
			cands.sort_custom(func(a, b):
				return absi(int(a["col"]) - int(n["col"])) < absi(int(b["col"]) - int(n["col"]))
			)
			var taken := 0
			for m in cands:
				if taken >= want:
					break
				if not n["next"].has(m["id"]):
					n["next"].append(m["id"])
					taken += 1
		# 补全：每个下层节点必须有入边
		for m in lower:
			var has_in := false
			for n in upper:
				if n["next"].has(m["id"]):
					has_in = true
					break
			if has_in:
				continue
			var src: Dictionary = upper[0]
			var bestd := 9999
			for n in upper:
				var d := absi(int(n["col"]) - int(m["col"]))
				if d < bestd and n["next"].size() < 2:
					bestd = d
					src = n
			src["next"].append(m["id"])


## 起点到 Boss 的路径数量（上限 999，防止指数爆炸）
static func _path_count(rows: Array) -> int:
	if rows.is_empty():
		return 0
	var ways: Dictionary = {}
	for n in rows[0]:
		ways[str(n["id"])] = 1
	for r in range(1, rows.size()):
		for n in rows[r]:
			var s := 0
			for p in rows[r - 1]:
				if p["next"].has(n["id"]):
					s += int(ways.get(str(p["id"]), 0))
			ways[str(n["id"])] = mini(s, 999)
	return int(ways.get(str(rows[rows.size() - 1][0]["id"]), 0))


# ------------------------------------------------------------------
# 节点内容
# ------------------------------------------------------------------
static func _attach_payload(rows: Array, layer: int, rng: RandomNumberGenerator) -> void:
	var cfg: Dictionary = EnemyDB.LAYERS[layer]
	var pool: Array = cfg["pool"]
	var used_events: Array = []
	var total := rows.size()

	for r in total:
		for n in rows[r]:
			match str(n["type"]):
				"battle":
					var count := rng.randi_range(1, 2) if layer == 0 else rng.randi_range(2, 3)
					var picked: Array = []
					for i in count:
						picked.append(str(pool[rng.randi() % pool.size()]))
					n["payload"] = {"enemies": picked}
				"elite":
					n["payload"] = {"enemies": [str(cfg["elite"])]}
				"boss":
					n["payload"] = {"enemies": [str(cfg["boss"])]}
				"event":
					var ids: Array = EventDB.ids()
					var choices: Array = []
					for id in ids:
						if not used_events.has(id):
							choices.append(id)
					if choices.is_empty():
						choices = ids
					var pick := str(choices[rng.randi() % choices.size()])
					used_events.append(pick)
					n["payload"] = {"event": pick}
				_:
					n["payload"] = {}
