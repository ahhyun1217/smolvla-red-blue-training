#!/usr/bin/env bash
# 수집 끝난 데이터셋을 HuggingFace Hub에 한 번에 업로드
# (collect.sh는 push_to_hub=false라 로컬에만 쌓임 → 다 모으고 이걸로 한 방에 푸시)
#
# 사용법:
#   hf auth login        # 처음 1회 (토큰 입력)
#   export HF_USER=<your_hf_username>
#   export DATASET=<repo이름>   # 선택: 기본 so101_red_blue_cube_sorting
#   bash push_dataset.sh
set -euo pipefail

: "${HF_USER:?먼저 실행하세요:  export HF_USER=<your_hf_username>}"
DATASET="${DATASET:-so101_red_blue_cube_sorting}"
REPO_ID="$HF_USER/$DATASET"

python - <<PY
from lerobot.datasets.lerobot_dataset import LeRobotDataset
ds = LeRobotDataset("${REPO_ID}")
print(f"업로드: {ds.repo_id}  (총 {ds.meta.total_episodes} 에피소드)")
ds.push_to_hub(tags=["so101", "waste-sorting", "stacking", "smolvla"])
print("완료 → https://huggingface.co/datasets/${REPO_ID}")
PY
