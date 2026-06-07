#!/bin/bash
set -e

source /home/kth/miniconda3/etc/profile.d/conda.sh
conda activate lerobot

export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

run_exp() {
    local config=$1
    local name=$2
    # 이전 빈 output 디렉터리 정리 (체크포인트 없으면 삭제)
    local outdir="outputs/train/${name}"
    if [ -d "$outdir" ] && [ -z "$(ls -A "$outdir")" ]; then
        rm -rf "$outdir"
    fi
    echo "========================================"
    echo "START: $name  ($(date))"
    echo "========================================"
    lerobot-train --config_path "$config" \
        2>&1 | tee "outputs/train/${name}_train.log"
    echo "========================================"
    echo "DONE: $name  ($(date))"
    echo "========================================"
}

# 실험 B: SmolVLA 증강 없음
run_exp configs/smolvla/red_blue_no_aug.yaml smolvla_no_aug

# 실험 C: GR00T 최소 증강 (brightness/contrast만)
run_exp configs/groot/red_blue.yaml groot_red_blue

echo "모든 실험 완료"
