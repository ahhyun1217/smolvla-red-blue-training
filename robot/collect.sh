#!/usr/bin/env bash
# SO101 유해폐기물 분류/스태킹 데이터 수집 (멀티태스크, 한 데이터셋에 누적)
#
# 사용법:
#   export HF_USER=<your_hf_username>          # 처음 1회만
#   bash collect.sh "<TASK>" <N> [new|resume]
#
# 예:
#   bash collect.sh "put the red die in the box"        40 new      # 첫 배치 = 데이터셋 생성
#   bash collect.sh "put the blue die in the box"       40 resume   # 이어붙이기
#   bash collect.sh "stack the red die on the blue die" 50 resume   # 이어붙이기
#
# 진행은 전부 키로 직접 (시간은 안전 캡일 뿐, 120초 전에 → 누르면 됨):
#   →  현재 에피소드 종료·저장 후 다음 / 리셋 단계도 → 누르면 즉시 다음
#   ←  현재 에피소드 취소·재녹화
#   Esc 전체 중단
set -euo pipefail

: "${HF_USER:?먼저 실행하세요:  export HF_USER=<your_hf_username>}"
REPO_ID="$HF_USER/so101_red_blue_cube_sorting"

TASK="${1:?task 문자열이 필요합니다}"
NEPS="${2:?에피소드 수가 필요합니다}"
MODE="${3:-resume}"   # 첫 배치만 new, 나머지는 resume

if [ "$MODE" = "new" ]; then RESUME=false; else RESUME=true; fi

echo "=== 수집 시작 ==="
echo "  데이터셋 : $REPO_ID"
echo "  task     : $TASK"
echo "  개수     : $NEPS   (mode=$MODE, resume=$RESUME)"
echo "================="

lerobot-record \
  --robot.type=so101_follower \
  --robot.port=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5AE6085270-if00 \
  --robot.id=my_follower \
  --robot.cameras="{ front: {type: opencv, index_or_path: /dev/video33, width: 640, height: 480, fps: 30, fourcc: MJPG}, side: {type: opencv, index_or_path: /dev/video35, width: 640, height: 480, fps: 30, fourcc: MJPG} }" \
  --teleop.type=so101_leader \
  --teleop.port=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5A68012267-if00 \
  --teleop.id=my_leader \
  --dataset.repo_id="$REPO_ID" \
  --dataset.single_task="$TASK" \
  --dataset.num_episodes="$NEPS" \
  --dataset.fps=30 \
  --dataset.episode_time_s=120 \
  --dataset.reset_time_s=120 \
  --resume="$RESUME" \
  --dataset.push_to_hub=false \
  --display_data=true
