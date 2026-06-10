import router from '@ohos.router';
import { SubscriptionItem } from '../model/SubscriptionItem';
import * as Storage from '../utils/Storage';

@Entry
@Component
struct SubscriptionEdit {
  @State subId: string = '';
  @State url: string = '';
  @State remarks: string = '';
  @State autoUpdate: boolean = false;
  @State updateInterval: number = 24;
  @State isNew: boolean = true;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params && params['subId']) {
      this.subId = params['subId'];
      this.isNew = false;
      this.loadSubscription();
    }
  }

  async loadSubscription(): Promise<void> {
    const list = await Storage.loadSubscriptionList();
    const sub = list.find(s => s.id === this.subId);
    if (sub) {
      this.url = sub.url;
      this.remarks = sub.remarks;
      this.autoUpdate = sub.autoUpdate;
      this.updateInterval = sub.updateInterval;
    }
  }

  async save(): Promise<void> {
    const list = await Storage.loadSubscriptionList();
    if (this.isNew) {
      const sub = new SubscriptionItem();
      sub.id = 'sub_' + Date.now();
      sub.url = this.url;
      sub.remarks = this.remarks;
      sub.autoUpdate = this.autoUpdate;
      sub.updateInterval = this.updateInterval;
      list.push(sub);
    } else {
      const sub = list.find(s => s.id === this.subId);
      if (sub) {
        sub.url = this.url;
        sub.remarks = this.remarks;
        sub.autoUpdate = this.autoUpdate;
        sub.updateInterval = this.updateInterval;
      }
    }
    await Storage.saveSubscriptionList(list);
    router.back();
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
        Text(this.isNew ? '添加订阅' : '编辑订阅')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Button('保存')
          .fontSize(15)
          .fontColor('#4CAF50')
          .type(ButtonType.Normal)
          .onClick(() => this.save())
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      Scroll() {
        Column() {
          Row() {
            Text('URL')
              .fontSize(15)
            TextInput({ placeholder: 'https://example.com/sub', text: this.url })
              .layoutWeight(1)
              .height(36)
              .margin({ left: 8 })
              .onChange((val) => { this.url = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Row() {
            Text('备注')
              .fontSize(15)
            TextInput({ placeholder: '我的订阅', text: this.remarks })
              .layoutWeight(1)
              .height(36)
              .margin({ left: 8 })
              .onChange((val) => { this.remarks = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          Row() {
            Text('自动更新')
              .fontSize(15)
            Toggle({ type: ToggleType.Switch, isOn: this.autoUpdate })
              .onChange((val) => { this.autoUpdate = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })
          .justifyContent(FlexAlign.SpaceBetween)
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
