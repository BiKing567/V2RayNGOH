import router from '@ohos.router';

@Entry
@Component
struct RoutingEdit {
  @State domainStrategy: string = 'AsIs';
  @State domains: string = '';
  @State ips: string = '';
  @State outboundTag: string = 'proxy';
  @State remark: string = '';

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('编辑规则')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Button('保存')
          .fontSize(15)
          .fontColor('#4CAF50')
          .type(ButtonType.Normal)
          .onClick(() => router.back())
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      Scroll() {
        Column() {
          Row() {
            Text('备注')
              .fontSize(15)
            TextInput({ placeholder: '我的规则', text: this.remark })
              .layoutWeight(1)
              .height(36)
              .margin({ left: 8 })
              .onChange((val) => { this.remark = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Row() {
            Text('出站')
              .fontSize(15)
            Select([
              { value: 'proxy' },
              { value: 'direct' },
              { value: 'block' },
            ])
              .value(this.outboundTag)
              .onSelect((_, val) => { this.outboundTag = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          Text('域名（每行一个）')
            .fontSize(14)
            .fontColor('#888888')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 4 })

          TextArea({ placeholder: 'domain:example.com\ngeosite:google\nregex:.*\\.cn', text: this.domains })
            .width('100%')
            .height(120)
            .padding(12)
            .backgroundColor('#FFFFFF')
            .onChange((val) => { this.domains = val; })

          Text('IP 地址（每行一个）')
            .fontSize(14)
            .fontColor('#888888')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 4 })

          TextArea({ placeholder: 'geoip:cn\n1.1.1.1\n10.0.0.0/8', text: this.ips })
            .width('100%')
            .height(120)
            .padding(12)
            .backgroundColor('#FFFFFF')
            .onChange((val) => { this.ips = val; })
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
