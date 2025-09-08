import { CustomAudioManager } from '../audio/CustomAudioManager';
import { MediaController } from '../audio/MediaController';
import { MusicModel } from '../common/model/MusicModel';
import MainViewModel from '../viewmodel/MainViewModel';
import { MapMusicPage } from './MapMusicPage';

@Entry
@Component
struct Index {
  private viewModel: MainViewModel = new MainViewModel();
  @State musicData: MusicModel[] = [];

  @State message: string = 'soundMap';
  @State cumulativeDegree: number = 0;
  @State threshold: number = 10;

  aboutToAppear(): void {
    this.musicData = this.viewModel.getMusicList();
    AppStorage.setOrCreate('musicList', this.musicData);

    MediaController.getInstance();
    CustomAudioManager.getInstance()
  }

  aboutToDisappear(): void {
    MediaController.getInstance().release();
  }

  build() {
    Column() {
      MapMusicPage()
    }.width('100%')
    .height('100%')
  }
}