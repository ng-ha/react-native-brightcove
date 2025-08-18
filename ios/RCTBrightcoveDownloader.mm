//
//  RCTBrightcoveDownloader.m
//  Brightcove
//
//  Created by MN12 on 7/8/25.
//

#import <BrightcovePlayerSDK/BrightcovePlayerSDK-Swift.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>

#import "RCTBrightcoveDownloader.h"
#import "react_native_brightcove-Swift.h"

@interface RCTBrightcoveDownloader () <RCTBrightcoveDownloadEventEmitterDelegate>

@end

@implementation RCTBrightcoveDownloader {
  RCTBrightcoveDownloaderImpl *downloader;
}

- (id)init {
  if (self = [super init]) {
    downloader = [RCTBrightcoveDownloaderImpl new];
    downloader.eventEmitterDelegate = self;
  }
  return self;
}

- (void)initModule:(JS::NativeBrightcoveDownloader::TBrightcoveDownloadConfig &)config {
  NSString *accountId = config.accountId() ?: @"";
  NSString *policyKey = config.policyKey() ?: @"";
  NSDictionary *dict = @{@"accountId" : accountId, @"policyKey" : policyKey};
  [downloader initModuleWithConfig:dict];
}

- (void)deinitModule {
  [downloader deinitModule];
}

- (void)getDownloadedVideos:(nonnull RCTPromiseResolveBlock)resolve
                     reject:(nonnull RCTPromiseRejectBlock)reject {
  [downloader getDownloadedVideosWithResolve:resolve reject:reject];
}

- (void)downloadVideo:(nonnull NSString *)id {
  [downloader findVideoToDownloadWithId:id];
}

- (void)pauseVideoDownload:(nonnull NSString *)id
                   resolve:(nonnull RCTPromiseResolveBlock)resolve
                    reject:(nonnull RCTPromiseRejectBlock)reject {
  [downloader pauseVideoDownloadWithVideoId:id resolve:resolve reject:reject];
}

- (void)resumeVideoDownload:(nonnull NSString *)id
                    resolve:(nonnull RCTPromiseResolveBlock)resolve
                     reject:(nonnull RCTPromiseRejectBlock)reject {
  [downloader resumeVideoDownloadWithVideoId:id resolve:resolve reject:reject];
}

- (void)deleteVideo:(nonnull NSString *)id
            resolve:(nonnull RCTPromiseResolveBlock)resolve
             reject:(nonnull RCTPromiseRejectBlock)reject {
  [downloader deleteVideoWithVideoId:id resolve:resolve reject:reject];
}

- (void)initialize {
}

- (void)invalidate {
  [downloader deinitModule];
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeBrightcoveDownloaderSpecJSI>(params);
}

+ (NSString *)moduleName {
  return @"BrightcoveDownloader";
}

@end
