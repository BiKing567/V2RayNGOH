import router from '@ohos.router';
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import { ProfileItem } from '../model/ProfileItem';
import { EConfigType } from '../model/Enums';
import { CoreServiceManager, ServiceState, ServiceMode, ServiceCallbacks } from '../services/CoreServiceManager';
import * as Storage from '../utils/Storage';
import * as Logger from '../utils/Logger';
import { ServerCard } from '../components/ServerCard';
import { ConfigBuilder } from '../utils/ConfigBuilder';
import * as V2rayCore from '../natives/V2rayCore';

interface ServerEntry {
  guid: string;
  profile: ProfileItem;
  delay: number;
}

@Entry
@Component
struct Index {
  @State serverList: ServerEntry[] = [];
  @State selectedGuid: string = '';
  @State serviceState: ServiceState = ServiceState.NOT_RUNNING;
  @State currentServerName: string = '';
  @State uplinkSpeed: string = '0 B/s';
  @State downlinkSpeed: string = '0 B/s';
  @State isLoading: boolean = false;
  @State showMenu: boolean = false;
  @State isTesting: boolean = false;

  private callbacks: ServiceCallbacks = {
    onStateChange: (state) => {
      this.serviceState = state;
    },
    onSpeedUpdate: (uplink, downlink) => {
      this.uplinkSpeed = this.formatSpeed(uplink);
      this.downlinkSpeed = this.formatSpeed(downlink);
    },
    onDelayResult: (delay) => {
      // Update delay for current server
      const idx = this.serverList.findIndex(s => s.guid === this.selectedGuid);
      if (idx >= 0) {
        this.serverList[idx].delay = delay;
        this.serverList = [...this.serverList];
      }
    },
    onError: (msg) => {
      AlertDialog.show({ message: msg, title: '错误' });
    },
  };

  aboutToAppear(): void {
    CoreServiceManager.registerCallbacks(this.callbacks);
  }

  onPageShow(): void {
    this.loadServerList();
    this.loadSelectedServer();
  }

  aboutToDisappear(): void {
    CoreServiceManager.unregisterCallbacks();
  }

  async loadServerList(): Promise<void> {
    this.isLoading = true;
    try {
      const guids = await Storage.getAllServerGuids();
      const entries: ServerEntry[] = [];
      for (const guid of guids) {
        const profile = await Storage.loadServer(guid);
        if (profile) {
          entries.push({ guid, profile, delay: -1 });
        }
      }
      entries.sort((a, b) => a.profile.addedTime - b.profile.addedTime);
      this.serverList = entries;
    } catch (err) {
      Logger.e('Failed to load server list: ' + JSON.stringify(err));
    }
    this.isLoading = false;
  }

  async loadSelectedServer(): Promise<void> {
    const guid = await Storage.getSelectedServer();
    if (guid) {
      this.selectedGuid = guid;
      const profile = await Storage.loadServer(guid);
      if (profile) {
        this.currentServerName = profile.remarks;
      }
    }
  }

  formatSpeed(bytesPerSec: number): string {
    if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + ' B/s';
    if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + ' KB/s';
    return (bytesPerSec / (1024 * 1024)).toFixed(1) + ' MB/s';
  }

  async toggleConnection(): Promise<void> {
    if (this.serviceState === ServiceState.RUNNING) {
      CoreServiceManager.stop();
    } else {
      if (!this.selectedGuid) {
        AlertDialog.show({ message: '请先选择一个服务器', title: '提示' });
        return;
      }
      const mode = (await Storage.getSetting('connection_mode')) || 'vpn';
      if (mode === 'vpn') {
        const context = getContext(this) as common.UIAbilityContext;
        let want: Want = {
          bundleName: context.abilityInfo.bundleName,
          abilityName: 'VpnServiceAbility',
        };
        try {
          context.connectServiceExtensionAbility(want, {
            onConnect: () => {
              Logger.i('VPN service connected');
              CoreServiceManager.start(ServiceMode.VPN, this.selectedGuid);
            },
            onDisconnect: () => {
              Logger.i('VPN service disconnected');
            },
            onFailed: (code: number) => {
              Logger.e('VPN failed code=' + code + ', fallback to proxy');
              CoreServiceManager.start(ServiceMode.PROXY, this.selectedGuid);
            },
          });
        } catch (e) {
          Logger.e('connectServiceExtensionAbility threw: ' + JSON.stringify(e));
          CoreServiceManager.start(ServiceMode.PROXY, this.selectedGuid);
        }
      } else {
        Logger.i('Starting core in proxy mode');
        CoreServiceManager.start(ServiceMode.PROXY, this.selectedGuid);
      }
    }
  }

  async testAllDelays(): Promise<void> {
    if (this.isTesting) return;
    if (this.serviceState === ServiceState.RUNNING) {
      AlertDialog.show({
        message: '测试延迟将断开当前连接',
        title: '提示',
        buttons: [
          { value: '取消', action: () => {} },
          { value: '继续', action: () => this.runDelayTest() },
        ],
      });
    } else {
      this.runDelayTest();
    }
  }

  async runDelayTest(): Promise<void> {
    this.isTesting = true;
    if (this.serviceState === ServiceState.RUNNING) {
      CoreServiceManager.stop();
      await new Promise<void>(resolve => { setTimeout(resolve, 500); });
    }

    const entries = [...this.serverList];
    for (let i = 0; i < entries.length; i++) {
      entries[i].delay = -2;
    }
    this.serverList = [...entries];

    const testUrl = (await Storage.getSetting('delay_test_url')) || 'https://www.gstatic.com/generate_204';

    for (let i = 0; i < entries.length; i++) {
      try {
        const config = ConfigBuilder.buildV2RayConfig(entries[i].profile, 10808, 'proxy');
        V2rayCore.startCore(config, 0);
        await new Promise<void>(resolve => { setTimeout(resolve, 400); });
        entries[i].delay = V2rayCore.measureDelay(testUrl);
        V2rayCore.stopCore();
      } catch {
        entries[i].delay = -1;
      }
      this.serverList = [...entries];
    }
    this.isTesting = false;
  }

  onServerClick(guid: string): void {
    this.selectedGuid = guid;
    Storage.setSelectedServer(guid);
    this.loadServerList();
  }

  onServerLongPress(guid: string): void {
    AlertDialog.show({
      title: '服务器操作',
      message: '',
      buttons: [
        { value: '编辑', action: () => {
          router.pushUrl({ url: 'pages/ServerEdit', params: { guid } });
        }},
        { value: '删除', action: async () => {
          await Storage.deleteServer(guid);
          if (this.selectedGuid === guid) {
            this.selectedGuid = '';
            await Storage.setSelectedServer('');
          }
          this.loadServerList();
        }},
        { value: '取消', action: () => {} },
      ],
    });
  }

  build() {
    Stack() {
      Column() {
      // Top bar
      Row() {
        Text('☰')
          .fontSize(24)
          .fontColor('#333333')
          .width(24)
          .height(24)
          .margin({ left: 8 })
          .onClick(() => {
            this.showMenu = !this.showMenu;
          })
        Text('V2RayNG')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .margin({ left: 12 })

        if (this.serviceState === ServiceState.RUNNING) {
          Row() {
            Circle()
              .width(8)
              .height(8)
              .fill('#4CAF50')
            Text(this.currentServerName)
              .fontSize(12)
              .fontColor('#4CAF50')
              .margin({ left: 4 })
          }
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#E8F5E9')
          .borderRadius(12)
        }

        Text('⏱')
          .fontSize(22)
          .fontColor(this.isTesting ? '#CCCCCC' : '#666666')
          .width(24)
          .height(24)
          .margin({ right: 12 })
          .onClick(() => this.testAllDelays())
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .margin({ top: 40 })
      } else {
        // Server list
        List() {
          ForEach(this.serverList, (entry: ServerEntry) => {
            ListItem() {
              ServerCard({
                remarks: entry.profile.remarks,
                server: entry.profile.getServerAddressAndPort(),
                configType: EConfigType[entry.profile.configType],
                delay: entry.delay,
                isSelected: entry.guid === this.selectedGuid,
                onClickAction: () => this.onServerClick(entry.guid),
                onLongPressAction: () => this.onServerLongPress(entry.guid),
              })
            }
          }, (entry: ServerEntry) => entry.guid)
        }
        .layoutWeight(1)
        .width('100%')

        if (this.serverList.length === 0) {
          Column() {
            Text('没有配置服务器')
              .fontSize(16)
              .fontColor('#999999')
            Text('点击 + 添加服务器或导入订阅')
              .fontSize(13)
              .fontColor('#BBBBBB')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }

      // Speed indicator
      if (this.serviceState === ServiceState.RUNNING) {
        Row() {
          Text('▲ ' + this.uplinkSpeed)
            .fontSize(12)
            .fontColor('#666666')
          Text('▼ ' + this.downlinkSpeed)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        .backgroundColor('#F5F5F5')
      }

      // Bottom action bar
      Row() {
        // Add server
        Button() {
          Text('+')
            .fontSize(28)
            .fontColor('#666666')
            .width(24)
            .height(24)
        }
        .width(48)
        .height(48)
        .type(ButtonType.Circle)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 4, color: '#20000000', offsetY: 2 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/ServerEdit', params: { guid: '' } });
        })

        // Connection toggle
        Button() {
          if (this.serviceState === ServiceState.RUNNING) {
            Text('■')
              .fontSize(28)
              .fontColor('#FFFFFF')
              .width(32)
              .height(32)
          } else {
            Text('▶')
              .fontSize(28)
              .fontColor('#FFFFFF')
              .width(32)
              .height(32)
          }
        }
        .width(64)
        .height(64)
        .type(ButtonType.Circle)
        .backgroundColor(this.serviceState === ServiceState.RUNNING ? '#F44336' : '#4CAF50')
        .shadow({ radius: 6, color: this.serviceState === ServiceState.RUNNING ? '#33F44336' : '#334CAF50', offsetY: 3 })
        .margin({ left: 16 })
        .onClick(() => this.toggleConnection())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding(12)
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 4, color: '#20000000', offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')

    if (this.showMenu) {
      Column()
        .width('100%')
        .height('100%')
        .opacity(0.01)
        .backgroundColor('#000000')
        .onClick(() => this.showMenu = false)

      Column() {
        Text('订阅管理')
          .fontSize(16)
          .fontColor('#333333')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .width('100%')
          .onClick(() => {
            this.showMenu = false;
            router.pushUrl({ url: 'pages/Subscription' });
          })
        Text('路由规则')
          .fontSize(16)
          .fontColor('#333333')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .width('100%')
          .onClick(() => {
            this.showMenu = false;
            router.pushUrl({ url: 'pages/Routing' });
          })
        Text('设置')
          .fontSize(16)
          .fontColor('#333333')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .width('100%')
          .onClick(() => {
            this.showMenu = false;
            router.pushUrl({ url: 'pages/Settings' });
          })
        Text('日志')
          .fontSize(16)
          .fontColor('#333333')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .width('100%')
          .onClick(() => {
            this.showMenu = false;
            router.pushUrl({ url: 'pages/Logcat' });
          })
        Text('关于')
          .fontSize(16)
          .fontColor('#333333')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .width('100%')
          .onClick(() => {
            this.showMenu = false;
            router.pushUrl({ url: 'pages/About' });
          })
      }
      .width(180)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 8, color: '#33000000', offsetY: 4 })
      .position({ x: 8, y: 56 })
    }
  }
  .width('100%')
  .height('100%')
}
}
