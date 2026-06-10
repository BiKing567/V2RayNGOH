import router from '@ohos.router';

@Entry
@Component
struct PerAppProxy {
  @State bypassMode: boolean = true;
  @State appList: string[] = [];
  @State selectedApps: string[] = [];

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('应用代理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      Row() {
        Text('绕过模式')
          .fontSize(15)
        Toggle({ type: ToggleType.Switch, isOn: this.bypassMode })
          .onChange((val) => { this.bypassMode = val; })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceBetween)

      Text(this.bypassMode ? '所选应用将绕过代理'
        : '仅所选应用使用代理')
        .fontSize(13)
        .fontColor('#888888')
        .padding({ left: 16, top: 8 })

      List() {
        ForEach(this.appList, (app: string) => {
          ListItem() {
            Row() {
              Text(app)
                .fontSize(15)
              Checkbox()
                .onChange((val) => {
                  if (val) this.selectedApps.push(app);
                  else this.selectedApps = this.selectedApps.filter(a => a !== app);
                })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .justifyContent(FlexAlign.SpaceBetween)
          }
        })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
