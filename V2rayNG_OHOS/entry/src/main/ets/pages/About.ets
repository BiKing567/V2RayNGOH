import router from '@ohos.router';
import { getVersion } from '../natives/V2rayCore';

@Entry
@Component
struct About {
  @State appVersion: string = '2.2.3';
  @State coreVersion: string = '未知';
  @State buildInfo: string = '2025.06.07';

  aboutToAppear(): void {
    try {
      this.coreVersion = getVersion();
    } catch {
      this.coreVersion = '未加载';
    }
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('关于')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      Column() {
        Image($r('app.media.app_icon'))
          .width(80)
          .height(80)
          .borderRadius(16)
          .margin({ top: 32 })

        Text('V2RayNG for HarmonyOS')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 16 })

        Text('版本: ' + this.appVersion)
          .fontSize(15)
          .fontColor('#666666')
          .margin({ top: 8 })

        Text('V2Ray 核心: ' + this.coreVersion)
          .fontSize(15)
          .fontColor('#666666')
          .margin({ top: 4 })

        Text('构建: ' + this.buildInfo)
          .fontSize(13)
          .fontColor('#888888')
          .margin({ top: 4 })

        Divider()
          .width('80%')
          .margin({ top: 24 })

        Text('适用于 Android 的 V2Ray/Xray 客户端，现已移植到 HarmonyOS')
          .fontSize(13)
          .fontColor('#888888')
          .textAlign(TextAlign.Center)
          .margin({ top: 16 })
          .padding({ left: 32, right: 32 })

        Text('基于 2dust/v2rayNG')
          .fontSize(13)
          .fontColor('#888888')
          .margin({ top: 8 })

        Text('许可证: GPL v3')
          .fontSize(13)
          .fontColor('#888888')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
