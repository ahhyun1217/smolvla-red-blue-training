#!/usr/bin/env bash
# 텔레옵 + 카메라 미리보기 (데이터 저장 안 함).
# 새 환경(천장/조명/카메라 배치) 세팅 후 색·시야각 확인용.
#   - 리더 팔을 움직이면 팔로워가 따라옴
#   - front/side 카메라 창이 떠서 어느 게 front인지, 색이 잘 잡히는지 눈으로 확인
#
# 사용법:  bash teleop.sh
# 카메라/포트 다르면 환경변수로 덮어쓰기:
#   WRIST_CAM=/dev/videoN TOP_CAM=/dev/videoM bash teleop.sh
set -euo pipefail

ROBOT_PORT="${ROBOT_PORT:-/dev/serial/by-id/usb-1a86_USB_Single_Serial_5AE6085270-if00}"
TELEOP_PORT="${TELEOP_PORT:-/dev/serial/by-id/usb-1a86_USB_Single_Serial_5A68012267-if00}"
WRIST_CAM="${WRIST_CAM:-/dev/video33}"   # 손목 시점
TOP_CAM="${TOP_CAM:-/dev/video35}"       # 탑뷰

echo "=== 텔레옵 (카메라 미리보기) ==="
echo "  wrist=$WRIST_CAM  top=$TOP_CAM"
echo "  창에서 색/시야각 확인. 종료는 Ctrl+C 또는 창 esc"
echo "================================"

lerobot-teleoperate \
  --robot.type=so101_follower \
  --robot.port="$ROBOT_PORT" \
  --robot.id=my_follower \
  --robot.cameras="{ wrist: {type: opencv, index_or_path: $WRIST_CAM, width: 640, height: 480, fps: 30, fourcc: MJPG}, top: {type: opencv, index_or_path: $TOP_CAM, width: 640, height: 480, fps: 30, fourcc: MJPG} }" \
  --teleop.type=so101_leader \
  --teleop.port="$TELEOP_PORT" \
  --teleop.id=my_leader \
  --display_data=true
