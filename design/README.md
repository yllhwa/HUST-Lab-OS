## 华中科技大学 网络空间安全学院 2020 级 计算机操作系统 课程设计

### 目录说明
```
.
├── src                  # 程序代码
│   ├── main.asm         # 主程序
│   └── macro.inc        # 自定义的宏
└── vm                   # bochs虚拟机配置文件
```

### 项目说明
1. 我是在`Windows`下面做的，各类操作是否支持其它系统请自行测试（Windows 下用 DiskGenius 挂载软盘）。
2. `Windows`下安装好`bochs`后，`bochsrc.bxrc`可以双击运行，也可以右键进入`DEBUG`。
3. `src`目录的`.vscode`目录定义了一些 VSCode 的代码折叠配置，请安装`zokugun.explicit-folding`插件后查看，不然简直看不下去。
4. 我使用了大量的宏定义，可读性可能不佳，见谅。

### LICENSE

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

请务必注意协议的限制