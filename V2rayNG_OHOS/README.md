# V2RayNG for HarmonyOS NEXT

V2RayNG 的 HarmonyOS NEXT 原生移植。NAPI (C++) 桥接静态链接 Go V2Ray/Xray-core。

## 架构

```
ArkUI (ArkTS) → NAPI Bridge (C++) → Go V2Ray Core (静态链接 .a)
```

## 项目结构

```
V2rayNG_OHOS/
├── AppScope/                    # 应用级配置
├── entry/
│   └── src/main/
│       ├── ets/                 # ArkUI 代码
│       │   ├── Application/     # AbilityStage
│       │   ├── MainAbility/     # UIAbility
│       │   ├── pages/           # UI 页面
│       │   ├── components/      # 可复用组件
│       │   ├── services/        # 后台服务
│       │   ├── model/           # 数据模型
│       │   ├── natives/         # NAPI 桥接接口
│       │   └── utils/           # 工具
│       ├── cpp/                 # NAPI C++ 桥接
│       └── resources/           # 多语言资源
├── v2ray_go/                    # Go V2Ray 核心源码
│   ├── main.go                  # C 导出接口
│   ├── build_ohos.sh            # 交叉编译脚本
│   └── Makefile                 # 备选构建
├── build-profile.json5
└── build_install.sh             # 完整构建安装脚本
```

## 构建

### 前置条件

- **DevEco Studio 5.0+** (HarmonyOS 6.1.1 SDK, API 24)
- **Go 1.22+**
- **HarmonyOS NDK** (随 SDK 安装)

### 编译 Go V2Ray 核心

```bash
cd v2ray_go
export OHOS_NDK_HOME=/path/to/ohos-sdk/ohos-ndk
./build_ohos.sh
```

输出: `v2ray_go/libs/<abi>/libv2ray_core.a`

### 构建 HAP

```bash
./build_install.sh
```

或用 DevEco Studio 打开项目，点击 Build > Build HAP(s)。

## License

GPL v3 (与原始 v2rayNG 保持一致)
