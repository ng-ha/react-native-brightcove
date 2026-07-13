# react-native-brightcove

Brightcove Player SDK implementation for React Native, supporting the **New Architecture** (Fabric components and TurboModules).

## Features
- **Fabric Player Component (`BrightcoveView`)**: Native rendering, playback rate control, custom volume, and event listeners.
- **Picture in Picture (PiP)**: Full support for Picture in Picture mode.
- **TurboModule Offline Downloader (`BrightcoveDownloader`)**: Pause, resume, and manage offline playback of videos.

---

## Installation

```sh
yarn add react-native-brightcove
# or
npm install react-native-brightcove
```

### iOS Setup

1. Add the Brightcove CocoaPods spec repositories to the top of your `ios/Podfile`:
   ```ruby
   source 'https://cdn.cocoapods.org/' # for github actions
   source 'https://github.com/brightcove/BrightcoveSpecs.git'
   ```

2. After installing the package and updating your Podfile, install the CocoaPods dependencies:
   ```sh
   cd ios && pod install
   ```

> [!NOTE]
> This package uses the `Brightcove-Player-Core/XCFramework` pod dependency (version `~> 7.0.6`).

### Android Setup

Add the Brightcove Maven repository to your project's `android/build.gradle` or settings file under repositories:

```groovy
allprojects {
    repositories {
        // ...
        maven {
            url 'https://repo.brightcove.com/releases'
        }
    }
}
```

---

## Picture-in-Picture Setup

To enable Picture-in-Picture (PiP) functionality, follow these platform-specific setup steps:

### iOS

In your app's `Info.plist` (typically under `ios/YourAppName/Info.plist`), add `audio` background mode support:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Android

In your `MainActivity.kt` (typically under `android/app/src/main/java/com/yourAppName/MainActivity.kt`), add the following imports and override `onPictureInPictureModeChanged` and `onUserLeaveHint`:

```kotlin
import android.content.res.Configuration
import com.ngthanhha.brightcove.util.PictureInPictureUtil

// Inside your MainActivity class:

override fun onPictureInPictureModeChanged(
  isInPictureInPictureMode: Boolean,
  newConfig: Configuration,
) {
  super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
  PictureInPictureUtil.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
}

override fun onUserLeaveHint() {
  super.onUserLeaveHint()
  PictureInPictureUtil.onUserLeaveHint()
}
```

---

## Usage

### 1. Video Player (`BrightcoveView`)

Render the video player component inline in your application:

```tsx
import React, { useRef } from 'react';
import { StyleSheet, View, Button } from 'react-native';
import { BrightcoveView, Commands } from 'react-native-brightcove';

export function PlayerScreen() {
  const playerRef = useRef(null);

  const play = () => {
    if (playerRef.current) {
      Commands.play(playerRef.current);
    }
  };

  const pause = () => {
    if (playerRef.current) {
      Commands.pause(playerRef.current);
    }
  };

  return (
    <View style={styles.container}>
      <BrightcoveView
        ref={playerRef}
        style={styles.player}
        accountId="your-account-id"
        policyKey="your-policy-key"
        videoId="your-video-id"
        autoPlay={true}
        enablePictureInPicture={true}
        onReady={(e) => console.log('Ready', e.nativeEvent)}
        onPlay={(e) => console.log('Playing', e.nativeEvent)}
        onPause={(e) => console.log('Paused', e.nativeEvent)}
        onEnd={(e) => console.log('Finished', e.nativeEvent)}
        onProgress={(e) => console.log('Progress', e.nativeEvent.currentTime)}
      />
      <View style={styles.controls}>
        <Button title="Play" onPress={play} />
        <Button title="Pause" onPress={pause} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  player: { width: '100%', aspectRatio: 16 / 9 },
  controls: { flexDirection: 'row', justifyContent: 'space-around', margin: 10 }
});
```

### 2. Offline Downloader (`BrightcoveDownloader`)

Initialize the downloader module first, then request downloads or query downloaded videos.

```tsx
import React, { useEffect, useState } from 'react';
import { Button, Text, View } from 'react-native';
import { BrightcoveDownloader } from 'react-native-brightcove';

export function DownloaderScreen() {
  const [downloadProgress, setDownloadProgress] = useState(0);

  useEffect(() => {
    // 1. Initialize the module
    BrightcoveDownloader.initModule({
      accountId: 'your-account-id',
      policyKey: 'your-policy-key',
    });

    // 2. Set up event listeners
    const progressSub = BrightcoveDownloader.onDownloadProgress((event) => {
      console.log(`Downloading ${event.id}: ${event.progress}%`);
      setDownloadProgress(event.progress);
    });

    const completeSub = BrightcoveDownloader.onDownloadCompleted((event) => {
      console.log(`Download finished for video: ${event.id}`);
    });

    return () => {
      progressSub.remove();
      completeSub.remove();
      BrightcoveDownloader.deinitModule();
    };
  }, []);

  const startDownload = () => {
    BrightcoveDownloader.downloadVideo('your-video-id');
  };

  return (
    <View style={{ padding: 20 }}>
      <Text>Progress: {downloadProgress.toFixed(1)}%</Text>
      <Button title="Download Video" onPress={startDownload} />
    </View>
  );
}
```

---

## API Reference

### `BrightcoveView` Props

| Prop | Type | Description |
|---|---|---|
| `accountId` | `string` | Brightcove Account ID |
| `policyKey` | `string` | Brightcove Policy Key |
| `playerName` | `string` | Custom Player Name |
| `videoId` | `string` | ID of the video to play |
| `playlistReferenceId` | `string` | Reference ID of the playlist |
| `autoPlay` | `boolean` | Automatically play when ready |
| `play` | `boolean` | Control play state directly |
| `fullscreen` | `boolean` | Control fullscreen mode |
| `disableDefaultControl` | `boolean` | Disable default player controls |
| `volume` | `float` | Volume range `0.0` - `1.0` (set after ready) |
| `playbackRate` | `float` | Playback speed |
| `enablePictureInPicture`| `boolean` | Enable/disable Picture in Picture support |

#### Events

- `onReady`
- `onPlay`
- `onPause`
- `onEnd`
- `onProgress`: Returns `{ currentTime: number }` (milliseconds)
- `onUpdateBufferProgress`: Returns `{ bufferProgress: number }`
- `onChangeDuration`: Returns `{ duration: number }` (milliseconds)
- `onEnterFullscreen`
- `onExitFullscreen`
- `onWillEnterPictureInPictureMode`
- `onDidEnterPictureInPictureMode`
- `onWillExitPictureInPictureMode`
- `onDidExitPictureInPictureMode`

#### Commands

Native imperative actions controlled via `Commands`:
- `play(ref)`
- `pause(ref)`
- `seekTo(ref, seconds: number)`
- `stopPlayback(ref)`
- `toggleFullscreen(ref, isFullscreen: boolean)`
- `toggleInViewPort(ref, inViewPort: boolean)`

---

### `BrightcoveDownloader` API

#### Methods

- **`initModule(config: { accountId: string, policyKey: string }): void`**: Initializes the downloader SDK.
- **`deinitModule(): void`**: Disposes downloader listeners and resources.
- **`getAllDownloadedVideos(): Promise<TBrightcoveDownloadedVideo[]>`**: Returns a list of all downloaded video metadata objects.
- **`getDownloadedVideoById(id: string): Promise<TBrightcoveDownloadedVideo>`**: Retrieves downloaded video details by ID.
- **`estimateDownloadSize(id: string): Promise<number>`**: Estimates file size in bytes for a video.
- **`downloadVideo(id: string): void`**: Queues/starts downloading a video.
- **`pauseVideoDownload(id: string): Promise<boolean>`**: Pauses active download.
- **`resumeVideoDownload(id: string): Promise<boolean>`**: Resumes paused download.
- **`cancelVideoDownload(id: string): Promise<boolean>`**: Cancels download and clears files.
- **`deleteVideo(id: string): Promise<boolean>`**: Deletes a saved video file.

#### Event Subscriptions

Use these listener registration functions (which return an `EventSubscription` with a `.remove()` method):
- `onDownloadRequested(callback: (e: { id: string }) => void)`
- `onDownloadStarted(callback: (e: { id: string, estimatedSize?: number, name?: string, duration?: number }) => void)`
- `onDownloadProgress(callback: (e: { id: string, progress: number, bytesDownloaded: number }) => void)`
- `onDownloadPaused(callback: (e: { id: string, reason: number }) => void)`
- `onDownloadCompleted(callback: (e: { id: string }) => void)`
- `onDownloadCanceled(callback: (e: { id: string }) => void)`
- `onDownloadDeleted(callback: (e: { id: string }) => void)`
- `onDownloadFailed(callback: (e: { id: string, reason: number }) => void)`

---

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
