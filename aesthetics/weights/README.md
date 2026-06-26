# 模型权重目录

将 EAT 官方权重放入此目录：

| 文件 | 必填 | 来源 |
|------|------|------|
| `finetune.pth` | 是 | [EAT 仓库](https://github.com/woshidandan/Image-Aesthetics-and-Quality-Assessment) Google Drive 中的 AVA checkpoint |
| `pretrain.pth` | 否 | 百度网盘 `dat_base_in1k_224.pth`（提取码 8888） |

下载后若文件名不同，请重命名为 `finetune.pth`。

安装命令：`scripts\setup_aesthetics.bat`
