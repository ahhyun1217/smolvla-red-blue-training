# SO101 Red/Blue Cube Sorting

SO101 로봇팔로 빨강/파랑 큐브를 색에 따라 분류하는 정책 학습 실험 (유해폐기물 분류 캡스톤).
빨강 → 왼쪽 흰 박스 / 파랑 → 오른쪽 흰 박스. 장면엔 빨강·파랑이 같이 있고, 명령으로 어느 색을 집을지 지정한다.

- task 문자열: `put the red cube in the left white box` · `put the blue cube in the right white box`
- 장면 구성: 항상 **빨강2 + 파랑1**, 큐브 위치/좌우 매 에피소드 랜덤 (박스는 고정)

## 실험 방향 및 이력

### Phase 1 — SmolVLA / GR00T (양방향 분류)
언어조건 VLA 한 모델로 빨강·파랑을 동시에 프롬프트로 구분하는 방식 시도.
- **SmolVLA**: 증강 유/무, freeze 유/무 조합으로 실험
- **GR00T N1.5-3B**: projector + diffusion head만 파인튜닝 (LLM/vision 동결)
- 결과: 적은 데이터(80 ep)에서 **색 grounding이 약해 단일 모델로 양방향 분류 성능 부족**

### Phase 2 — SmolVLA 단일색 모델 (현재)
색마다 별도 모델을 학습해 모델 선택으로 색 라우팅.
- **red 모델**: `smolvla_red_only_frozen` — freeze=True, 60 ep → **성능 양호**
- **blue 모델**: `smolvla_blue_only_frozen` — freeze=True, 70 ep (소수색 분류 난이도로 데이터 추가)
- SmolVLA는 VLM 사전학습 덕에 색 개념 내재 → ACT 대비 색 구분 유리
- 추론은 GPU/CPU 모두 가능 (노트북 배포 고려)

## 데이터셋 (HF, public)

| 데이터셋 | 에피소드 | 프레임 | 태스크 | 비고 |
|---------|---------|-------|-------|------|
| [so101_red_blue_cube_sorting](https://huggingface.co/datasets/AmberHyunKIM/so101_red_blue_cube_sorting) | 80 | 43,878 | 빨강·파랑 양방향 분류 | Phase 1 초기 데이터, 카메라 front/side |
| [so101_red_blue_v2](https://huggingface.co/datasets/AmberHyunKIM/so101_red_blue_v2) | 80 | 40,327 | 빨강·파랑 양방향 분류 | Phase 1 재수집, 카메라 wrist/top |
| [so101_red_only](https://huggingface.co/datasets/AmberHyunKIM/so101_red_only) | 60 | 30,106 | 빨강 2개 → 왼쪽 흰 박스 | Phase 2 단일색, **현재 사용** |
| [so101_blue_only](https://huggingface.co/datasets/AmberHyunKIM/so101_blue_only) | 70 | 23,114 | 파랑 1개 → 오른쪽 흰 박스 | Phase 2 단일색, **현재 사용** |

- 카메라: **wrist, top** (640×480, MJPG) — 손목캠 + 탑뷰
- 색 판별 작업이라 학습 시 **hue/saturation 증강은 끔** (색 왜곡 방지)

## 전체 워크플로우
```
수집(로봇 PC) → HF 업로드 → GPU 머신 ACT 학습 → HF 모델 업로드 → 로봇 PC 추론/평가
```

## `robot/` — 로봇 PC용 (수집 + 추론)
같은 SO101 로봇을 다루는 PC라면 clone 후 바로 쓸 수 있다.

| 파일 | 용도 |
|------|------|
| `setup.sh` | 새 PC 환경 준비 (lerobot 설치 + 로봇/카메라 점검 + 모델 미리받기) |
| `teleop.sh` | 텔레옵 + 카메라 미리보기 (색/시야각 확인, 데이터 저장 안 함) |
| `collect.sh` | 데이터 수집 (범용: `bash collect.sh "<task>" <N> [new\|resume]`) |
| `collect_blue.sh` | 파랑 데이터셋 수집 래퍼 (`so101_blue_only`) |
| `eval.sh` | 학습된 정책으로 추론 (캘리·device·모델 자동 처리) |
| `push_dataset.sh` | 수집한 데이터셋 HF 업로드 (`DATASET` 환경변수로 repo 지정) |
| `GPU_TRAINING.md` | GPU 머신 학습 런북 (ACT 메인 + SmolVLA 옵션) |
| `calibration/` | 로봇 캘리값 (이 로봇 개체 전용) |

### 환경 준비 (새 PC, 같은 로봇 연결 시)
```bash
git clone https://github.com/ahhyun1217/smolvla-red-blue-training.git
cd smolvla-red-blue-training/robot
bash setup.sh                 # lerobot 설치 + 로봇/카메라 점검
bash teleop.sh                # (선택) 카메라 색/시야각 눈으로 확인
```
- 캘리브레이션은 `robot/calibration/` 에서 자동 인식 (복사 불필요)
- 카메라/포트가 다르면 환경변수로 덮어쓰기:
  ```bash
  WRIST_CAM=/dev/videoN TOP_CAM=/dev/videoM ROBOT_PORT=/dev/serial/by-id/... bash teleop.sh
  ```

### 데이터 수집
```bash
export HF_USER=AmberHyunKIM

export DATASET=so101_red_only
bash collect.sh "put the red cube in the left white box" 60 new     # 빨강
bash push_dataset.sh

bash collect_blue.sh                                                # 파랑 40개 (so101_blue_only)
bash collect_blue.sh 20 resume                                      # 이어쌓기
DATASET=so101_blue_only bash push_dataset.sh
```
키: `→` 저장·다음 / `←` 취소·재녹화 / `Esc` 중단

### 추론 (학습된 ACT로)
```bash
# eval.sh의 POLICY를 act_red_only 등으로 지정하거나 --policy.path 직접 지정
bash eval.sh "put the red cube in the left white box" 1
```
device 자동 (GPU 있으면 cuda, 없으면 cpu) · 모델은 HF에서 자동 다운로드(public)

## 학습 (GPU 머신)
ACT 두 모델(red/blue) 학습 절차는 [`robot/GPU_TRAINING.md`](robot/GPU_TRAINING.md).

### 실험 이력 — Config / Dataset / Model 매핑

#### SmolVLA 실험

| 설명 | Config | 데이터셋 | 학습된 모델 |
|------|--------|---------|------------|
| 빨강 단독 — vision 동결 ✅ | `configs/smolvla/red_only_frozen.yaml` | [so101_red_only](https://huggingface.co/datasets/AmberHyunKIM/so101_red_only) (60 ep) | [smolvla_red_only_frozen](https://huggingface.co/AmberHyunKIM/smolvla_red_only_frozen) |
| 빨강 단독 — vision 언프리즈 | `configs/smolvla/red_only_unfrozen.yaml` | [so101_red_only](https://huggingface.co/datasets/AmberHyunKIM/so101_red_only) (60 ep) | [smolvla_red_only_unfrozen](https://huggingface.co/AmberHyunKIM/smolvla_red_only_unfrozen) |
| 파랑 단독 — vision 동결 (진행중) | `configs/smolvla/blue_only_frozen.yaml` | [so101_blue_only](https://huggingface.co/datasets/AmberHyunKIM/so101_blue_only) (70 ep) | [smolvla_blue_only_frozen](https://huggingface.co/AmberHyunKIM/smolvla_blue_only_frozen) |
| 양방향 분류 — 증강 있음 | `configs/smolvla/red_blue.yaml` | [so101_red_blue_cube_sorting](https://huggingface.co/datasets/AmberHyunKIM/so101_red_blue_cube_sorting) (80 ep) | [smolvla_red_blue_cube_sorting](https://huggingface.co/AmberHyunKIM/smolvla_red_blue_cube_sorting) |
| 양방향 분류 — 증강 없음 | `configs/smolvla/red_blue_no_aug.yaml` | [so101_red_blue_cube_sorting](https://huggingface.co/datasets/AmberHyunKIM/so101_red_blue_cube_sorting) (80 ep) | [smolvla_red_blue_no_aug](https://huggingface.co/AmberHyunKIM/smolvla_red_blue_no_aug) |

#### GR00T N1.5 실험

| 설명 | Config | 데이터셋 | 학습된 모델 |
|------|--------|---------|------------|
| 양방향 분류 v1 | `configs/groot/red_blue.yaml` | [so101_red_blue_cube_sorting](https://huggingface.co/datasets/AmberHyunKIM/so101_red_blue_cube_sorting) (80 ep) | [groot_red_blue_cube_sorting](https://huggingface.co/AmberHyunKIM/groot_red_blue_cube_sorting) |
| 양방향 분류 v2 (10 epoch) | `configs/groot/red_blue_v2.yaml` | [so101_red_blue_v2](https://huggingface.co/datasets/AmberHyunKIM/so101_red_blue_v2) (80 ep) | [groot_red_blue_v2](https://huggingface.co/AmberHyunKIM/groot_red_blue_v2) |

## 참고
- 캘리브레이션 JSON은 **이 물리 로봇 개체 전용** (모터 영점값). 다른 로봇이면 새로 캘리.
- GPU 학습 머신은 캘리 불필요 (로봇 연결 안 함).
- 카메라: wrist=USB 3.2, top=USB 3.3, 둘 다 MJPG 필수 (같은 USB 버스 대역폭).
- 리더 팔 전원 배럴잭이 잘 빠짐 → 텔레옵/수집 전 모터 스캔으로 6개 응답 확인.
