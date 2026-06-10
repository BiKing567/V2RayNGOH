import router from '@ohos.router';
import * as Logger from '../utils/Logger';

@Entry
@Component
struct Logcat {
  @State logLines: string[] = [];
  @State autoScroll: boolean = true;
  private refreshId: number = 0;

  aboutToAppear(): void {
    this.refreshLogs();
    this.refreshId = setInterval(() => this.refreshLogs(), 1000) as number;
  }

  aboutToDisappear(): void {
    if (this.refreshId) {
      clearInterval(this.refreshId);
    }
  }

  refreshLogs(): void {
    this.logLines = Logger.getLogBuffer();
  }

  clearLogs(): void {
    this.logLines = [];
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
        Text('日志')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Button('清空')
          .fontSize(14)
          .fontColor('#F44336')
          .type(ButtonType.Normal)
          .onClick(() => this.clearLogs())
        Toggle({ type: ToggleType.Switch, isOn: this.autoScroll })
          .margin({ left: 8 })
        Text('自动滚动')
          .fontSize(12)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      TextArea({ text: this.logLines.join('\n') })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#1A1A2E')
        .fontColor('#00FF00')
        .fontSize(11)
        .fontFamily('monospace')
        .padding(8)
        .borderRadius(0)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
