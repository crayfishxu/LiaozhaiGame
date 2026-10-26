class_name AssetLoader
extends RefCounted

## ==================================================================
## 资源接入层（解耦核心）
##
## 所有视图只通过本类取美术资源。项目里没有图片时，全部返回 null，
## 视图层自动回退到「色块 + 文字」占位表现。
##
## 后期接入美术，只需按下面的约定放图，无需改任何逻辑代码：
##
##   卡面立绘   res://art/cards/{卡牌key}_{xian|ben}.png
##              例：res://art/cards/sushou_xian.png
##                  res://art/cards/sushou_ben.png
##
##   敌人立绘   res://art/enemies/{敌人key}.png
##              例：res://art/enemies/youhun.png
##
##   战斗背景   res://art/bg/battle_bg.png
##
##   角色立绘   res://art/characters/{角色key}.png
##
## 支持 .png / .jpg / .webp（Godot 会自动导入为 Texture2D）
## ==================================================================

const CARD_DIR := "res://art/cards/"
const ENEMY_DIR := "res://art/enemies/"
const BG_DIR := "res://art/bg/"
const CHAR_DIR := "res://art/characters/"


static func card_art(key: String, side: String) -> Texture2D:
	return _texture(CARD_DIR + key + "_" + side)


static func enemy_art(key: String) -> Texture2D:
	return _texture(ENEMY_DIR + key)


## 战斗背景：按波次取 res://art/bg/battle_bg_{n}.png（n 从 1 起）
## 找不到该层的专属背景时，回退到通用 res://art/bg/battle_bg.png
static func battle_bg(wave: int = 0) -> Texture2D:
	var specific := _texture(BG_DIR + "battle_bg_" + str(wave + 1))
	if specific != null:
		return specific
	return _texture(BG_DIR + "battle_bg")


static func character_art(key: String) -> Texture2D:
	return _texture(CHAR_DIR + key)


## 尝试若干扩展名，找到即返回
static func _texture(base_path: String) -> Texture2D:
	var exts: Array[String] = [".png", ".jpg", ".webp"]
	for ext in exts:
		var p: String = base_path + ext
		if ResourceLoader.exists(p):
			var res := load(p)
			if res is Texture2D:
				return res as Texture2D
	return null
