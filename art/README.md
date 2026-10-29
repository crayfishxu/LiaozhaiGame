# 美术资源目录

按以下路径放图即可自动生效，无需改代码。详见项目根目录 README.md。

- `cards/{卡牌key}_xian.png`  卡面 · 显相
- `cards/{卡牌key}_ben.png`   卡面 · 本相
- `enemies/{敌人key}.png`     敌人立绘
- `bg/battle_bg.png`          战斗背景
- `characters/{角色key}.png`  角色立绘
- `fx/{名称}.tscn`            特效场景（可选）

当前已全量：17 个敌人立绘、52 张卡 × 双面（104 张）、3 张分层背景、1 张女主立绘。

原图（生成稿）放在 `_gen/raw/`，该目录带 `.gdignore`，不进引擎也不进包；
成品由 `tools/prep_art.py` 从原图裁切、去背、调色生成。
