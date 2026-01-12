import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MediaController } from '../audio/MediaController';
import { MusicModel } from '../common/model/MusicModel';
import { getCityMusic } from '../common/constants/CityMusicLocal';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CustomAudioManager } from '../audio/CustomAudioManager';

const cityToPlate: Record<string, number> = {
  'istanbul': 34,
  'ankara': 6,
  'izmir': 35,
  'bursa': 16,
  'antalya': 7,
  'samsun': 55
};

const CITY_MARKERS: mapCommon.MarkerOptions[] = [
  {
    position: { latitude: 41.0082, longitude: 28.9784 },
    title: 'istanbul',
    clickable: true,
    anchorU: 0.5,
    anchorV: 1,
    alpha: 1
  },
  {
    position: { latitude: 39.9208, longitude: 32.8541 },
    title: 'ankara',
    clickable: true,
    anchorU: 0.5,
    anchorV: 1,
    alpha: 1
  },
  {
    position: { latitude: 38.4237, longitude: 27.1428 },
    title: 'izmir',
    clickable: true,
    anchorU: 0.5,
    anchorV: 1,
    alpha: 1
  }
];

@Extend(Image)
function controlImageStyle() {
  .aspectRatio(1)
  .objectFit(ImageFit.Contain)
}

@Component
export struct MapMusicPage {
  @StorageLink('selectIndex') selectIndex: number = 0;
  @StorageLink('musicList') musicList: MusicModel[] = [];
  @StorageLink('currentTime') currentTime: string = '00:00';
  @StorageLink('isPlay') isPlay: boolean = false;
  @StorageLink('progress') value: number = 0;
  @StorageLink('progressMax') max: number = 0;

  async aboutToAppear() {
    await CustomAudioManager.getInstance().initAudioVolumeGroupManager()
  }

  private mapController?: map.MapComponentController;

  private async playByCityName(cityName: string): Promise<void> {
    const plate: number = cityToPlate[cityName] ?? 0;
    const track: MusicModel = getCityMusic(plate);
    AppStorage.setOrCreate('musicList', [track]);
    AppStorage.setOrCreate('selectIndex', 0);
    await MediaController.getInstance().startByIndex(0);
  }

  @Builder
  private InfoWindowUI(md: map.MarkerDelegate) {
    Column() {
      Text(md.marker!.getTitle().length > 0 ? `${md.marker?.getTitle()} • Çalınıyor...` : 'Seçildi')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .padding(6)
        .backgroundColor('#AA000000')
        .borderRadius(8)
    }
    .onClick(() => {
      void this.playByCityName(md.marker!.getTitle()); // müziği tetikle
    })
    .onAppear(() => {
      void this.playByCityName(md.marker!.getTitle()); // müziği tetikle
    })
  }

  build() {

    Column() {
      MapComponent({
        mapOptions: {
          position: { target: { latitude: 39.0, longitude: 35.0 }, zoom: 5 } // Türkiye merkez
        },
        mapCallback: (err: BusinessError | undefined, ctrl: map.MapComponentController): void => {
          if (err) {
            hilog.error(0, 'testt', `Map init error: code=${err.code}, msg=${err.message}`)
            return;
          }
          this.mapController = ctrl;

          for (const m of CITY_MARKERS) {
            ctrl.addMarker(m);
          }
        },
        customInfoWindow: (md: map.MarkerDelegate) => {
          this.InfoWindowUI(md);
        }

      })
        .width('100%')
        .height('60%')

      Column() {
          Column() {
            Text(this.musicList.length ? this.musicList[this.selectIndex].title : '—')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.currentTime)
              .fontSize(11)
              .fontColor('#ffff71ab')
          }
          .margin({ left: 8 })

        Row() {
          Image($r('app.media.ic_prev'))
            .controlImageStyle()
            .width(24)
            .onClick((): void => {
              MediaController.getInstance().playPrevious();
            })

          Image(this.isPlay ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .controlImageStyle()
            .width(24)
            .onClick((): void => {
              const mc: MediaController = MediaController.getInstance();
              if (this.isPlay) {
                mc.pause();
              } else {
                mc.getFirst() ? mc.startByIndex() : mc.resume();
              }
            })

          Image($r('app.media.ic_next'))
            .controlImageStyle()
            .width(24)
            .onClick((): void => {
              MediaController.getInstance().playNext();
            })
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
        .margin({ top: 6 })
      }
      .width('100%')
      .height('30%')
      .padding(0)
      .backgroundColor('#1A000000')
      .borderRadius(16)
      .shadow({
        radius: 12,
        color: '#66000000',
        offsetX: 0,
        offsetY: 2
      })
    }
    .width('100%')
    .height('100%')
  }
}
