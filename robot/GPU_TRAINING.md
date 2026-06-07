# SO101 분류 정책 학습 런북 (GPU 머신용)

노트북에서 수집·업로드한 데이터셋을 **GPU 머신에서 학습**하는 절차.
GPU 머신엔 노트북의 커스텀 lerobot이 아니라 **공식 최신 lerobot을 새로 설치**한다 (데이터는 HF로 이동하므로 git 불필요).

## 현재 방향 (2026-06)
언어조건 VLA(SmolVLA/GR00T)는 적은 데이터로 **색 grounding이 약했음** → **단일색 ACT 2개 + 모델 선택 라우팅**으로 전환.
- 명령(빨강/파랑)은 모델 *안의* 텍스트가 아니라 **어느 모델을 로드하느냐**로 매핑된다.
- ACT는 언어조건 없음·가볍고·CPU 추론 빠름 → SmolVLA가 노트북에서 멈추던 문제도 해결.

### 데이터셋 (HF, public)
| repo | 에피소드 | 집는 색 | task 라벨 |
|---|---|---|---|
| `AmberHyunKIM/so101_red_only`  | 60 | 빨강 2개 → 왼쪽 흰 박스 | `put the red cube in the left white box` |
| `AmberHyunKIM/so101_blue_only` | 70 | 파랑 1개 → 오른쪽 흰 박스 | `put the blue cube in the right white box` |

- 장면 구성: 항상 **빨강2 + 파랑1**, 큐브 위치/좌우 매 에피소드 랜덤 (박스는 고정)
- 카메라 키: `observation.images.wrist`, `observation.images.top` (640×480 MJPG)
- (옛 데이터 `so101_red_blue_cube_sorting`, `so101_red_blue_v2`는 front/side·구 task 문자열 — 사용 안 함)

---

## 0. 전제 (GPU 머신)
- Linux + NVIDIA GPU, 드라이버 + CUDA (`nvidia-smi` 동작)
- Python **3.12+**
- 장시간 작업이므로 `tmux`/`screen` 안에서 실행 권장

## 1. 공식 최신 lerobot 설치
```bash
conda create -n lerobot python=3.12 -y
conda activate lerobot
git clone https://github.com/huggingface/lerobot.git
cd lerobot
pip install -e ".[smolvla]"      # ACT만 쓸 거면 ".[smolvla]" 없이 기본 설치도 OK (ACT는 base 포함)
```

## 2. HuggingFace 로그인
```bash
hf auth login        # write 토큰
hf auth whoami       # AmberHyunKIM 확인
```

---

## 3. ACT 학습 (메인) — 색마다 모델 1개

⚠️ **색 jitter 증강은 끈다.** 일반 ACT 가이드는 색 jitter를 권하지만 그건 *색을 무시하고 일반화*하라는 것 — 우리는 색이 유일한 판별 신호라 끄지 않으면 학습이 망가진다. (hue/saturation weight=0)

### 3-1. red ACT
```bash
lerobot-train \
  --policy.type=act \
  --dataset.repo_id=AmberHyunKIM/so101_red_only \
  --output_dir=outputs/train/act_red \
  --job_name=act_red \
  --policy.device=cuda \
  --batch_size=8 \
  --steps=100000 \
  --save_freq=10000 \
  --dataset.image_transforms.enable=true \
  --dataset.image_transforms.tfs.hue.weight=0.0 \
  --dataset.image_transforms.tfs.saturation.weight=0.0 \
  --wandb.enable=false \
  --policy.push_to_hub=true \
  --policy.repo_id=AmberHyunKIM/act_red_only
```

### 3-2. blue ACT (dataset/output/repo만 blue로)
```bash
lerobot-train \
  --policy.type=act \
  --dataset.repo_id=AmberHyunKIM/so101_blue_only \
  --output_dir=outputs/train/act_blue \
  --job_name=act_blue \
  --policy.device=cuda \
  --batch_size=8 \
  --steps=100000 \
  --save_freq=10000 \
  --dataset.image_transforms.enable=true \
  --dataset.image_transforms.tfs.hue.weight=0.0 \
  --dataset.image_transforms.tfs.saturation.weight=0.0 \
  --wandb.enable=false \
  --policy.push_to_hub=true \
  --policy.repo_id=AmberHyunKIM/act_blue_only
```

**조정 포인트**
- `--batch_size`: ACT는 8부터, VRAM 여유 있으면 ↑. OOM이면 ↓.
- `--steps`: ACT는 보통 100k면 수렴. 짧게 검증만이면 줄여도 됨.
- 플래그 이름은 **GPU의 최신 lerobot 기준** — 다르면 `lerobot-train --help` 확인.

### 검증 (노트북, 로봇 연결)
red ACT 받아서 **빨강 옆에 파랑을 놓고** 돌렸을 때 파랑 무시하고 빨강만 집으면 색 구분 성공.
```bash
# eval.sh의 POLICY를 act_red_only로 바꾸거나 --policy.path 직접 지정
```
- 빨강만 잘 집음 → blue ACT도 같은 식으로 확정 → 데모 완성
- 파랑도 집어버림 → 위치/개수 지름길 의심: 위치 랜덤·조명 점검, 데이터 보강(색당 +20)

---

## 4. (옵션) SmolVLA — 언어조건 "한 모델 + 음성" 버전
데모용으로 "프롬프트로 색 지정" 스토리를 원하면. **단 추론은 GPU 머신에서** 돌려야 매끄럽다(노트북 CPU는 느림). 두 단일색 데이터셋을 함께 학습:

```bash
lerobot-train \
  --policy.path=lerobot/smolvla_base \
  --dataset.repo_id=AmberHyunKIM/so101_red_only \
  --output_dir=outputs/train/smolvla_red_blue \
  --policy.device=cuda \
  --batch_size=64 \
  --steps=20000 \
  --save_freq=5000 \
  --dataset.image_transforms.enable=true \
  --dataset.image_transforms.tfs.hue.weight=0.0 \
  --dataset.image_transforms.tfs.saturation.weight=0.0 \
  --policy.push_to_hub=true \
  --policy.repo_id=AmberHyunKIM/smolvla_red_blue
```
- 단일 데이터셋만 지정하면 한 색만 배움 → 두 데이터셋을 같이 쓰려면 `MultiLeRobotDataset` 또는 합본 데이터셋 필요. (언어조건은 빨강/파랑이 한 학습에 섞여 있어야 작동)
- 색 grounding은 데이터 많을수록 유리 (색당 60+).

---

## 메모 / 트러블슈팅
- **lerobot 버전차 config 로드 에러**: 노트북(구버전)에서 GPU(신버전)가 만든 모델 config를 읽을 때 `use_peft`/`compile_model`/`compile_mode` 필드로 DecodingError가 날 수 있다. 노트북 `policies/smolvla/configuration_smolvla.py`의 SmolVLAConfig에 아래 3줄(기본값) 추가하면 해결:
  ```python
  use_peft: bool = False
  compile_model: bool = False
  compile_mode: str | None = None
  ```
- **카메라**: wrist=`/dev/video33`(USB 3.2), top=`/dev/video35`(USB 3.3). 노드 번호는 PC마다 다름 → `WRIST_CAM`/`TOP_CAM` 환경변수로 덮어쓰기. 두 카메라 같은 USB 버스라 둘 다 **MJPG 필수**.
- **시리얼 포트**: ttyACM 번호는 재연결마다 바뀜 → `/dev/serial/by-id/` 시리얼 경로 사용 (follower 5AE6085270, leader 5A68012267).
- **리더 전원**: 리더 팔 배럴잭이 잘 빠짐 → 텔레옵/수집 전 `FeetechMotorsBus.scan_port`로 6개 모터 응답 확인.
- 데이터셋 포맷 v3.0 — 노트북·GPU 양쪽 호환.
- 노트북은 절대 `git pull` 금지 (커스텀 record.py 충돌). GPU만 최신.
