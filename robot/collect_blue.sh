#!/usr/bin/env bash
# 파랑 단일색 데이터셋(so101_blue_only) 40개 수집.
# 장면은 빨강2 + 파랑1 그대로, 로봇은 파랑 1개만 집어 오른쪽 흰 박스로.
#
# 사용법:
#   bash collect_blue.sh                 # 처음부터 40개 (new)
#   bash collect_blue.sh 15 resume       # 끊겼을 때 15개 더 이어쌓기
#
# 키:  → 저장·다음 / ← 취소·재녹화 / Esc 중단
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export HF_USER="${HF_USER:-AmberHyunKIM}"
export DATASET="${DATASET:-so101_blue_only}"

NEPS="${1:-40}"      # 이번에 찍을 개수
MODE="${2:-new}"     # 첫 배치 new, 이어쌓기 resume

bash "$SCRIPT_DIR/collect.sh" "put the blue cube in the right white box" "$NEPS" "$MODE"
