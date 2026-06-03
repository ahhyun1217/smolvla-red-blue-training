# SmolVLA SO101 Red/Blue Cube Sorting

SO101 로봇팔로 빨강/파랑 큐브를 색에 따라 분류하는 SmolVLA 정책 학습 실험.

## 데이터셋
- HF: [AmberHyunKIM/so101_red_blue_cube_sorting](https://huggingface.co/datasets/AmberHyunKIM/so101_red_blue_cube_sorting)
- 80 에피소드 / 43,878 프레임
- 카메라: front, side

## 학습된 모델
- HF: [AmberHyunKIM/smolvla_red_blue_cube_sorting](https://huggingface.co/AmberHyunKIM/smolvla_red_blue_cube_sorting)
- 정책: SmolVLA base (frozen vision encoder)
- 학습: 20,000 steps / batch 32 / RTX 5070 Ti

## Loss 수렴
| step | loss |
|------|------|
| 200 | 1.676 |
| 1,000 | 0.365 |
| 5,000 | 0.199 |
| 10,000 | 0.102 |
| 20,000 | 0.055 |

## 학습 재현
```bash
conda activate lerobot
lerobot-train --config_path train_smolvla_red_blue.yaml
```
