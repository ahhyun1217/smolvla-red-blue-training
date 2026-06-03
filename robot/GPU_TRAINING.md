# SO101 분류 정책 학습 런북 (GPU 머신용)

노트북에서 수집·업로드한 데이터셋을 **GPU 머신에서 SmolVLA로 학습**하는 절차.
GPU 머신엔 노트북의 커스텀 lerobot이 아니라 **공식 최신 lerobot을 새로 설치**한다 (데이터는 HF로 이동하므로 git 불필요).

- 데이터셋(HF, public): `AmberHyunKIM/so101_red_blue_cube_sorting`
- 카메라 키: `observation.images.front`, `observation.images.side`
- task 라벨: `put the red cube in the left box` / `put the blue cube in the right box`
- 목표(1차): **분류 검증** — 색 구분이 실제로 학습되는지 확인 (스태킹은 별도 데이터셋, 나중)

---

## 0. 전제 (GPU 머신)
- Linux + NVIDIA GPU, 드라이버 + CUDA 설치됨 (`nvidia-smi` 동작)
- Python **3.12+** (공식 최신 lerobot 요구사항)
- Tailscale로 SSH 접속해서 아래를 실행 (장시간이므로 `tmux`/`screen` 안에서 권장)

```bash
nvidia-smi          # GPU 보이는지
python --version    # 3.12+ 확인
```

## 1. 환경 + 공식 최신 lerobot 설치 (SmolVLA 포함)
```bash
# conda 환경 (예시)
conda create -n lerobot python=3.12 -y
conda activate lerobot

# 공식 최신 클론 + smolvla extra 설치
git clone https://github.com/huggingface/lerobot.git
cd lerobot
pip install -e ".[smolvla]"
```

## 2. HuggingFace 로그인 (데이터 pull + 모델 push용)
```bash
hf auth login        # write 토큰 입력 (구버전이면 huggingface-cli login)
hf auth whoami       # AmberHyunKIM 확인
```

## 3. 데이터셋 확인 (선택 — train이 자동으로 받지만 미리 점검)
```bash
python - <<'PY'
from lerobot.datasets.lerobot_dataset import LeRobotDataset
ds = LeRobotDataset("AmberHyunKIM/so101_red_blue_cube_sorting")
print("episodes:", ds.meta.total_episodes, "| frames:", ds.meta.total_frames)
print("features:", list(ds.meta.features.keys()))
PY
# 기대: episodes 80, front/side 카메라 + action + state
```

## 4. SmolVLA 학습 (분류 검증)
색으로 분류하는 작업이므로 **hue/saturation 증강은 끈다** (색 왜곡 방지). 나머지(밝기/대비/선명도/아핀)는 켜서 조명·위치 강건성 확보.

```bash
lerobot-train \
  --policy.path=lerobot/smolvla_base \
  --dataset.repo_id=AmberHyunKIM/so101_red_blue_cube_sorting \
  --output_dir=outputs/train/smolvla_red_blue \
  --job_name=smolvla_red_blue \
  --policy.device=cuda \
  --batch_size=64 \
  --steps=20000 \
  --save_freq=5000 \
  --dataset.image_transforms.enable=true \
  --dataset.image_transforms.tfs.hue.weight=0.0 \
  --dataset.image_transforms.tfs.saturation.weight=0.0 \
  --wandb.enable=false \
  --policy.push_to_hub=true \
  --policy.repo_id=AmberHyunKIM/smolvla_red_blue_cube_sorting
```

**조정 포인트**
- `--batch_size` : GPU VRAM에 맞춰 조절 (OOM 나면 32, 16으로 ↓). SmolVLA base ≈ 450M 파라미터.
- `--steps` : 80 에피소드 검증엔 20k 정도면 충분. 길게 보고 싶으면 ↑.
- `--wandb.enable=true` 로 켜면 로스 곡선 모니터링 (W&B 로그인 필요).
- ⚠️ **플래그 이름은 GPU의 최신 lerobot 기준** — 다르면 `lerobot-train --help`로 확인. (특히 `--policy.path` vs `--policy.pretrained_path`, `--steps` vs `--policy.max_steps` 등 버전차 가능)

## 5. 모니터링
```bash
# 다른 셸에서 (tmux pane)
nvidia-smi -l 2       # GPU 사용률
# wandb 켰으면 대시보드, 아니면 outputs/train/.../ 의 로그/체크포인트 확인
ls outputs/train/smolvla_red_blue/checkpoints/
```

## 6. 학습 후
- 체크포인트: `outputs/train/smolvla_red_blue/checkpoints/last/`
- `push_to_hub=true`였으면 → `AmberHyunKIM/smolvla_red_blue_cube_sorting` 에 모델 업로드됨
- **평가는 노트북에서** (로봇 연결된 쪽): 노트북에서 이 모델 pull → `lerobot-record`에 `--policy.path=...`로 정책 추론 실행하거나 `lerobot-eval` 사용

## 7. 검증 판단
- 빨강 명령 → 빨강만 왼쪽, 파랑 명령 → 파랑만 오른쪽이면 **파이프라인 성공** → 스태킹 데이터 수집(별도 `so101_stacking`)으로 진행
- 색을 헷갈리면 → 데이터 보강(색당 50+), 위치 랜덤화 점검, 카메라 각도 재검토

---

### 메모
- 데이터셋 포맷 v3.0 — 노트북(구버전)·GPU(최신) 양쪽 호환 확인됨
- 스태킹은 이 데이터셋에 섞지 말 것 (별도 데이터셋 유지)
- 노트북은 절대 `git pull` 금지 (커스텀 record.py 충돌). GPU만 최신.
