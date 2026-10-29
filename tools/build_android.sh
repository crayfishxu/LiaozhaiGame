#!/usr/bin/env bash
# 《聊斋美人》Android 打包脚本
#
# 用法：
#   tools/build_android.sh apk    # 调试 APK，可直接装手机
#   tools/build_android.sh aab    # Google Play 上传包（gradle + release 签名）
#
# 签名口令不写在脚本里，从本地私有文件读取：
#   ~/.liaozhai_keystore_pass     （单行口令，权限建议 600）
# 可用环境变量 LIAOZHAI_KEYSTORE_PASS_FILE 指定别的路径。
#
# 需要：Godot 4.6.3、JDK 17、Android SDK、导出模板。

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
PASS_FILE="${LIAOZHAI_KEYSTORE_PASS_FILE:-$HOME/.liaozhai_keystore_pass}"

if [ -z "${JAVA_HOME:-}" ]; then
	JAVA_HOME="$(ls -d /usr/local/Cellar/openjdk@17/*/libexec/openjdk.jdk/Contents/Home 2>/dev/null | head -1 || true)"
fi

MODE_INPUT="${1:-aab}"
case "$MODE_INPUT" in
apk)
	PRESET="Android Debug APK"
	OUT="build/liaozhai-debug.apk"
	EXPORT_FLAG="--export-debug"
	;;
aab)
	PRESET="Google Play AAB"
	OUT="build/liaozhai-release.aab"
	EXPORT_FLAG="--export-release"
	if [ -f "$PASS_FILE" ]; then
		# tr 去掉可能的换行，避免密码尾部多一个 \n
		GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(tr -d '\r\n' <"$PASS_FILE")"
		export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
	else
		echo "!! 找不到口令文件：$PASS_FILE" >&2
		echo "   请把密钥口令写成单行存进去，或设置 LIAOZHAI_KEYSTORE_PASS_FILE" >&2
		exit 1
	fi
	;;
*)
	echo "用法: $0 apk|aab" >&2
	exit 2
	;;
esac

[ -n "${JAVA_HOME:-}" ] || {
	echo "!! 找不到 JDK 17，请设置 JAVA_HOME" >&2
	exit 1
}

cd "$ROOT"
echo "JAVA_HOME = $JAVA_HOME"
echo "构建 $PRESET → $OUT"
rm -f "$OUT"
"$GODOT" --headless --path . "$EXPORT_FLAG" "$PRESET" "$OUT"
echo "----"
ls -lh "$OUT"
