#!/bin/bash

# 启用严格模式
set -euo pipefail

# 定义变量
RESULT_DIR="/home/lbs/software/jmeter/result"
JMX_FILE="/home/lbs/software/jmeter/conf/pushEventToKafka.jmx"
RESULT_FILE="${RESULT_DIR}/01-result.csv"
LOG_FILE="${RESULT_DIR}/01-log.log"
PID_FILE="${RESULT_DIR}/jmeter.pid"

# 函数：清理旧的结果和日志文件
cleanup() {
  echo "正在删除旧的结果和日志文件..."
  rm -f "$RESULT_FILE" "$LOG_FILE"
}

# 函数：检查 JMeter 是否正在运行
is_running() {
  if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
      return 0  # 正在运行
    else
      rm -f "$PID_FILE"  # 移除无效的 PID 文件
      return 1  # 未运行
    fi
  else
    return 1  # 未运行
  fi
}

# 函数：运行 JMeter 测试
start_jmeter() {
  if is_running; then
    echo "JMeter 已在运行，PID: $(cat "$PID_FILE")"
    exit 1
  fi

  echo "启动 JMeter 测试..."
  nohup jmeter -n \
         -t "$JMX_FILE" \
         -l "$RESULT_FILE" \
         -j "$LOG_FILE" \
         > /dev/null 2>&1 &
  echo $! > "$PID_FILE"
  echo "JMeter 测试已在后台启动，PID: $(cat "$PID_FILE")"
}

# 函数：停止 JMeter 测试
stop_jmeter() {
  if is_running; then
    PID=$(cat "$PID_FILE")
    echo "正在停止 JMeter 测试，PID: $PID..."
    kill "$PID"
    # 等待进程结束
    while ps -p "$PID" > /dev/null 2>&1; do
      sleep 1
    done
    rm -f "$PID_FILE"
    echo "JMeter 测试已停止。"
  else
    echo "JMeter 没有运行。"
  fi
}

# 函数：重启 JMeter 测试
restart_jmeter() {
  echo "正在重启 JMeter 测试..."
  stop_jmeter
  # 可选：等待一段时间确保旧进程完全停止
  sleep 2
  start_jmeter
}

# 函数：查看 JMeter 运行状态
status_jmeter() {
  if is_running; then
    echo "JMeter 正在运行，PID: $(cat "$PID_FILE")"
  else
    echo "JMeter 没有运行。"
  fi
}

# 函数：显示用法说明
usage() {
  echo "用法: $0 {start|stop|restart|status}"
  exit 1
}

# 主执行流程
case "${1:-}" in
  start)
    cleanup
    start_jmeter
    ;;
  stop)
    stop_jmeter
    ;;
  restart)
    restart_jmeter
    ;;
  status)
    status_jmeter
    ;;
  *)
    usage
    ;;
esac
