import { ServiceState } from '../services/CoreServiceManager';

@Component
export struct ConnectionStatus {
  @Link state: ServiceState;

  build() {
    Row() {
      if (this.state === ServiceState.RUNNING) {
        Text('●')
          .fontSize(14)
          .fontColor('#4CAF50')
        Text('已连接')
          .fontSize(13)
          .fontColor('#4CAF50')
          .margin({ left: 4 })
      } else {
        Text('○')
          .fontSize(14)
          .fontColor('#999999')
        Text('未连接')
          .fontSize(13)
          .fontColor('#999999')
          .margin({ left: 4 })
      }
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor(this.state === ServiceState.RUNNING ? '#E8F5E9' : '#F5F5F5')
    .borderRadius(12)
  }
}
