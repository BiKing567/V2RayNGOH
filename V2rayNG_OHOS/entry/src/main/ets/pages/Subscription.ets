import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { SubscriptionItem } from '../model/SubscriptionItem';
import { fetchSubscription } from '../utils/SubscriptionUpdater';
import * as Storage from '../utils/Storage';
import * as Logger from '../utils/Logger';

@Entry
@Component
struct Subscription {
  @State subList: SubscriptionItem[] = [];
  @State isLoading: boolean = false;

  onPageShow(): void {
    this.loadSubscriptions();
  }

  async loadSubscriptions(): Promise<void> {
    this.subList = await Storage.loadSubscriptionList();
  }

  async addSubscription(): Promise<void> {
    router.pushUrl({ url: 'pages/SubscriptionEdit', params: {} });
  }

  async updateSubscription(sub: SubscriptionItem): Promise<void> {
    try {
      const profiles = await fetchSubscription(sub);
      Logger.i('Fetched ' + profiles.length + ' profiles from ' + sub.remarks);
      for (const profile of profiles) {
        const guid = 'sub_' + sub.id + '_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8);
        profile.subscriptionId = sub.id;
        await Storage.saveServer(guid, profile);
      }
      sub.lastUpdateTime = Date.now();
      await Storage.saveSubscriptionList(this.subList);
      const toast = profiles.length > 0
        ? '更新成功 ' + profiles.length + ' 个节点'
        : '更新成功，但未解析到任何节点，请检查日志';
      promptAction.showToast({ message: toast, duration: 3000 });
    } catch (err) {
      Logger.e('Update failed: ' + JSON.stringify(err));
      promptAction.showToast({ message: '更新失败: ' + JSON.stringify(err), duration: 3000 });
    }
  }

  async updateAll(): Promise<void> {
    this.isLoading = true;
    try {
      for (const sub of this.subList) {
        if (sub.enabled) {
          await this.updateSubscription(sub);
        }
      }
    } catch (err) {
      Logger.e('UpdateAll failed: ' + JSON.stringify(err));
    } finally {
      this.isLoading = false;
    }
  }

  async deleteSub(sub: SubscriptionItem): Promise<void> {
    const idx = this.subList.indexOf(sub);
    if (idx >= 0) {
      this.subList.splice(idx, 1);
      await Storage.saveSubscriptionList(this.subList);
      this.loadSubscriptions();
    }
  }

  build() {
    Column() {
      // Title bar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('订阅管理')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Button('+')
          .fontSize(24)
          .fontColor('#4CAF50')
          .type(ButtonType.Normal)
          .onClick(() => this.addSubscription())
        Button('全部更新')
          .fontSize(13)
          .fontColor('#2196F3')
          .type(ButtonType.Normal)
          .margin({ left: 8 })
          .onClick(() => this.updateAll())
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 40 })
      }

      List() {
        ForEach(this.subList, (sub: SubscriptionItem) => {
          ListItem() {
            Column() {
              Row() {
                Column() {
                  Text(sub.remarks)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                  Text(sub.url)
                    .fontSize(12)
                    .fontColor('#888888')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  if (sub.lastUpdateTime > 0) {
                    Text('上次更新: ' + new Date(sub.lastUpdateTime).toLocaleString())
                      .fontSize(11)
                      .fontColor('#AAAAAA')
                      .margin({ top: 2 })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Button('更新')
                  .fontSize(12)
                  .height(30)
                  .type(ButtonType.Normal)
                  .fontColor('#2196F3')
                  .onClick(async () => {
                    this.isLoading = true;
                    await this.updateSubscription(sub);
                    this.isLoading = false;
                  })
              }
              .width('100%')

              Row() {
                Toggle({ type: ToggleType.Switch, isOn: sub.enabled })
                  .onChange((val) => {
                    sub.enabled = val;
                    Storage.saveSubscriptionList(this.subList);
                  })
                Text('自动更新')
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ left: 4 })
              }
              .width('100%')
              .margin({ top: 4 })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
          }
        }, (sub: SubscriptionItem) => sub.id)
      }
      .layoutWeight(1)
      .width('100%')
      .padding(8)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
