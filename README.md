# 聊斋美人 · 卡牌肉鸽战斗原型

Godot 4.6.3 工程 · 占位素材可运行版 · 立绘与特效预留接入位

---

## 一、怎么跑起来

1. 安装 [Godot 4.4](https://godotengine.org/download)（标准版即可，不需要 .NET）
2. 打开 Godot → 项目管理器 → **导入** → 选择本目录下的 `project.godot`
3. 按 <kbd>F5</kbd> 或点击右上角 ▶ 运行

> 首次打开会自动导入资源，约 5 秒。
> 中文使用系统字体渲染（微软雅黑 / 苹方 / Noto Sans CJK），无需额外打包字体。

---

## 二、目录结构

```
godot_project/
├── project.godot              工程配置（窗口 1280×800，GL Compatibility）
├── icon.svg                   图标
├── scenes/
│   └── Battle.tscn            主场景（仅一个 Control 挂脚本，UI 由代码构建）
├── scripts/
│   ├── CardDB.gd              卡牌数据表          ← 改数值只动这里
│   ├── EnemyDB.gd             敌人与波次配置      ← 改数值只动这里
│   ├── AssetLoader.gd         资源接入层          ← 美术接入的唯一入口
│   ├── CardView.gd            卡牌视图（纯表现）
│   ├── EnemyView.gd           敌人视图（纯表现）
│   └── Battle.gd              战斗规则与流程      ← 改玩法动这里
└── art/                       美术资源目录（当前为空，放图即生效）
    ├── cards/
    ├── enemies/
    ├── bg/
    ├── characters/
    └── fx/
```

### 分层说明

| 层 | 文件 | 职责 | 改动频率 |
|----|------|------|----------|
| 数据 | CardDB / EnemyDB | 卡牌、敌人、波次的纯数值 | 每次调平衡 |
| 接入 | AssetLoader | 把资源路径和加载逻辑收在一处 | 几乎不改 |
| 表现 | CardView / EnemyView | 只负责画，不含规则 | 换美术时 |
| 规则 | Battle | 回合流程、伤害结算、翻面机制 | 改玩法时 |

**关键：`CardView` / `EnemyView` 里没有任何 `load("res://...")`，全部走 `AssetLoader`。**
所以换美术不需要碰逻辑代码。

---

## 三、怎么接入美术（重点）

### 3.1 放图即生效

按下面的路径丢文件进去，**不用改任何代码**：

| 内容 | 路径 | 建议尺寸 |
|------|------|----------|
| 卡面立绘 | `art/cards/{卡牌key}_xian.png` | **240×179**（对应卡面 110×82 区域，2 倍图） |
| 卡面立绘（本相） | `art/cards/{卡牌key}_ben.png` | 240×179 |
| 敌人立绘 | `art/enemies/{敌人key}.png` | 264×344 |
| 战斗背景（通用） | `art/bg/battle_bg.png` | 2560×1600 |
| 战斗背景（分层） | `art/bg/battle_bg_1.png` `_2` `_3` … | 2560×1600 |
| 角色立绘 | `art/characters/{角色key}.png` | 512×768（当前只有 `nvzhu.png`，开场界面用） |

> 卡面立绘是**横构图**，不是竖的。卡片只有 130×196，立绘区是 110×82 的横幅，
> 丢 2:3 的竖图进去会被 `STRETCH_KEEP_ASPECT_CENTERED` 缩成一条，白占空间。

`battle_bg_{n}.png` 的 n 从 1 起，对应 `EnemyDB.WAVES` 的层序（1 外院 / 2 佛堂 / 3 妖窟）。某层没放图就回退到通用的 `battle_bg.png`。

精英与 BOSS 想让立绘更大，在 `EnemyDB` 里给该敌人加一个 `"art_h"`（像素高度，上限 220，默认 196）：

```gdscript
"laolao": { "name": "姥姥", ..., "art_h": 184 },
"benti":  { "name": "树妖姥姥", ..., "art_h": 190 },
```

**示例：**
```
art/cards/sushou_xian.png     素手 · 显相
art/cards/sushou_ben.png      素手 · 本相
art/enemies/youhun.png        游魂
art/enemies/benti.png         树妖姥姥
art/bg/battle_bg.png          兰若寺背景
```

支持 `.png` / `.jpg` / `.webp`。

有图 → 自动替换占位字符；没图 → 继续显示「嗔 / 障 / 念 / 妖」等占位字。

### 3.2 代码里的接入点

所有美术相关位置都标了 `[ART]` 或 `[FX]`，全局搜索即可定位：

| 标记 | 位置 | 说明 |
|------|------|------|
| `[ART]` | `CardView.gd` → `load_art()` | 卡面图 |
| `[ART]` | `EnemyView.gd` → `refresh()` | 敌人立绘 |
| `[ART]` | `Battle.gd` → `_build_ui()` / `start_wave()` | 战斗背景（按层切换） |
| `[FX]` | `CardView.gd` → `play_hover_fx()` / `play_play_fx()` | 卡牌悬停、出牌特效 |
| `[FX]` | `EnemyView.gd` → `play_hit_fx()` / `play_death_fx()` | 受击、死亡特效 |
| `[FX]` | `Battle.gd` → `_float_at()` | 伤害飘字（可换成美术数字图） |

特效场景预留了 `art/fx/{名称}.tscn`，通过 `AssetLoader.fx_scene("名称")` 加载，目前未调用，接入时在对应 `[FX]` 函数里 `add_child` 即可。

### 3.3 想换布局？

`CardView.gd` 顶部的 `CARD_W` / `CARD_H` 和内部各元素的 `position` 都是显式坐标，直接改数字即可。
或者把 `CardView` 换成你的 `.tscn` 场景（把脚本挂在根节点，保证有 `setup(key, side, index)` 和 `clicked` 信号）。

---

## 四、核心机制

### 显相 / 本相 双面

每张卡有两面，打出后自动翻到另一面：

| | 显相 | 本相 |
|---|------|------|
| 视觉 | 月白底、深色字 | 鸦青底、朱砂边、白字 |
| 定位 | 防御、稳定、低代价 | 爆发、高收益、自损 |
| 示例 | 素手：造成 6 点伤害 | 素手：造成 9 点伤害，自损 2 |

实现方式极简：卡牌实例是 `{"key": "...", "side": "xian"}`，打出时 `side` 翻转后进入弃牌堆。下次抽到自然是另一面。

### 怨气

玩家受伤时积累怨气（+2，有「怨气缠身·本相」时 +4）。
「怨念」这张牌吃怨气加成，「缠丝·本相」按目标毒层数结算。

### 回合流程

```
玩家回合开始 → 清空护盾 → 回满心力(3) → 结算中毒 → 抽 5 张 → 显示敌人意图
    ↓
出牌（消耗心力，卡牌翻面入弃牌）
    ↓
结束回合 → 弃掉手牌 → 敌人依次行动 → 判定胜负
```

### 当前内容量

| 项 | 数量 |
|----|------|
| 卡牌 | 17 种（各 2 面，共 34 种表现） |
| 初始牌组 | 12 张 |
| 敌人 | 4 种（游魂 / 树傀 / 姥姥 / 树妖姥姥） |
| 波次 | 3 波（含 1 精英 1 BOSS） |
| 战后奖励 | 12 张卡池三选一 |

---

## 五、改东西改哪里

| 想改 | 改哪 |
|------|------|
| 卡牌数值、描述、效果 | `CardDB.gd` 的 `CARDS` |
| 加新卡 | 在 `CARDS` 加一条，再把 key 加进 `REWARD_POOL` |
| 敌人血量、行动循环 | `EnemyDB.gd` 的 `ENEMIES` |
| 波次编排 | `EnemyDB.gd` 的 `WAVES` |
| 初始牌组 | `Battle.gd` → `_starter_deck()` |
| 初始血量、每回合抽牌/心力 | `Battle.gd` 顶部 `START_HP` / `DRAW_PER_TURN` / `ENERGY_PER_TURN` |
| 配色 | 各脚本顶部的 `const C_*` |
| 卡牌尺寸 | `CardView.gd` 的 `CARD_W` / `CARD_H` |

### 加一张新卡的最小步骤

```gdscript
# CardDB.gd → CARDS 里加
"xinyou": {
    "name": "心釉", "type": "skill", "cost": 1, "target": true, "glyph": "念",
    "xian": {"text": "造成 5 点伤害\n抽 1 张牌", "dmg": 5, "draw": 1},
    "ben": {"text": "对全体造成 6 点伤害\n自损 3 魂火", "aoe_dmg": 6, "self_hp": 3},
},
```

再把 `"xinyou"` 加进 `REWARD_POOL`。完事，不需要动别的文件。

---

## 六、已实现 / 未实现

### 已实现
- 回合制卡牌战斗（心力、抽牌、弃牌、洗牌）
- 显相/本相翻面机制
- 13 种效果字段（伤害、多段、AOE、护盾、自损、中毒、缠绕、易伤、抽牌、加费、反伤、能力、特殊结算）
- 敌人意图显示与行动循环
- 怨气资源与相关卡牌联动
- 三波关卡 + 战后三选一奖励
- 胜利 / 失败 / 开场界面
- 伤害飘字、受击闪白、悬停放大
- 资源接入层与占位回退

### 未实现（下一步）
- 地图节点与路径选择（当前是线性三波）
- 局外成长（悟道点、卡池解锁）
- 存档
- 音效音乐
- 更多角色与流派
- 卡牌升级
- 遗物/旧物系统（数据结构已在设计中，未落代码）

---

## 七、移动端适配与已知限制

### 7.1 屏幕适配（v0.1.2 起）

手机横屏下原本「字小、画面缩」的根因是设计基准分辨率太高：`1280×800` 的稿子在
1080p 手机上 `stretch` 缩放系数只有 1.35，12px 的字落到屏幕上不足 1.1mm。

现在改成：

| 项 | 值 | 说明 |
|----|----|----|
| 基准分辨率 | `1024×720` | `project.godot` → `[display]`，缩放系数升到 **1.5** |
| 拉伸模式 | `canvas_items` + `aspect=expand` | 超宽屏（19.5:9）左右扩展，不裁切 UI |
| 屏幕方向 | `sensor_landscape` | 锁定横屏，允许左右翻转 |
| 字号系数 | `UI_S = 1.3` | `Battle.gd` 顶部常量，`_mk_label()` 统一乘 |
| 沉浸模式 | `screen/immersive_mode=true` | 导出预设里，隐藏状态栏/导航栏 |

字号要整体再调大 / 调小，只改 `Battle.gd` 里的 `UI_S` 一个常量即可；
`CardView.gd` / `EnemyView.gd` 里的字号是按新尺寸手调的，改 `UI_S` 不会影响它们。

元素尺寸也同步放大了一轮：卡牌 `130×196`（原 `106×162`）、敌人立绘 `152×196`（原 `132×172`）。
纵向空间是硬约束 —— `topbar 44 + field + midbar 26 + handzone 232 + botbar 52 = 720`，
再往上堆元素就会把手牌区压扁。

### 7.2 返回键与退出

手机没有 Esc，所以做了两条出口，任意一条都能离开游戏：

1. **左上角 `≡` 按钮** —— 悬浮在弹窗之上，任何界面状态下都点得到
2. **系统返回键** —— 走 `NOTIFICATION_WM_GO_BACK_REQUEST`，已把
   `application/config/quit_on_go_back` 设为 `false`，由脚本接管

两者都打开「暂停」面板：继续游戏 / 重新开始 / 退出到桌面。
退出走 `get_tree().quit()`，Android 上会直接结束进程回到桌面。
结算界面额外带一个「退出」按钮。

> 注意：`quit_on_go_back` 必须保持 `false`。设成 `true` 时引擎会抢在脚本之前直接杀进程，
> 返回键就变成无提示闪退了。

### 7.3 出牌是两步操作（v0.1.3 起有提示）

带 `target: true` 的牌（几乎全部攻击牌、以及「幽怨 / 情丝 / 低眉」）**点一下只是选中**，
还要再点一个敌人才真正打出。防御牌、技能牌、能力牌则是一点即出。

v0.1.2 之前这里有个坑：有立绘的敌人会把 `_body_panel` 的 stylebox 换成 `StyleBoxEmpty`
（避免立绘透出一圈浅灰底色），连带 `set_targetable()` 改的红色描边也一起失效了 ——
玩家点了攻击牌，敌人身上**什么提示都没有**，看起来就像「牌打不出去」。

v0.1.3 的修法：

- 选中框独立成 `_target_frame` 一层叠在立绘上，不再依赖 stylebox，红框一定可见
- 中栏右侧出现 `▸ 点 一 个 敌 人`
- 所有被拦下的点击都有 toast 说明原因：
  - 心力不够 → `心力不足 · 需要 N 点`
  - 连点同一张牌 → `已取消选择`
  - 没选牌就点敌人 → `先点一张牌，再点敌人`
  - 敌人行动中 → `敌人行动中…`

另外修掉一个尺寸遗留 bug：`_refresh_hp()` 里血条宽度写死 `150×6`，
而 v0.1.2 的容器已经改成 `160×8`，导致打第一张牌后血条会缩一截。

#### 敌人立绘点不动（v0.1.4 修）

v0.1.3 加了红框之后仍然「点了敌人没反应」，实测定位到：**点敌人名字能打出，点立绘不能**。

原因在命中链路。`EnemyView` 是 `VBoxContainer`（`mouse_filter = STOP`），
它的 `gui_input` 才是真正接 click 的地方；但里面几个装饰性子节点默认会**吃掉**事件：

| 子节点 | 类型 | 默认 mouse_filter |
|---|---|---|
| `_body_panel`（立绘框） | PanelContainer | PASS，但不继续冒泡 |
| `_hp_bar`（血条） | Control | **STOP**，直接吞掉 |

结果就是点立绘 / 血条全无响应，只有名字那几个像素能点中。

修法：`_build()` 里把 `_intent_panel` / `_body_panel` / `_hp_bar` / `_status_box`
以及两个 Label 全部显式设成 `MOUSE_FILTER_IGNORE`，让事件直接落到最外层的
`EnemyView`。现在整个敌人矩形（意图条 → 状态框）任意位置都能选中。

> 排查心得：这类「某个区域点不动」的问题，**先按区域网格点击对比**（名字 / 立绘 / 血条 / 空白），
> 两三个点就能定位到具体是哪个子控件的 `mouse_filter` 没收干净。

### 7.4 已知限制

- UI 全部由代码构建，场景树在编辑器里看不到节点。若需要可视化编辑，可把 `CardView` / `EnemyView` 改造成 `.tscn` 场景。
- 手牌超过 6 张时用负间距重叠，超过 10 张仍可能超出屏幕，需要加横向滚动或扇形排布。
- 动画是 `Tween` 硬编码，未做统一的动画调度。
- 超宽屏（2.17:1）下左右两侧仍有约 27% 的背景留白，卡牌与敌人是居中的；想做满屏需要把玩家状态挪到侧栏重排。
- 特效只有代码内的 `Tween`（飘字、缩放、受击闪白），没有独立特效资源，也没有粒子层。

### 7.5 美术资源清单（v0.1.5 已补齐）

| 类别 | 文件数 | 位置 | 状态 |
|------|--------|------|------|
| 卡面立绘 | 34（17 卡 × 显/本） | `art/cards/` | ✅ 240×179 RGBA，边缘羽化 |
| 敌人立绘 | 4 | `art/enemies/` | ✅ 528×688 |
| 战斗背景 | 3 | `art/bg/` | ✅ 外院 / 佛堂 / 妖窟 |
| 女主立绘 | 1 | `art/characters/nvzhu.png` | ✅ 512×768，开场界面 |
| 启动图标 | 5 + 自适应 | `art/icon/launcher/` | ✅ |
| 商店素材 | 6 | `build/store/` | ✅ 512 图标 / 1024×500 / 4 张截图 |

卡面的显相 / 本相不是两套独立画稿，而是**同一张底图调色派生**：
显相提亮 1.10、降饱和 0.80、偏冷青；本相压暗 0.76、升对比 1.10、偏朱红。
想换某张卡的构图，只要替换 `art/_gen/raw/{key}.png` 后重跑派生脚本即可。

`art/_gen/`（原始大图）与 `art/_raw/`（更早的素材）都带 `.gdignore` + `.gitignore`，
不进包也不入库，只在本地保留以便重制。

---

## 八、打包 Android / 上架 Google Play

### 8.1 一次性环境

| 项 | 值 |
|----|----|
| 引擎 | Godot **4.6.3**（`/Applications/Godot.app`） |
| JDK | 17（编辑器设置 `export/android/java_sdk_path`） |
| Android SDK | `~/Library/Android/sdk`（build-tools 36.1.0、platform 36） |
| 导出模板 | `~/Library/Application Support/Godot/export_templates/4.6.3.stable/`（`android_debug.apk` / `android_release.apk` / `android_source.zip`） |
| 上传密钥 | `/Users/crayfish/keystores/liaozhai-upload.jks`，alias `liaozhai-upload`，口令见同目录 `README.txt` |

> 工程必须开启 `rendering/textures/vram_compression/import_etc2_astc=true`，
> 否则 Android 导出会以「错误信息为空」的方式静默失败（Godot 的坑）。

### 8.2 出包

```bash
export JAVA_HOME=/usr/local/Cellar/openjdk@17/17.0.13/libexec/openjdk.jdk/Contents/Home
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=111111   # 密钥口令，不要写进仓库

cd godot_project

# Play 上架包（AAB，gradle 构建，自动签名）
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --export-release "Google Play AAB" build/liaozhai-release.aab

# 调试用 APK（预编译模板，秒出）
/Applications/Godot.app/Contents/MacOS/Godot --headless \
  --export-debug "Android Debug APK" build/liaozhai-debug.apk
```

### 8.3 产物

| 文件 | 用途 |
|------|------|
| `build/liaozhai-release.aab` | 上传 Google Play Console |
| `build/liaozhai-release-universal.apk` | 侧载到真机验证（由 AAB 转换，同密钥签名） |
| `build/liaozhai-debug.apk` | 调试安装包 |

### 8.4 上架要点

- 包名 `com.liaozhai.meiren`，minSdk 24 / targetSdk 36，覆盖 `arm64-v8a` + `armeabi-v7a`
- **每次上传 versionCode 必须递增** → 改 `export_presets.cfg` 里的 `version/code`
- `android/`（1.2 GB）是 gradle 构建模板，`.godot/`、`build/` 都是生成物，**不要提交到仓库**
- 首次上传用上传密钥签名，随后在 Play Console 开启「Play 应用签名」

### 8.5 升版本号

版本号有两处，**必须同时改**，否则 Play 会因重复 versionCode 拒包：

| 位置 | 字段 | 当前值 |
|------|------|--------|
| `export_presets.cfg`（两个预设各一份） | `version/code` / `version/name` | `6` / `"0.1.5"` |
| `project.godot` `[application]` | `config/version` | `"0.1.5"` |

出包后把旧产物移进 `build/archive/v<旧版本>/`，保持 `build/` 顶层只有当前版本的三个文件。

### 8.6 Play Console 的两条「提醒」

上传 AAB 后 Google Play 会提示两条黄色提醒，**都不阻断发布**，但成因不同：

| 提醒 | 成因 | 处理 |
|------|------|------|
| 未关联去混淆文件 | Godot 的 `release` 构建没有开启 R8/ProGuard（模板里 `buildTypes.release` 无 `minifyEnabled`），整个 dex 未混淆，**本来就没有 mapping.txt 可传** | 忽略即可。除非自己开 `minifyEnabled`，那样必须补 keep 规则，否则 JNI 反射会 crash |
| 未上传原生调试符号 | Godot 官方导出模板里的 `libgodot_android.so` 是完全 strip 过的（`llvm-nm` 返回 no symbols），`debugSymbolLevel` 也提不出东西 | 下载官方符号包，抽出对应 ABI 打包上传 |

原生符号的正确做法（Godot 官方提供单独的符号包，不在 tpz 里）：

```
https://github.com/godotengine/godot/releases/download/4.6.3-stable/
  Godot_native_debug_symbols.4.6.3.stable.template_release.android.zip   # 722 MB
```

里面是 4 个 ABI 的**未 strip** 库（`arm64-v8a/libgodot_android.so` 693 MB，含 `.debug_info` / `.debug_line` / 35 万条符号）。
只需要抽 `arm64-v8a` 和 `armeabi-v7a` 两组，按 `<abi>/<lib>.so` 打成 zip（本项目产物：`build/symbols/native-debug-symbols-v0.1.1.zip`，359 MB），
在 Play Console 的 App Bundle 探索工具 → 该版本 → 下载 → 「原生调试符号」处上传。

> 校验符号是否与发行包同源：对两个 `.so` 分别 `llvm-objcopy --dump-section .text=...` 后比 md5，一致即可。
> 本项目实测 `text` / `dynsym` 两段哈希与 AAR 里的库完全一致。

启动器图标若不显示，检查 `package/show_as_launcher_app`；`build/symbols/` 与 `build/store/` 都放 `.gdignore`，避免被引擎导入。

---

版本：v0.1.1 · 2026-10-23
