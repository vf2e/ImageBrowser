# 模型权重目录

将 EAT 官方权重放入此目录：

| 文件 | 必填 | 说明 |
|------|------|------|
| `*.pth`（除 pretrain.pth） | 是 | AVA 微调 checkpoint，**无需重命名** |
| `pretrain.pth` | 否 | 预训练权重 `dat_base_in1k_224.pth` |

程序会自动识别本目录下第一个非 `pretrain.pth` 的 `.pth` 文件，例如：

```
AVA_AOT_vacc_0.8259_srcc_0.7596_vlcc_0.7710.pth
```

安装命令：`scripts\setup_aesthetics.bat`
