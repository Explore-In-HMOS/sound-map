// common/constants/CityMusicLocal.ts
import { MusicModel } from '../model/MusicModel';

export function getCityMusic(plate: number): MusicModel {
  const m = new MusicModel();
  m.id = plate;
  m.artist = 'Local Artist';
  m.artwork = $r('app.media.ic_dream_it'); // istersen değiştir

  switch (plate) {
    case 34:
      m.title = 'istanbul';
      m.src = 'istanbul.mp3';
      return m;
    case 6:
      m.title = 'ankara';
      m.src = 'ankara.mp3';
      return m;
    case 35:
      m.title = 'izmir';
      m.src = 'izmir.mp3';
      return m;
    default:
      m.title = 'default';
      m.src = 'default.mp3';
      return m;
  }
}
