import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type { EventEmitter } from 'react-native/Libraries/Types/CodegenTypes';

export type TBrightcoveDownloaderParams = {
  value: string;
};

export interface Spec extends TurboModule {
  downloadVideo(id: string): void;
  pauseVideoDownload(id: string): void;
  resumeVideoDownload(id: string): void;
  deleteVideo(id: string): void;
  readonly onDownloadRequested: EventEmitter<TBrightcoveDownloaderParams>;
  readonly onDownloadStarted: EventEmitter<TBrightcoveDownloaderParams>;
  readonly onDownloadProgress: EventEmitter<TBrightcoveDownloaderParams>;
  readonly onDownloadPaused: EventEmitter<TBrightcoveDownloaderParams>;
  readonly onDownloadCompleted: EventEmitter<TBrightcoveDownloaderParams>;
  readonly onDownloadCanceled: EventEmitter<TBrightcoveDownloaderParams>;
  readonly onDownloadDeleted: EventEmitter<TBrightcoveDownloaderParams>;
  readonly onDownloadFailed: EventEmitter<TBrightcoveDownloaderParams>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeBrightcoveDownloader'
);
