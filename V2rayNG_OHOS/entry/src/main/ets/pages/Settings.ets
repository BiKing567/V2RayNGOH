import router from '@ohos.router';
import * as Storage from '../utils/Storage';

@Entry
@Component
struct Settings {
  @State socksPort: string = '10808';
  @State localDnsPort: string = '10853';
  @State vpnMtu: string = '1500';
  @State ipv6Enabled: boolean = false;
  @State delayTestUrl: string = 'https://www.gstatic.com/generate_204';
  @State logLevel: string = 'warning';
  @State proxySharing: boolean = false;
  @State perAppProxy: boolean = false;
  @State connectionMode: string = 'vpn';

  aboutToAppear(): void {
    this.loadSettings();
  }

  async loadSettings(): Promise<void> {
    this.socksPort = (await Storage.getSetting('socks_port')) || '10808';
    this.localDnsPort = (await Storage.getSetting('local_dns_port')) || '10853';
    this.vpnMtu = (await Storage.getSetting('vpn_mtu')) || '1500';
    this.ipv6Enabled = (await Storage.getSettingBool('ipv6_enabled')) || false;
    this.delayTestUrl = (await Storage.getSetting('delay_test_url')) || 'https://www.gstatic.com/generate_204';
    this.logLevel = (await Storage.getSetting('core_loglevel')) || 'warning';
    this.proxySharing = (await Storage.getSettingBool('proxy_sharing_enabled')) || false;
    this.perAppProxy = (await Storage.getSettingBool('per_app_proxy')) || false;
    this.connectionMode = (await Storage.getSetting('connection_mode')) || 'vpn';
  }

  async saveSetting(key: string, value: string): Promise<void> {
    await Storage.setSetting(key, value);
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
        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 12 })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      Scroll() {
        Column() {
          // Network section
          Text('网络')
            .fontSize(14)
            .fontColor('#888888')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 4 })

          Row() {
            Text('SOCKS 端口')
              .fontSize(15)
            TextInput({ placeholder: '10808', text: this.socksPort })
              .width(100)
              .height(36)
              .onChange((val) => {
                this.socksPort = val;
                this.saveSetting('socks_port', val);
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          Row() {
            Text('本地 DNS 端口')
              .fontSize(15)
            TextInput({ placeholder: '10853', text: this.localDnsPort })
              .width(100)
              .height(36)
              .onChange((val) => {
                this.localDnsPort = val;
                this.saveSetting('local_dns_port', val);
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          Row() {
            Text('VPN MTU')
              .fontSize(15)
            TextInput({ placeholder: '1500', text: this.vpnMtu })
              .width(100)
              .height(36)
              .onChange((val) => {
                this.vpnMtu = val;
                this.saveSetting('vpn_mtu', val);
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          // Features section
          Text('功能')
            .fontSize(14)
            .fontColor('#888888')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 4 })

          Row() {
            Text('连接模式')
              .fontSize(15)
            Select([{ value: 'VPN' }, { value: 'PROXY' }])
              .value(this.connectionMode === 'vpn' ? 'VPN' : 'PROXY')
              .onSelect((idx, val) => {
                this.connectionMode = val === 'VPN' ? 'vpn' : 'proxy';
                this.saveSetting('connection_mode', this.connectionMode);
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })

          Row() {
            Text('IPv6 支持')
              .fontSize(15)
            Toggle({ type: ToggleType.Switch, isOn: this.ipv6Enabled })
              .onChange((val) => {
                this.ipv6Enabled = val;
                this.saveSetting('ipv6_enabled', String(val));
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            Text('代理共享')
              .fontSize(15)
            Toggle({ type: ToggleType.Switch, isOn: this.proxySharing })
              .onChange((val) => {
                this.proxySharing = val;
                this.saveSetting('proxy_sharing_enabled', String(val));
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            Text('应用代理')
              .fontSize(15)
            Toggle({ type: ToggleType.Switch, isOn: this.perAppProxy })
              .onChange((val) => {
                this.perAppProxy = val;
                this.saveSetting('per_app_proxy', String(val));
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .margin({ top: 1 })
          .justifyContent(FlexAlign.SpaceBetween)

          // Test section
          Text('测试')
            .fontSize(14)
            .fontColor('#888888')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 4 })

          Row() {
            Text('延迟测试 URL')
              .fontSize(15)
            TextInput({ placeholder: 'URL', text: this.delayTestUrl })
              .layoutWeight(1)
              .height(36)
              .margin({ left: 8 })
              .onChange((val) => {
                this.delayTestUrl = val;
                this.saveSetting('delay_test_url', val);
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')

          // Debug section
          Text('调试')
            .fontSize(14)
            .fontColor('#888888')
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 4 })

          Row() {
            Text('日志级别')
              .fontSize(15)
            Select([{ value: 'debug' }, { value: 'info' }, { value: 'warning' }, { value: 'error' }, { value: 'none' }])
              .value(this.logLevel)
              .onSelect((idx, val) => {
                this.logLevel = val;
                this.saveSetting('core_loglevel', val);
              })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('#FFFFFF')
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
