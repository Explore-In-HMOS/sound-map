import { MusicModel } from '../model/MusicModel';

export class MusicData {
  public static readonly MUSIC_LIST: MusicModel[] = [
    {
      id: 1,
      title: 'ankara',
      artist: 'ankara_artist',
      artwork: $r('app.media.ic_dream_it'),
      src: 'ankara.mp3'
    },
    {
      id: 2,
      title: 'izmir',
      artist: 'izmir_artist',
      artwork: $r('app.media.ic_world'),
      src: 'izmir.mp3'
    },
    {
      id: 3,
      title: 'istanbul',
      artist: 'istanbul_artist',
      artwork: $r('app.media.ic_power'),
      src: 'istanbul.mp3'
    },
    {
      id: 4,
      title: 'default',
      artist: 'default_artist',
      artwork: $r('app.media.ic_boisterous'),
      src: 'default.mp3'
    }
  ];
}