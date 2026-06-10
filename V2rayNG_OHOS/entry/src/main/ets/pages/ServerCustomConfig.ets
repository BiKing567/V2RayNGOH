import router from '@ohos.router';
import { ProfileItem } from '../model/ProfileItem';
import { EConfigType, configTypeFromInt } from '../model/Enums';
import * as Storage from '../utils/Storage';
import * as Logger from '../utils/Logger';

@Entry
@Component
struct ServerCustomConfig {
  @State guid: string = '';
  @State jsonContent: string = '{\n  "inbounds": [],\n  "outbounds": []\n}';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params && params['guid']) {
      this.guid = params['guid'];
      this.loadCustomConfig();
    }
  }

  async loadCustomConfig(): Promise<void> {
    const profile = await Storage.loadServer(this.guid);
    if (profile && profile.server) {
      this.jsonContent = profile.server;
    }
  }

  async save(): Promise<void> {
    try {
      JSON.parse(this.jsonContent); // validate
      const profile = new ProfileItem(EConfigType.CUSTOM);
      profile.remarks = '自定义配置';
      profile.server = this.jsonContent;
      await Storage.saveServer(this.guid, profile);
      Logger.i('Custom config saved');
      router.back();
    } catch (err) {
      AlertDialog.show({ message: '无效 JSON: ' + (err as Error).message, title: '错误' });
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
        Text('自定义配置')
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

      TextArea({ text: this.jsonContent })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#1A1A2E')
        .fontColor('#00FF00')
        .fontSize(12)
        .fontFamily('monospace')
        .padding(8)
        .onChange((val) => { this.jsonContent = val; })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
