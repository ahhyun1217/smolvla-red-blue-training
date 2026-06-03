#!/usr/bin/env bash
# 학습된 SmolVLA 정책을 노트북(로봇 연결)에서 평가/추론
# 정책이 로봇을 직접 제어한다. task 문자열(=음성 명령에 해당)로 빨강/파랑을 지정.
#
# 사용법:
#   export HF_USER=<your_hf_username>
#   bash eval.sh "<TASK>" [N]
#
# 예:
#   bash eval.sh "put the red cube in the left box"   5
#   bash eval.sh "put the blue cube in the right box" 5
#
# 진행 키 (Xorg 세션에서):
#   →  현재 에피소드 종료 후 다음 / 리셋도 → 로 넘김
#   ←  현재 에피소드 취소·재시도
#   Esc 중단
set -euo pipefail

: "${HF_USER:?먼저 실행하세요:  export HF_USER=<your_hf_username>}"
POLICY="$HF_USER/smolvla_red_blue_cube_sorting"

TASK="${1:?task 문자열이 필요합니다 (예: \"put the red cube in the left box\")}"
NEPS="${2:-5}"

echo "=== 평가(추론) 시작 ==="
echo "  정책 : $POLICY"
echo "  task : $TASK"
echo "  개수 : $NEPS"
echo "======================="

lerobot-record \
  --robot.type=so101_follower \
  --robot.port=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5AE6085270-if00 \
  --robot.id=my_follower \
  --robot.cameras="{ front: {type: opencv, index_or_path: /dev/video33, width: 640, height: 480, fps: 30, fourcc: MJPG}, side: {type: opencv, index_or_path: /dev/video35, width: 640, height: 480, fps: 30, fourcc: MJPG} }" \
  --policy.path="$POLICY" \
  --policy.device=cpu \
  --dataset.repo_id="$HF_USER/eval_smolvla_red_blue" \
  --dataset.single_task="$TASK" \
  --dataset.num_episodes="$NEPS" \
  --dataset.fps=30 \
  --dataset.episode_time_s=240 \
  --dataset.reset_time_s=5 \
  --dataset.push_to_hub=false \
  --display_data=true
