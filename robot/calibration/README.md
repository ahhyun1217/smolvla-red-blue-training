# SO101 캘리브레이션 (이 로봇 개체 전용)

이 폴더의 JSON은 **amber의 SO101 로봇/리더 개체**의 모터 영점·가동범위 값이다.
`homing_offset`, `range_min/max`는 이 물리 조립체에 종속 → **같은 로봇**을 제어하는 다른 PC에서만 재사용 가능. 다른 로봇이면 새로 캘리할 것.

- follower(로봇): `robots/so101_follower/my_follower.json`  (serial 5AE6085270)
- leader(리더): `teleoperators/so101_leader/my_leader.json`  (serial 5A68012267)
- ⚠️ GPU 학습 머신은 캘리 불필요 (로봇 연결 안 함, 학습만).

## 다른 PC에서 쓰는 법

**방법 A — 같은 캐시 경로에 복사** (가장 간단, 스크립트 수정 불필요):
```bash
mkdir -p ~/.cache/huggingface/lerobot/calibration/robots/so101_follower
mkdir -p ~/.cache/huggingface/lerobot/calibration/teleoperators/so101_leader
cp calibration/robots/so101_follower/my_follower.json \
   ~/.cache/huggingface/lerobot/calibration/robots/so101_follower/
cp calibration/teleoperators/so101_leader/my_leader.json \
   ~/.cache/huggingface/lerobot/calibration/teleoperators/so101_leader/
```

**방법 B — calibration_dir 지정** (repo에서 바로 참조):
```bash
lerobot-record ... \
  --robot.calibration_dir="$(pwd)/calibration/robots/so101_follower" \
  --teleop.calibration_dir="$(pwd)/calibration/teleoperators/so101_leader"
```
(robot.id=`my_follower`, teleop.id=`my_leader` 이면 폴더 안 `my_follower.json`/`my_leader.json` 을 찾는다.)
