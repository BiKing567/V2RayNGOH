@Component
export struct ServerCard {
  @State remarks: string = '';
  @State server: string = '';
  @State configType: string = '';
  @State delay: number = -1;
  @State isSelected: boolean = false;
  private onClickAction?: () => void;
  private onLongPressAction?: () => void;

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.remarks || this.server || '未命名节点')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
          Row() {
            Text(this.server)
              .fontSize(13)
              .fontColor('#888888')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(this.configType)
              .fontSize(11)
              .fontColor('#666666')
              .margin({ left: 8 })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        if (this.delay === -2) {
          Text('测速中...')
            .fontSize(13)
            .fontColor('#FF9800')
            .margin({ left: 8, right: 4 })
        } else if (this.delay === -1) {
          Text('超时')
            .fontSize(13)
            .fontColor('#F44336')
            .margin({ left: 8, right: 4 })
        } else if (this.delay >= 0) {
          Text(this.delay + ' ms')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.delay < 300 ? '#4CAF50' : this.delay < 800 ? '#FF9800' : '#F44336')
            .margin({ left: 8, right: 4 })
        }

        if (this.isSelected) {
          Text('✓')
            .fontSize(22)
            .fontColor('#4CAF50')
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .backgroundColor(this.isSelected ? '#E8F5E9' : '#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 4 })
    .onClick(() => {
      if (this.onClickAction) this.onClickAction();
    })
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          if (this.onLongPressAction) this.onLongPressAction();
        })
    )
  }
}
