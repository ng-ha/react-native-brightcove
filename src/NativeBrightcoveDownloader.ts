import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type {
  Double,
  EventEmitter,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';

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

// Download result

export type TBrightcovePauseDownloadResult = {
  status?: Int32 | null;
};

export type TBrightcoveResumeDownloadResult = {
  status?: Int32 | null;
};

export type TBrightcoveDeleteVideoResult = {
  result?: boolean | null;
};

// Download event

export type TBrightcoveDownloadRequestedEvent = {
  id: string;
};

export type TBrightcoveDownloadStartedEvent = {
  id: string;
  estimatedSize: Int32;
};

export type TBrightcoveDownloadProgressEvent = {
  id: string;
  maxSize: Int32;
  bytesDownloaded: Int32;
  progress: Double;
};

export type TBrightcoveDownloadPausedEvent = {
  id: string;
  reason: Int32;
};

export type TBrightcoveDownloadCompletedEvent = {
  id: string;
};

export type TBrightcoveDownloadCanceledEvent = {
  id: string;
};

export type TBrightcoveDownloadDeletedEvent = {
  id: string;
};

export type TBrightcoveDownloadFailedEvent = {
  id: string;
  reason: Int32;
};

export interface Spec extends TurboModule {
  initModule(config: TBrightcoveDownloadConfig): void;
  deinitModule(): void;
  getDownloadedVideos(): Promise<TBrightcoveDownloadedVideo[]>;
  downloadVideo(id: string): void;
  pauseVideoDownload(id: string): Promise<TBrightcovePauseDownloadResult>;
  resumeVideoDownload(id: string): Promise<TBrightcoveResumeDownloadResult>;
  deleteVideo(id: string): Promise<TBrightcoveDeleteVideoResult>;
  readonly onDownloadRequested: EventEmitter<TBrightcoveDownloadRequestedEvent>;
  readonly onDownloadStarted: EventEmitter<TBrightcoveDownloadStartedEvent>;
  readonly onDownloadProgress: EventEmitter<TBrightcoveDownloadProgressEvent>;
  readonly onDownloadPaused: EventEmitter<TBrightcoveDownloadPausedEvent>;
  readonly onDownloadCompleted: EventEmitter<TBrightcoveDownloadCompletedEvent>;
  readonly onDownloadCanceled: EventEmitter<TBrightcoveDownloadCanceledEvent>;
  readonly onDownloadDeleted: EventEmitter<TBrightcoveDownloadDeletedEvent>;
  readonly onDownloadFailed: EventEmitter<TBrightcoveDownloadFailedEvent>;
}

export default TurboModuleRegistry.getEnforcing<Spec>(
  'NativeBrightcoveDownloader'
);
