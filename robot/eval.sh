#!/usr/bin/env bash
# 학습된 SmolVLA 정책을 로봇 연결된 PC에서 평가/추론 (clone 후 바로 실행 가능)
# 정책이 로봇을 직접 제어한다. task 문자열(=음성 명령에 해당)로 빨강/파랑을 지정.
#
# 전제 (한 번만): lerobot 설치 + 로봇/카메라 USB 연결
# 사용법:
#   bash eval.sh "<TASK>" [N]
#
# 예:
#   bash eval.sh "put the red cube in the left box"   1
#   bash eval.sh "put the blue cube in the right box" 1
#
# 환경변수로 덮어쓰기 가능:
#   HF_USER (기본 AmberHyunKIM), DEVICE (기본 자동: GPU 있으면 cuda, 없으면 cpu)
#   FRONT_CAM/SIDE_CAM (카메라 노드), ROBOT_PORT (로봇 시리얼 포트)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HF_USER="${HF_USER:-AmberHyunKIM}"
POLICY="$HF_USER/smolvla_red_blue_cube_sorting"

# 캘리브레이션: 스크립트 옆 calibration/ 폴더에서 자동 인식 (캐시 복사 불필요)
CALIB_DIR="$SCRIPT_DIR/calibration/robots/so101_follower"

# 로봇/카메라 (PC가 바뀌면 환경변수로 덮어쓰기)
ROBOT_PORT="${ROBOT_PORT:-/dev/serial/by-id/usb-1a86_USB_Single_Serial_5AE6085270-if00}"
FRONT_CAM="${FRONT_CAM:-/dev/video33}"
SIDE_CAM="${SIDE_CAM:-/dev/video35}"
DEVICE="${DEVICE:-}"   # 비우면 정책 설정(cuda) → 없으면 자동 cpu 폴백

TASK="${1:?task 문자열이 필요합니다 (예: \"put the red cube in the left box\")}"
NEPS="${2:-1}"

echo "=== 평가(추론) 시작 ==="
echo "  정책   : $POLICY"
echo "  task   : $TASK"
echo "  개수   : $NEPS"
echo "  캘리   : $CALIB_DIR"
echo "  device : ${DEVICE:-auto(cuda→cpu)}"
echo "======================="

DEVICE_ARG=()
[ -n "$DEVICE" ] && DEVICE_ARG=(--policy.device="$DEVICE")

lerobot-record \
  --robot.type=so101_follower \
  --robot.port="$ROBOT_PORT" \
  --robot.id=my_follower \
  --robot.calibration_dir="$CALIB_DIR" \
  --robot.cameras="{ front: {type: opencv, index_or_path: $FRONT_CAM, width: 640, height: 480, fps: 30, fourcc: MJPG}, side: {type: opencv, index_or_path: $SIDE_CAM, width: 640, height: 480, fps: 30, fourcc: MJPG} }" \
  --policy.path="$POLICY" \
  "${DEVICE_ARG[@]}" \
  --dataset.repo_id="$HF_USER/eval_smolvla_red_blue" \
  --dataset.single_task="$TASK" \
  --dataset.num_episodes="$NEPS" \
  --dataset.fps=30 \
  --dataset.episode_time_s=240 \
  --dataset.reset_time_s=5 \
  --dataset.push_to_hub=false \
  --display_data=true
