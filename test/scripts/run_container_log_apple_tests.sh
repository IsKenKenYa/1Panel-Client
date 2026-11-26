#!/usr/bin/env bash
#
# Apple 容器日志真实链路测试的统一执行入口。
#
# 负责：启动 Dart 测试服务 → 等待就绪 → 运行指定测试 → 无条件释放。
# 端口固定且显式，冲突时立即失败并说明原因，不终止其他进程。
#
# 用法：
#   test/scripts/run_container_log_apple_tests.sh unit
#   test/scripts/run_container_log_apple_tests.sh ui
#   test/scripts/run_container_log_apple_tests.sh macos
#
# 测试配置隔离：Swift 测试经 useTestStorageNamespace 通道把配置读写切到
# 独立命名空间，用户真实配置不会被读写。

set -u -o pipefail

MODE="${1:-}"
if [ -z "$MODE" ]; then
  echo "usage: $0 <unit|ui|macos>" >&2
  exit 64
fi

PORT="${ONEPANEL_TEST_SERVICE_PORT:-18765}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/build/b73_evidence"
mkdir -p "$OUT"

SIMULATOR_ID="${ONEPANEL_TEST_SIMULATOR:-991FFE2A-01B0-4C83-BAC7-0037F58E61D3}"
FLUTTER_BIN="${ONEPANEL_FLUTTER_BIN:-/Volumes/FXS100Pro/DevTools/Flutter/flutter/bin}"

SERVICE_PID=""
SERVICE_LOG="$OUT/service.log"

cleanup() {
  local status=$?
  if [ -n "$SERVICE_PID" ] && kill -0 "$SERVICE_PID" 2>/dev/null; then
    kill "$SERVICE_PID" 2>/dev/null || true
    wait "$SERVICE_PID" 2>/dev/null || true
    echo "service stopped (pid $SERVICE_PID)"
  fi
  exit "$status"
}
trap cleanup EXIT INT TERM

# 端口占用检查：已有进程时立即失败，不去终止它。
if /usr/bin/nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
  echo "端口 $PORT 已被占用，请释放后重试（不会终止其他进程）" >&2
  exit 70
fi

echo "启动测试服务 port=$PORT"
PATH="$FLUTTER_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  nohup dart run "$ROOT/test/scripts/container_log_sse_server.dart" \
    "$OUT/service-url.txt" "$OUT/scenario.txt" "$PORT" \
    > "$SERVICE_LOG" 2>&1 < /dev/null &
SERVICE_PID=$!

# 就绪检查：轮询状态端点，超时或服务退出即失败。
readiness() {
  local deadline=$((SECONDS + 30))
  while [ $SECONDS -lt $deadline ]; do
    if [ -f "$OUT/service-url.txt" ] && /usr/bin/curl -fsS \
        --max-time 2 "http://127.0.0.1:$PORT/status" > /dev/null 2>&1; then
      return 0
    fi
    if ! kill -0 "$SERVICE_PID" 2>/dev/null; then
      echo "测试服务提前退出，日志：$SERVICE_LOG" >&2
      /usr/bin/tail -20 "$SERVICE_LOG" >&2
      return 1
    fi
    /bin/sleep 0.2
  done
  echo "等待测试服务就绪超时（30 秒），日志：$SERVICE_LOG" >&2
  /usr/bin/tail -20 "$SERVICE_LOG" >&2
  return 1
}

if ! readiness; then
  exit 71
fi
SERVICE_URL="$(/bin/cat "$OUT/service-url.txt")"
echo "服务就绪"

case "$MODE" in
  unit)
    PATH="$FLUTTER_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
      flutter test test/api_client/container_log_stream_v2_test.dart \
      | tee "$OUT/unit-sse.log"
    exit "${PIPESTATUS[0]}"
    ;;
  ui)
    xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
    xcrun simctl bootstatus "$SIMULATOR_ID" -b > /dev/null 2>&1 || true
    ONEPANEL_UI_TEST_SERVICE="$SERVICE_URL" \
      xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
        -configuration Debug \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -parallel-testing-enabled NO \
        -only-testing:RunnerUITests \
        -test-timeouts-enabled YES \
        -default-test-execution-time-allowance 180 \
        -maximum-test-execution-time-allowance 300 \
        -resultBundlePath "$OUT/ios-ui.xcresult" test \
      | tee "$OUT/ios-ui.log"
    STATUS="${PIPESTATUS[0]}"
    xcrun simctl shutdown "$SIMULATOR_ID" 2>/dev/null || true
    exit "$STATUS"
    ;;
  macos)
    xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
      -configuration Debug -destination 'platform=macOS' \
      -parallel-testing-enabled NO \
      -test-timeouts-enabled YES \
      -default-test-execution-time-allowance 90 \
      -maximum-test-execution-time-allowance 180 \
      -resultBundlePath "$OUT/macos-tests.xcresult" test \
      | tee "$OUT/macos-tests.log"
    exit "${PIPESTATUS[0]}"
    ;;
  *)
    echo "未知模式：$MODE" >&2
    exit 64
    ;;
esac