import router from '@ohos.router';
import * as Logger from '../utils/Logger';

@Entry
@Component
struct Backup {
  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('备份与恢复')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      Column() {
        Column() {
          Image($r('app.media.ic_backup'))
            .width(48)
            .height(48)
            .margin({ top: 24 })
          Text('备份')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 8 })
          Text('导出所有配置和设置')
            .fontSize(13)
            .fontColor('#888888')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .margin({ bottom: 12 })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          Logger.i('Backup - to be implemented with file save');
        })

        Column() {
          Image($r('app.media.ic_restore'))
            .width(48)
            .height(48)
            .margin({ top: 24 })
          Text('恢复')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 8 })
          Text('从备份文件导入配置')
            .fontSize(13)
            .fontColor('#888888')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          Logger.i('Restore - to be implemented with file picker');
        })
      }
      .width('100%')
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
