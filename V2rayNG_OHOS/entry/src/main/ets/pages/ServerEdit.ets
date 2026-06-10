import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ProfileItem } from '../model/ProfileItem';
import { EConfigType, configTypeFromInt } from '../model/Enums';
import { parseShareLink } from '../utils/SubscriptionUpdater';
import * as Storage from '../utils/Storage';
import * as Logger from '../utils/Logger';

@Entry
@Component
struct ServerEdit {
  @State guid: string = '';
  @State configType: number = EConfigType.VMESS;
  @State remarks: string = '';
  @State server: string = '';
  @State serverPort: string = '443';
  @State password: string = '';
  @State method: string = 'aes-256-gcm';
  @State flow: string = '';
  @State username: string = '';
  @State network: string = 'tcp';
  @State security: string = 'none';
  @State sni: string = '';
  @State host: string = '';
  @State path: string = '';
  @State headerType: string = 'none';
  @State alpn: string = '';
  @State fingerPrint: string = '';
  @State importUrl: string = '';
  @State isNew: boolean = true;

  importFromLink(): void {
    if (!this.importUrl) {
      promptAction.showToast({ message: '请输入链接', duration: 1500 });
      return;
    }
    const profile = parseShareLink(this.importUrl.trim());
    if (!profile) {
      promptAction.showToast({ message: '无法解析该链接', duration: 2000 });
      return;
    }
    this.configType = profile.configType;
    this.remarks = profile.remarks;
    this.server = profile.server || '';
    this.serverPort = profile.serverPort || '443';
    this.password = profile.password || '';
    this.method = profile.method || 'aes-256-gcm';
    this.flow = profile.flow || '';
    this.username = profile.username || '';
    this.network = profile.network || 'tcp';
    this.security = profile.security || 'none';
    this.sni = profile.sni || '';
    this.host = profile.host || '';
    this.path = profile.path || '';
    this.headerType = profile.headerType || 'none';
    this.alpn = profile.alpn || '';
    this.fingerPrint = profile.fingerPrint || '';
    promptAction.showToast({ message: '解析成功: ' + profile.remarks, duration: 2000 });
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params && params['guid']) {
      this.guid = params['guid'];
      this.isNew = false;
      this.loadServer();
    } else {
      this.guid = this.generateGuid();
    }
  }

  generateGuid(): string {
    return 'guid_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8);
  }

  async loadServer(): Promise<void> {
    const profile = await Storage.loadServer(this.guid);
    if (profile) {
      this.configType = profile.configType;
      this.remarks = profile.remarks;
      this.server = profile.server || '';
      this.serverPort = profile.serverPort || '443';
      this.password = profile.password || '';
      this.method = profile.method || 'aes-256-gcm';
      this.flow = profile.flow || '';
      this.username = profile.username || '';
      this.network = profile.network || 'tcp';
      this.security = profile.security || 'none';
      this.sni = profile.sni || '';
      this.host = profile.host || '';
      this.path = profile.path || '';
      this.headerType = profile.headerType || 'none';
      this.alpn = profile.alpn || '';
      this.fingerPrint = profile.fingerPrint || '';
    }
  }

  async saveServer(): Promise<void> {
    const profile = new ProfileItem(configTypeFromInt(this.configType));
    profile.remarks = this.remarks;
    profile.server = this.server;
    profile.serverPort = this.serverPort;
    profile.password = this.password;
    profile.method = this.method;
    profile.flow = this.flow;
    profile.username = this.username;
    profile.network = this.network;
    profile.security = this.security;
    profile.sni = this.sni;
    profile.host = this.host;
    profile.path = this.path;
    profile.headerType = this.headerType;
    profile.alpn = this.alpn;
    profile.fingerPrint = this.fingerPrint;

    await Storage.saveServer(this.guid, profile);
    Logger.i('Server saved: ' + this.guid);
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
        Text(this.isNew ? '添加服务器' : '编辑服务器')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
        Blank()
        Button('保存')
          .fontSize(15)
          .fontColor('#4CAF50')
          .type(ButtonType.Normal)
          .onClick(() => this.saveServer())
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      Scroll() {
        Column() {
          // Import from share link
          Column() {
            Text('从链接导入')
              .fontSize(14)
              .fontColor('#888888')
              .width('100%')
              .margin({ bottom: 4 })
            Row() {
              TextInput({ placeholder: 'vmess:// / vless:// / ss:// / trojan:// ...', text: this.importUrl })
                .layoutWeight(1)
                .height(36)
                .onChange((val) => { this.importUrl = val; })
              Button('解析')
                .fontSize(14)
                .height(36)
                .fontColor('#4CAF50')
                .type(ButtonType.Normal)
                .margin({ left: 8 })
                .onClick(() => this.importFromLink())
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 1 })

          // Type
          Row() {
            Text('类型')
              .fontSize(15)
            Select([
              { value: 'VMess' }, { value: 'VLESS' }, { value: 'Shadowsocks' },
              { value: 'Trojan' }, { value: 'SOCKS' }, { value: 'HTTP' },
              { value: 'WireGuard' }, { value: 'Hysteria2' }, { value: 'Custom' },
            ])
              .value(EConfigType[this.configType] || 'VMESS')
              .onSelect((idx) => {
                this.configType = idx + 1;
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          // Remarks
          Row() {
            Text('备注')
              .fontSize(15)
            TextInput({ placeholder: '我的服务器', text: this.remarks })
              .layoutWeight(1)
              .height(36)
              .margin({ left: 8 })
              .onChange((val) => { this.remarks = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          // Address
          Row() {
            Text('地址')
              .fontSize(15)
            TextInput({ placeholder: 'example.com', text: this.server })
              .layoutWeight(1)
              .height(36)
              .margin({ left: 8 })
              .onChange((val) => { this.server = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          // Port
          Row() {
            Text('端口')
              .fontSize(15)
            TextInput({ placeholder: '443', text: this.serverPort })
              .width(100)
              .height(36)
              .margin({ left: 8 })
              .onChange((val) => { this.serverPort = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          // Password / UUID
          if (this.configType !== EConfigType.SOCKS && this.configType !== EConfigType.HTTP) {
            Row() {
              Text(this.configType === EConfigType.VMESS || this.configType === EConfigType.VLESS ? 'UUID' : 'Password')
                .fontSize(15)
              TextInput({ placeholder: '', text: this.password })
                .layoutWeight(1)
                .height(36)
                .margin({ left: 8 })
                .type(InputType.Password)
                .onChange((val) => { this.password = val; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 1 })
          }

          // Encryption method (Shadowsocks)
          if (this.configType === EConfigType.SHADOWSOCKS) {
            Row() {
              Text('加密方式')
                .fontSize(15)
              TextInput({ placeholder: 'aes-256-gcm', text: this.method })
                .width(150)
                .height(36)
                .margin({ left: 8 })
                .onChange((val) => { this.method = val; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 1 })
          }

          // VLESS Flow
          if (this.configType === EConfigType.VLESS) {
            Row() {
              Text('流控')
                .fontSize(15)
              TextInput({ placeholder: '', text: this.flow })
                .layoutWeight(1)
                .height(36)
                .margin({ left: 8 })
                .onChange((val) => { this.flow = val; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 1 })
          }

          // Transport
          Text('传输')
            .fontSize(14)
            .fontColor('#888888')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 4 })

          Row() {
            Text('网络')
              .fontSize(15)
            Select([
              { value: 'tcp' }, { value: 'kcp' }, { value: 'ws' },
              { value: 'grpc' }, { value: 'h2' }, { value: 'httpupgrade' },
              { value: 'xhttp' },
            ])
              .value(this.network)
              .onSelect((_, val) => { this.network = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          // Host (WS, HTTP)
          if (this.network === 'ws' || this.network === 'h2' || this.network === 'httpupgrade') {
            Row() {
              Text('主机')
                .fontSize(15)
              TextInput({ placeholder: '', text: this.host })
                .layoutWeight(1)
                .height(36)
                .margin({ left: 8 })
                .onChange((val) => { this.host = val; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 1 })

            Row() {
              Text('路径')
                .fontSize(15)
              TextInput({ placeholder: '/', text: this.path })
                .layoutWeight(1)
                .height(36)
                .margin({ left: 8 })
                .onChange((val) => { this.path = val; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 1 })
          }

          // Security
          Row() {
            Text('安全')
              .fontSize(15)
            Select([
              { value: 'none' }, { value: 'tls' }, { value: 'reality' },
            ])
              .value(this.security)
              .onSelect((_, val) => { this.security = val; })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          if (this.security !== 'none') {
            Row() {
              Text('SNI')
                .fontSize(15)
              TextInput({ placeholder: this.server || '', text: this.sni })
                .layoutWeight(1)
                .height(36)
                .margin({ left: 8 })
                .onChange((val) => { this.sni = val; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 1 })

            Row() {
              Text('ALPN')
                .fontSize(15)
              TextInput({ placeholder: 'h2,http/1.1', text: this.alpn })
                .layoutWeight(1)
                .height(36)
                .margin({ left: 8 })
                .onChange((val) => { this.alpn = val; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 1 })

            Row() {
              Text('指纹')
                .fontSize(15)
              TextInput({ placeholder: 'chrome', text: this.fingerPrint })
                .layoutWeight(1)
                .height(36)
                .margin({ left: 8 })
                .onChange((val) => { this.fingerPrint = val; })
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .margin({ top: 1 })
          }
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
