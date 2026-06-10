# V2RayNG for HarmonyOS NEXT

把 Android 版 v2rayNG 搬到纯血鸿蒙上的整活项目，新手练手用，代码质量一般，欢迎喷也欢迎 PR。

## 现状

- **NAPI bridge 静态链接 Go core** ✅ 能编译通过，能跑
- **模拟器上跑不了 VPN** ❌ HarmonyOS NEXT 模拟器缺微内核网卡支持，VpnExtension 底层无法创建 TUN 设备，调了必挂
- **真机未测试** ❌ 手头没真机，不知道真机上 native lib 加载和 VPN 能不能通

所以这个项目目前是个技术验证（PoC），不是可用的 App。

## 项目结构

```
V2rayNG_OHOS/
├── AppScope/                    # 应用级配置
├── entry/
│   └── src/main/
│       ├── ets/                 # ArkUI 页面代码
│       ├── cpp/                 # NAPI C++ 桥接（napi_bridge.cpp）
│       └── resources/           # 多语言资源
├── v2ray_go/                    # Go V2Ray 核心
│   ├── main.go                  # C-archive 导出
│   └── build_ohos.sh            # 交叉编译脚本
├── build-profile.json5
└── build_install.sh             # 一键构建+安装
```

## 构建

1. 装好 DevEco Studio 5.0+（API 24 SDK、NDK）
2. Go 1.22+

```bash
# 编译 Go 核心（arm64-v8a / armeabi-v7a / x86_64）
cd v2ray_go
export OHOS_NDK_HOME=/path/to/ohos-sdk/ohos-ndk
./build_ohos.sh

# 构建 HAP 并安装到模拟器
cd ..
./build_install.sh
```

## 已知问题

- 模拟器下 `loadNativeModule` 会失败（系统强制覆盖 `compressNativeLibs` 为 true，不提取 .so），实测 `napi_bridge.so` 打包进了 HAP 但运行时找不到
- 即使 .so 加载调通，VPN 功能在模拟器上也无法工作
- 代码是边看文档边写的，ArkTS 不熟，Go cgo 也是硬蹭，欢迎指正

## 特别感谢

- [2dust/v2rayNG](https://github.com/2dust/v2rayNG) — 原始 Android 项目
- [XTLS/Xray-core](https://github.com/XTLS/Xray-core) — Go 核心

## License

GPL v3
