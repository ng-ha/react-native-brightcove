import type { CodegenTypes, HostComponent, ViewProps } from 'react-native';
import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import type { Float, Int32 } from 'react-native/Libraries/Types/CodegenTypes';

type TBrightcovePlayerEventBase = {
  target: Int32;
};

type TBrightcovePlayerEventProgress = {
  target: Int32;
  currentTime: Int32;
};

type TBrightcovePlayerEventDuration = {
  target: Int32;
  duration: Int32;
};

type TBrightcovePlayerEventBuffer = {
  target: Int32;
  bufferProgress: Int32;
};

interface NativeProps extends ViewProps {
  accountId?: string | null;
  playerName?: string | null;
  videoId?: string | null;
  policyKey?: string | null;
  autoPlay?: boolean | null;
  play?: boolean | null;
  fullscreen?: boolean | null;
  disableDefaultControl?: boolean | null;
  /**
   * Volume in **0.0** to **1.0** range, default is **1.0**.
   * You should set volume it after the player is initialized.
   * If you set the volume before the player is initialized, it will not work.
   */
  volume?: Float | null;
  playbackRate?: Float | null;
  onReady?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventBase> | null;
  onPlay?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventBase> | null;
  onPause?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventBase> | null;
  onEnd?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventBase> | null;
  onProgress?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventProgress> | null;
  onUpdateBufferProgress?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventBuffer> | null;
  onChangeDuration?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventDuration> | null;
  onEnterFullscreen?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventBase> | null;
  onExitFullscreen?: CodegenTypes.BubblingEventHandler<TBrightcovePlayerEventBase> | null;
}

/**
 * All the Native Commands must have a first parameter of type React.ElementRef.
 * In TypeScript, the React.ElementRef is deprecated. The correct type to use is actually React.ComponentRef.
 * However, due to a bug in Codegen, using ComponentRef will crash the app. We have the fix already,
 * but we need to release a new version of React Native to apply it.
 * https://reactnative.dev/docs/next/the-new-architecture/fabric-component-native-commands#1-update-your-component-specs
 */
interface NativeCommands {
  play: (viewRef: React.ElementRef<HostComponent<NativeProps>>) => void;
  pause: (viewRef: React.ElementRef<HostComponent<NativeProps>>) => void;
  /**
   * seek to a specific time in **seconds**
   * @param viewRef - The reference to the BrightcoveView component
   * @param seconds - The time in **seconds** to seek to
   * @returns void
   */
  seekTo: (
    viewRef: React.ElementRef<HostComponent<NativeProps>>,
    seconds: Int32
  ) => void;
  stopPlayback: (viewRef: React.ElementRef<HostComponent<NativeProps>>) => void;
  toggleFullscreen: (
    viewRef: React.ElementRef<HostComponent<NativeProps>>,
    isFullscreen: boolean
  ) => void;
  toggleInViewPort: (
    viewRef: React.ElementRef<HostComponent<NativeProps>>,
    inViewPort: boolean
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    'play',
    'pause',
    'seekTo',
    'stopPlayback',
    'toggleFullscreen',
    'toggleInViewPort',
  ],
});

export default codegenNativeComponent<NativeProps>(
  'BrightcoveView'
) as HostComponent<NativeProps>;
