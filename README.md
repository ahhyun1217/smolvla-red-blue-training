# SmolVLA SO101 Red/Blue Cube Sorting

SO101 로봇팔로 빨강/파랑 큐브를 색에 따라 분류하는 SmolVLA 정책 학습 실험 (유해폐기물 분류 캡스톤).
초록 큐브는 방해물(distractor)로 두고, 언어 명령으로 색을 지정해 분류한다.

- 빨강 → 왼쪽 상자 / 파랑 → 오른쪽 상자 / 초록 → 안 집음
- task 문자열: `put the red cube in the left box` · `put the blue cube in the right box`

## 데이터셋
- HF: [AmberHyunKIM/so101_red_blue_cube_sorting](https://huggingface.co/datasets/AmberHyunKIM/so101_red_blue_cube_sorting)
- 80 에피소드 / 43,878 프레임 (빨강 40 + 파랑 40)
- 카메라: front, side (640×480, MJPG)

## 학습된 모델
- HF: [AmberHyunKIM/smolvla_red_blue_cube_sorting](https://huggingface.co/AmberHyunKIM/smolvla_red_blue_cube_sorting)
- 정책: SmolVLA base (frozen vision encoder), language-conditioned
- 학습: 20,000 steps / batch 32 / RTX 5070 Ti
- 색 판별 작업이라 hue/saturation 증강은 끔 (brightness/contrast/sharpness/affine만)

### Loss 수렴
| step | loss |
|------|------|
| 200 | 1.676 |
| 1,000 | 0.365 |
| 5,000 | 0.199 |
| 10,000 | 0.102 |
| 20,000 | 0.055 |

## 전체 워크플로우
```
수집(로봇 PC) → HF 업로드 → GPU 머신 학습 → HF 모델 업로드 → 로봇 PC 추론/평가
```

## `robot/` — 로봇 PC용 (수집 + 추론)
같은 SO101 로봇을 다루는 PC라면 clone 후 바로 쓸 수 있다.

| 파일 | 용도 |
|------|------|
| `setup.sh` | 새 PC 환경 준비 (lerobot 설치 + 로봇/카메라 점검 + 모델 미리받기) |
| `eval.sh` | 학습된 정책으로 추론 (캘리·device·모델 자동 처리) |
| `collect.sh` | 텔레오퍼레이션 데이터 수집 |
| `push_dataset.sh` | 수집한 데이터셋 HF 업로드 |
| `GPU_TRAINING.md` | GPU 머신 학습 런북 |
| `calibration/` | 로봇 캘리값 (이 로봇 개체 전용) |

### 추론 (새 PC, 같은 로봇 연결 시 — 두 단계)
```bash
git clone https://github.com/ahhyun1217/smolvla-red-blue-training.git
cd smolvla-red-blue-training/robot

bash setup.sh                                          # 1) 환경 준비
bash eval.sh "put the red cube in the left box" 1      # 2) 추론
```
- 캘리브레이션은 `robot/calibration/` 에서 자동 인식 (복사 불필요)
- device 자동 (GPU 있으면 cuda, 없으면 cpu) · 모델은 HF에서 자동 다운로드(public)
- 카메라/포트가 다르면 환경변수로 덮어쓰기:
  ```bash
  FRONT_CAM=/dev/videoN SIDE_CAM=/dev/videoM ROBOT_PORT=/dev/serial/by-id/... \
    bash eval.sh "put the blue cube in the right box" 1
  ```

### 데이터 수집
```bash
export HF_USER=AmberHyunKIM
bash collect.sh "put the red cube in the left box"  40 new      # 첫 배치
bash collect.sh "put the blue cube in the right box" 40 resume   # 이어붙이기
bash push_dataset.sh                                             # HF 업로드
```

## 학습 재현 (GPU 머신)
자세한 절차는 [`robot/GPU_TRAINING.md`](robot/GPU_TRAINING.md).
```bash
conda activate lerobot
lerobot-train --config_path train_smolvla_red_blue.yaml
```

## 참고
- 캘리브레이션 JSON은 **이 물리 로봇 개체 전용** (모터 영점값). 다른 로봇이면 새로 캘리.
- GPU 학습 머신은 캘리 불필요 (로봇 연결 안 함).
