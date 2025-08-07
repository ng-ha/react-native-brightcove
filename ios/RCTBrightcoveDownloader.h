//
//  RCTBrightcoveDownloader.h
//  Brightcove
//
//  Created by MN12 on 7/8/25.
//

#import <BrightcoveCodegenSpec/BrightcoveCodegenSpec.h>
#import <Foundation/Foundation.h>
#import <React/RCTInitializing.h>
#import <React/RCTInvalidating.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCTBrightcoveDownloader
    : NativeBrightcoveDownloaderSpecBase <NativeBrightcoveDownloaderSpec, RCTInitializing,
                                          RCTInvalidating>

@end

NS_ASSUME_NONNULL_END
