import { useRef, useState } from 'react';
import { View, StyleSheet, Button } from 'react-native';
import {
  BrightcoveDownloader,
  BrightcoveView,
  Commands,
} from 'react-native-brightcove';

const accountId = '5434391461001';
const videoId = '6140448705001';
const policyKey =
  'BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L';

export default function App() {
  const [volume, setVolume] = useState<number | undefined>();
  const videoPlayer = useRef<React.ElementRef<typeof View> | null>(null);

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

  const fullscreen = () => {
    if (videoPlayer.current) {
      Commands.toggleFullscreen(videoPlayer.current, true);
    }
  };

  return (
    <View style={styles.container}>
      <BrightcoveView
        ref={videoPlayer}
        style={styles.video}
        accountId={accountId}
        policyKey={policyKey}
        videoId={videoId}
        playerName="ngthanhha"
        autoPlay
        // play
        // fullscreen
        disableDefaultControl={false}
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
      <Button title="Play" onPress={play} />
      <Button title="Pause" onPress={pause} />
      <Button title="Seek" onPress={seekTo} />
      <Button title="Stop" onPress={stopPlayback} />
      <Button title="Fullscreen" onPress={fullscreen} />
      <Button title="Set volume 0.2" onPress={() => setVolume(0.2)} />
      <Button title="Set volume 0.5" onPress={() => setVolume(0.5)} />
      <Button title="Set volume 1" onPress={() => setVolume(1)} />
      <Button
        title="Download video"
        onPress={() => BrightcoveDownloader.downloadVideo('id-testing')}
      />
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
