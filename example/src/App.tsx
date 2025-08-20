import { useEffect, useRef, useState } from 'react';
import {
  View,
  StyleSheet,
  Button,
  ScrollView,
  type EventSubscription,
} from 'react-native';
import {
  BrightcoveDownloader,
  BrightcoveView,
  Commands,
} from 'react-native-brightcove';

// const accountId = '5434391461001';
// const policyKey =
//   'BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L';
// const videoId = '6140448705001';

// const accountId = '5420904993001';
// const policyKey =
//   'BCpkADawqM1RJu5c_I13hBUAi4c8QNWO5QN2yrd_OgDjTCVsbILeGDxbYy6xhZESTFi68MiSUHzMbQbuLV3q-gvZkJFpym1qYbEwogOqKCXK622KNLPF92tX8AY9a1cVVYCgxSPN12pPAuIM';

// const playlistReferenceId = 'demo_odrm_widevine_dash';

// const videoIds = [
//   '5421538222001',
//   '5421543459001',
//   '5421546903001',
//   '5421531913001',
//   '5421538244001',
// ];

const accountId = '5434391461001';
const policyKey =
  'BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L';

const videoIds = [
  '5702141808001',
  '5702143019001',
  '5702147184001',
  '5702149062001',
  '5702143016001',
  '5702148954001',
  '1732548841120406830',
];

export default function App() {
  const [volume, setVolume] = useState<number | undefined>();
  const [fullscreen, setFullscreen] = useState<boolean | undefined>();
  const [disableDefaultControl, setDisableDefaultControl] = useState<
    boolean | undefined
  >();
  const videoPlayer = useRef<React.ElementRef<typeof View> | null>(null);

  useEffect(() => {
    BrightcoveDownloader.initModule({ accountId, policyKey });
    BrightcoveDownloader.getDownloadedVideos()
      .then((res) => console.log('[getDownloadedVideos OK]', res))
      .catch((e) => console.log('[getDownloadedVideos ERROR]', e));

    const listeners: EventSubscription[] = [];
    listeners.push(
      BrightcoveDownloader.onDownloadRequested((e) => {
        console.log('[onDownloadRequested]', e);
      }),
      BrightcoveDownloader.onDownloadStarted((e) => {
        console.log('[onDownloadStarted]', e);
      }),
      BrightcoveDownloader.onDownloadProgress((e) => {
        console.log('[onDownloadProgress]', e);
      }),
      BrightcoveDownloader.onDownloadPaused((e) => {
        console.log('[onDownloadPaused]', e);
      }),
      BrightcoveDownloader.onDownloadCompleted((e) => {
        console.log('[onDownloadCompleted]', e);
      }),
      BrightcoveDownloader.onDownloadFailed((e) => {
        console.log('[onDownloadFailed]', e);
      }),
      BrightcoveDownloader.onDownloadCanceled((e) => {
        console.log('[onDownloadCanceled]', e);
      }),
      BrightcoveDownloader.onDownloadDeleted((e) => {
        console.log('[onDownloadDeleted]', e);
      })
    );

    return () => listeners.forEach((listener) => listener.remove());
  }, []);

  const stopPlayback = () => {
    if (videoPlayer.current) {
      Commands.stopPlayback(videoPlayer.current);
    }
  };

  const play = () => {
    if (videoPlayer.current) {
      Commands.play(videoPlayer.current);
    }
  };

  const pause = () => {
    if (videoPlayer.current) {
      Commands.pause(videoPlayer.current);
    }
  };

  const seekTo = () => {
    if (videoPlayer.current) {
      Commands.seekTo(videoPlayer.current, 310);
    }
  };

  const toggleFullscreen = (value: boolean) => {
    if (videoPlayer.current) {
      Commands.toggleFullscreen(videoPlayer.current, value);
    }
  };

  const downloadVideo = () => {
    BrightcoveDownloader.downloadVideo(videoIds[0] as string);
  };
  const pauseDownloadVideo = () => {
    BrightcoveDownloader.pauseVideoDownload(videoIds[0] as string)
      .then((res) => console.log('[pauseVideoDownload OK]', res))
      .catch((e) => console.log('[pauseVideoDownload ERROR]', e));
  };
  const resumeDownloadVideo = () => {
    BrightcoveDownloader.resumeVideoDownload(videoIds[0] as string)
      .then((res) => console.log('[resumeVideoDownload OK]', res))
      .catch((e) => console.log('[resumeVideoDownload ERROR]', e));
  };
  const cancelDownloadVideo = () => {
    BrightcoveDownloader.cancelVideoDownload(videoIds[0] as string)
      .then((res) => console.log('[cancelVideoDownload OK]', res))
      .catch((e) => console.log('[cancelVideoDownload ERROR]', e));
  };
  const deleteVideo = () => {
    BrightcoveDownloader.deleteVideo(videoIds[0] as string)
      .then((res) => console.log('[deleteVideo OK]', res))
      .catch((e) => console.log('[deleteVideo ERROR]', e));
  };

  return (
    <View style={styles.container}>
      <BrightcoveView
        ref={videoPlayer}
        style={styles.video}
        accountId={accountId}
        policyKey={policyKey}
        videoId={videoIds[0] as string}
        playerName="ngthanhha"
        autoPlay
        fullscreen={fullscreen}
        disableDefaultControl={disableDefaultControl}
        volume={volume}
        playbackRate={1}
        // onReady={(e) => console.log('onReady', e.nativeEvent)}
        // onPlay={(e) => console.log('onPlay', e.nativeEvent)}
        // onPause={(e) => console.log('onPause', e.nativeEvent)}
        // onEnd={(e) => console.log('onEnd', e.nativeEvent)}
        // onProgress={(e) => console.log('onProgress', e.nativeEvent)}
        // onUpdateBufferProgress={(e) =>
        //   console.log('onUpdateBufferProgress', e.nativeEvent)
        // }
        // onChangeDuration={(e) => console.log('onChangeDuration', e.nativeEvent)}
        onEnterFullscreen={(e) =>
          console.log('onEnterFullscreen', e.nativeEvent)
        }
        onExitFullscreen={(e) => console.log('onExitFullscreen', e.nativeEvent)}
      />
      <ScrollView>
        <Button title="Play" onPress={play} />
        <Button title="Pause" onPress={pause} />
        <Button title="Seek" onPress={seekTo} />
        <Button title="Stop" onPress={stopPlayback} />
        <Button title="Set volume 0.2" onPress={() => setVolume(0.2)} />
        <Button title="Set volume 0.5" onPress={() => setVolume(0.5)} />
        <Button title="Set volume 1" onPress={() => setVolume(1)} />
        <Button
          title={`fullscreen: ${fullscreen}`}
          onPress={() => setFullscreen(!fullscreen)}
        />
        <Button
          title="Toggle fullscreen: true"
          onPress={() => toggleFullscreen(true)}
        />
        <Button
          title="Toggle fullscreen: false"
          onPress={() => toggleFullscreen(false)}
        />
        <Button
          title={`Disable default control: ${disableDefaultControl}`}
          onPress={() => setDisableDefaultControl(!disableDefaultControl)}
        />
        <Button title="Download video" onPress={downloadVideo} />
        <Button title="Pause download video" onPress={pauseDownloadVideo} />
        <Button title="Resume download video" onPress={resumeDownloadVideo} />
        <Button title="Cancel download video" onPress={cancelDownloadVideo} />
        <Button title="Delete video" onPress={deleteVideo} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  video: {
    width: '100%',
    height: 200,
    marginVertical: 20,
  },
});
