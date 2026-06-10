import router from '@ohos.router';

@Entry
@Component
struct Routing {
  @State routingRules: RoutingRule[] = [];
  @State domainStrategy: string = 'AsIs';

  aboutToAppear(): void {
    this.loadRules();
  }

  loadRules(): void {
    // Load from storage - placeholder
    this.routingRules = [];
  }

  addRule(): void {
    router.pushUrl({ url: 'pages/RoutingEdit', params: { ruleId: '' } });
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
        Text('路由规则')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Button('+')
          .fontSize(24)
          .fontColor('#4CAF50')
          .type(ButtonType.Normal)
          .onClick(() => this.addRule())
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      Row() {
        Text('域名策略')
          .fontSize(15)
        Select([
          { value: 'AsIs' },
          { value: 'IPIfNonMatch' },
          { value: 'IPOnDemand' },
        ])
          .value(this.domainStrategy)
          .onSelect((_, val) => { this.domainStrategy = val; })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')

      if (this.routingRules.length === 0) {
        Column() {
          Text('没有配置路由规则')
            .fontSize(15)
            .fontColor('#999999')
          Text('所有流量将通过代理出站')
            .fontSize(13)
            .fontColor('#BBBBBB')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      List() {
        ForEach(this.routingRules, (rule: RoutingRule) => {
          ListItem() {
            // Rule card placeholder
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

interface RoutingRule {
  id: string;
  remarks: string;
  domain?: string[];
  ip?: string[];
  outboundTag: string;
}
