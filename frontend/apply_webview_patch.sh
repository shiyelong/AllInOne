#!/bin/bash

# 使WebView插件的Swift代码修改脚本

# 找到插件的路径
WEBVIEW_PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/webview_flutter_wkwebview-3.20.0"

# 确保插件路径存在
if [ ! -d "$WEBVIEW_PLUGIN_PATH" ]; then
  echo "无法找到WebView插件路径: $WEBVIEW_PLUGIN_PATH"
  exit 1
fi

# 目标文件路径
TARGET_FILE="$WEBVIEW_PLUGIN_PATH/darwin/webview_flutter_wkwebview/Sources/webview_flutter_wkwebview/HTTPCookieProxyAPIDelegate.swift"

# 确保目标文件存在
if [ ! -f "$TARGET_FILE" ]; then
  echo "无法找到目标文件: $TARGET_FILE"
  exit 1
fi

# 创建备份
cp "$TARGET_FILE" "${TARGET_FILE}.bak"

# 修改代码，替换容易产生警告的行
sed -i '' 's/let keyValueTuples = try! properties.map<\[(HTTPCookiePropertyKey, Any)\], PigeonError> {/let keyValueTuples: \[(HTTPCookiePropertyKey, Any)\] = try! properties.map {/' "$TARGET_FILE"

echo "已应用补丁到 $TARGET_FILE"
echo "原始文件已备份为 ${TARGET_FILE}.bak"
echo "完成!"

# 使脚本执行权限
chmod +x apply_webview_patch.sh
