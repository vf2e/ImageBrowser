# 模型权重目录

将 EAT 官方权重放入此目录。**本目录下的 `.pth` 文件不会随 Git 提交**（体积约 300 MB+）。

## 必下载（美学评分）

| 项目 | 内容 |
|------|------|
| 下载 | [Google Drive — EAT 权重](https://drive.google.com/drive/folders/1UpLYGLU5omztVsIWkRPFTVKAOVe_4p3K?usp=sharing) |
| 文件名 | `AVA_AOT_vacc_0.8259_srcc_0.7596_vlcc_0.7710.pth` |
| 大小 | 约 333 MB |
| 放这里 | `aesthetics\weights\`（**无需重命名**） |

## 可选（预训练权重）

| 项目 | 内容 |
|------|------|
| 文件名 | `dat_base_in1k_224.pth`（网盘同目录，或 [百度网盘](https://pan.baidu.com/s/1kzXIp8V-QRSLOyRNMA-nUw?pwd=8888) 提取码 `8888`） |
| 放这里 | `aesthetics\weights\pretrain.pth`（**需重命名**） |

## 示例目录

```
aesthetics/weights/
├── AVA_AOT_vacc_0.8259_srcc_0.7596_vlcc_0.7710.pth   ← 必填
├── pretrain.pth                                       ← 可选
└── README.md
```

程序自动识别第一个非 `pretrain.pth` 的 `.pth` 作为 AVA 微调权重。

安装 Python 环境与 EAT 源码：`scripts\setup_aesthetics.bat`

完整说明见项目根目录 [README.md](../../README.md#2-完整下载与部署清单)。
