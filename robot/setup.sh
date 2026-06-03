#!/usr/bin/env bash
# 새 PC(로봇 연결용)에서 추론 환경을 한 번에 준비한다.
#   1) Python 버전 확인
#   2) lerobot(+smolvla) 설치 (이미 있으면 건너뜀)
#   3) 로봇 시리얼 포트 / 카메라 연결 점검
#   4) 정책 모델 미리 다운로드 (선택)
#
# 사용법:  bash setup.sh
# 끝나면:  bash eval.sh "put the red cube in the left box" 1
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HF_USER="${HF_USER:-AmberHyunKIM}"
POLICY="$HF_USER/smolvla_red_blue_cube_sorting"
LEROBOT_SRC="${LEROBOT_SRC:-$HOME/lerobot}"   # 공식 lerobot 클론 위치

ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
err()  { printf '  \033[31m✗\033[0m %s\n' "$1"; }

echo "=== [1/4] Python 확인 ==="
if ! command -v python >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  err "python 없음 — Python 3.10+ 설치 필요"; exit 1
fi
PY=$(command -v python || command -v python3)
PYVER=$("$PY" -c 'import sys;print("%d.%d"%sys.version_info[:2])')
ok "python $PYVER ($PY)"
"$PY" -c 'import sys;sys.exit(0 if sys.version_info[:2]>=(3,10) else 1)' \
  || warn "Python 3.10+ 권장 (현재 $PYVER)"

echo "=== [2/4] lerobot(+smolvla) 설치 ==="
if command -v lerobot-record >/dev/null 2>&1; then
  ok "lerobot 이미 설치됨 ($(command -v lerobot-record))"
else
  warn "lerobot 없음 → 공식 레포 설치 시작 ($LEROBOT_SRC)"
  if [ ! -d "$LEROBOT_SRC/.git" ]; then
    git clone https://github.com/huggingface/lerobot.git "$LEROBOT_SRC" || { err "clone 실패"; exit 1; }
  fi
  ( cd "$LEROBOT_SRC" && pip install -e ".[smolvla]" ) || { err "pip 설치 실패"; exit 1; }
  command -v lerobot-record >/dev/null 2>&1 && ok "lerobot 설치 완료" || { err "설치했는데 lerobot-record 안 보임"; exit 1; }
fi

echo "=== [3/4] 로봇/카메라 연결 점검 ==="
echo "  [시리얼 포트]"
if ls /dev/serial/by-id/ >/dev/null 2>&1 && [ -n "$(ls -A /dev/serial/by-id/ 2>/dev/null)" ]; then
  ls -l /dev/serial/by-id/ | sed 's/^/    /'
  ls /dev/serial/by-id/ 2>/dev/null | grep -q 5AE6085270 && ok "follower(5AE6085270) 감지" \
    || warn "follower 시리얼(5AE6085270) 안 보임 — 다른 로봇이면 ROBOT_PORT 환경변수로 지정"
else
  err "시리얼 포트 없음 — 로봇 USB/전원 확인"
fi
echo "  [카메라]"
if ls /dev/v4l/by-path/ >/dev/null 2>&1; then
  ls /dev/v4l/by-path/ 2>/dev/null | grep -i 'usb' | sed 's/^/    /' | head
  warn "카메라 노드 번호는 PC마다 다름 — eval.sh가 기본 /dev/video33,35 사용. 다르면 FRONT_CAM/SIDE_CAM 으로 덮어쓰기"
else
  warn "USB 카메라 안 보임 — 케이블 확인"
fi

echo "=== [4/4] 정책 모델 미리 다운로드 (선택) ==="
read -r -p "  지금 모델($POLICY) 받아둘까요? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  "$PY" - "$POLICY" <<'PY'
import sys
from huggingface_hub import snapshot_download
p = snapshot_download(sys.argv[1])
print("  다운로드 완료:", p)
PY
  ok "모델 캐시 준비됨"
else
  warn "건너뜀 — eval.sh 첫 실행 때 자동 다운로드(1.2GB)됨"
fi

echo
echo "=== 준비 끝 ==="
echo "  추론 실행:  bash eval.sh \"put the red cube in the left box\" 1"
echo "  (카메라/포트 다르면)  FRONT_CAM=/dev/videoN SIDE_CAM=/dev/videoM ROBOT_PORT=/dev/serial/by-id/... bash eval.sh ..."
