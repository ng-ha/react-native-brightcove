import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type {
  EventEmitter,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';

export type TBrightcoveDownloaderParams = {
  id: string;
};

export type TBrightcoveDownloadConfig = {
  accountId: string;
  policyKey: string;
};

export type TBrightcoveDownloadedVideo = {
  id: string;
  referenceId?: string | null;
  name?: string | null;
  shortDescription?: string | null;
  longDescription?: string | null;
  duration?: Int32 | null;
  thumbnailUri?: string | null;
  posterUri?: string | null;
  licenseExpiryDate?: string | null;
  size?: Int32 | null;
};

export interface Spec extends TurboModule {
  initModule(config: TBrightcoveDownloadConfig): void;
  deinitModule(): void;
  getDownloadedVideos(): Promise<TBrightcoveDownloadedVideo[]>;
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
