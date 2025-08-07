//
//  RCTBrightcoveDownloader.m
//  Brightcove
//
//  Created by MN12 on 7/8/25.
//

#import "RCTBrightcoveDownloader.h"

@implementation RCTBrightcoveDownloader

- (void)initModule:(JS::NativeBrightcoveDownloader::TBrightcoveDownloadConfig &)config {
}

- (void)deinitModule {
}

- (void)getDownloadedVideos:(nonnull RCTPromiseResolveBlock)resolve
                     reject:(nonnull RCTPromiseRejectBlock)reject {
}

- (void)downloadVideo:(nonnull NSString *)id {
}

- (void)pauseVideoDownload:(nonnull NSString *)id
                   resolve:(nonnull RCTPromiseResolveBlock)resolve
                    reject:(nonnull RCTPromiseRejectBlock)reject {
}

- (void)resumeVideoDownload:(nonnull NSString *)id
                    resolve:(nonnull RCTPromiseResolveBlock)resolve
                     reject:(nonnull RCTPromiseRejectBlock)reject {
}

- (void)deleteVideo:(nonnull NSString *)id
            resolve:(nonnull RCTPromiseResolveBlock)resolve
             reject:(nonnull RCTPromiseRejectBlock)reject {
}

- (void)initialize {
}

- (void)invalidate {
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeBrightcoveDownloaderSpecJSI>(params);
}

+ (NSString *)moduleName {
  return @"BrightcoveDownloader";
}

@end
