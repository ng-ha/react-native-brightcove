import { useRef, useState } from 'react';
import { Button, Platform, ScrollView, StyleSheet, View } from 'react-native';

import { useRoute, type RouteProp } from '@react-navigation/native';
import { BrightcoveView, Commands } from 'react-native-brightcove';
import { accountId, policyKey, videoId } from '../configs';
import type { RootStackParamList } from '../App';

export function PlayerScreen() {
  const enablePiP =
    useRoute<RouteProp<RootStackParamList, 'Player'>>().params
      ?.enablePictureInPicture;
  const [volume, setVolume] = useState<number | undefined>();
  const [fullscreen, setFullscreen] = useState<boolean | undefined>();
  const [disableDefaultControl, setDisableDefaultControl] = useState<
    boolean | undefined
  >();
  const [enablePictureInPicture, setEnablePictureInPicture] = useState<
    boolean | undefined
  >(enablePiP);
  const [inPiP, setInPiP] = useState(false);
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

  const toggleFullscreen = (value: boolean) => {
    if (videoPlayer.current) {
      Commands.toggleFullscreen(videoPlayer.current, value);
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
        fullscreen={fullscreen}
        disableDefaultControl={disableDefaultControl}
        volume={volume}
        playbackRate={1}
        enablePictureInPicture={enablePictureInPicture}
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
        onWillEnterPictureInPictureMode={(e) => {
          console.log('onWillEnterPictureInPictureMode', e.nativeEvent);
          if (!inPiP) setInPiP(true);
        }}
        onWillExitPictureInPictureMode={(e) => {
          console.log('onWillExitPictureInPictureMode', e.nativeEvent);
          if (inPiP) setInPiP(false);
        }}
        onDidEnterPictureInPictureMode={(e) => {
          console.log('onDidEnterPictureInPictureMode', e.nativeEvent);
          if (!inPiP) setInPiP(true);
        }}
        onDidExitPictureInPictureMode={(e) => {
          console.log('onDidExitPictureInPictureMode', e.nativeEvent);
          if (inPiP) setInPiP(false);
        }}
      />
      {(Platform.OS === 'ios' || (Platform.OS === 'android' && !inPiP)) && (
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
          <Button
            title={`Enable picture-in-picture: ${enablePictureInPicture}`}
            onPress={() => setEnablePictureInPicture(!enablePictureInPicture)}
          />
        </ScrollView>
      )}
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
    aspectRatio: 16 / 9,
  },
});
