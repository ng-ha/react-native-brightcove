#import "RCTBrightcoveView.h"

#import <BrightcovePlayerSDK/BrightcovePlayerSDK-Swift.h>
#import <BrightcovePlayerSDK/BrightcovePlayerSDK.h>
#import <react/renderer/components/BrightcoveCodegenSpec/ComponentDescriptors.h>
#import <react/renderer/components/BrightcoveCodegenSpec/EventEmitters.h>
#import <react/renderer/components/BrightcoveCodegenSpec/Props.h>
#import <react/renderer/components/BrightcoveCodegenSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import "react_native_brightcove-Swift.h"

using namespace facebook::react;

#ifdef DEBUG
inline std::ostream &operator<<(std::ostream &os, const BrightcoveViewProps &p) {
  os << "BrightcoveViewProps{";
  os << "accountId:\"" << p.accountId << "\", ";
  os << "policyKey:\"" << p.policyKey << "\", ";
  os << "playerName:\"" << p.playerName << "\", ";
  os << "videoId:\"" << p.videoId << "\", ";
  os << "playlistReferenceId:\"" << p.playlistReferenceId << "\", ";
  os << "autoPlay:" << p.autoPlay << ", ";
  os << "play:" << p.play << ", ";
  os << "fullscreen:" << p.fullscreen << ", ";
  os << "disableDefaultControl:" << p.disableDefaultControl << ", ";
  os << "volume:" << p.volume << ", ";
  os << "playbackRate:" << p.playbackRate;
  os << "}";
  return os;
}
#endif

// converting std::string → NSString
static inline NSString *NSStringFromStdString(const std::string &s) {
  if (s.empty()) {
    return @"";
  }
  return [NSString stringWithUTF8String:s.c_str()];
}

@interface RCTBrightcoveView () <RCTBrightcoveViewViewProtocol,
                                 RCTBrightcoveViewEventEmitterDelegate>

@end

@implementation RCTBrightcoveView {
  RCTBrightcoveViewImpl *_view;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const BrightcoveViewProps>();
    _props = defaultProps;
    _view = [[RCTBrightcoveViewImpl alloc] init];
    _view.eventEmitterDelegate = self;
    self.contentView = _view;
  }
  return self;
}

- (void)dealloc {
  if (_view) {
    _view.eventEmitterDelegate = nil;
    _view = nil;
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];
  _view.frame = self.bounds;
}

//- (void)ensureView {
//  if (!_view) {
//    _view = [[RCTBrightcoveViewImpl alloc] init];
//    _view.eventEmitterDelegate = self;
//    self.contentView = _view;
//  }
//}

// Called when the view is placed into the recycle pool.
// Reset state and restore default props to ensure a clean reuse.
// Note: _view becomes nil after recycling => use ensureView in updateProps
- (void)prepareForRecycle {
  [super prepareForRecycle];
  static const auto defaultProps = std::make_shared<const BrightcoveViewProps>();
  _props = defaultProps;

#if DEBUG
  const auto &currentViewProps = *std::static_pointer_cast<BrightcoveViewProps const>(_props);
  std::ostringstream oss;
  oss << currentViewProps;
  NSString *log = NSStringFromStdString(oss.str());
  NSLog(@"prepareForRecycle: %@", log);
#endif
}

// Disable recycling and force a new instance to be created each time.
+ (BOOL)shouldBeRecycled {
  return NO;
}

#pragma mark - Update props

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<BrightcoveViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<BrightcoveViewProps const>(props);

  // log props
#if DEBUG
  std::ostringstream oss;
  oss << oldViewProps << " -> " << newViewProps;
  NSString *log = NSStringFromStdString(oss.str());
  NSLog(@"updateProps: %@", log);
#endif

  // accountId
  if (oldViewProps.accountId != newViewProps.accountId) {
    NSString *accountId = NSStringFromStdString(newViewProps.accountId);
    [_view setAccountId:accountId];
  }

  // policyKey
  if (oldViewProps.policyKey != newViewProps.policyKey) {
    NSString *policyKey = NSStringFromStdString(newViewProps.policyKey);
    [_view setPolicyKey:policyKey];
  }

  // videoId
  if (oldViewProps.videoId != newViewProps.videoId) {
    NSString *videoId = NSStringFromStdString(newViewProps.videoId);
    [_view setVideoId:videoId];
  }

  // playerName
  if (oldViewProps.playerName != newViewProps.playerName) {
    NSString *playerName = NSStringFromStdString(newViewProps.playerName);
    [_view setPlayerName:playerName];
  }

  // autoPlay
  if (oldViewProps.autoPlay != newViewProps.autoPlay) {
    [_view setAutoPlay:newViewProps.autoPlay];
  }

  // play
  if (oldViewProps.play != newViewProps.play) {
    [_view setPlay:newViewProps.play];
  }

  // fullscreen
  if (oldViewProps.fullscreen != newViewProps.fullscreen) {
    [_view setFullscreen:newViewProps.fullscreen];
  }

  // volume
  if (oldViewProps.volume != newViewProps.volume) {
    [_view setVolume:newViewProps.volume];
  }

  // playbackRate
  if (oldViewProps.playbackRate != newViewProps.playbackRate) {
    [_view setPlaybackRate:newViewProps.playbackRate];
  }

  // disableDefaultControl
  if (oldViewProps.disableDefaultControl != newViewProps.disableDefaultControl) {
    [_view setDisableDefaultControl:newViewProps.disableDefaultControl];
  }

  [super updateProps:props oldProps:oldProps];
}

#pragma mark - Player Actions

- (void)pause {
  [_view pause];
}

- (void)play {
  [_view play];
}

- (void)seekTo:(NSInteger)seconds {
  [_view seekTo:(float)seconds
      completionHandler:^(BOOL finished){
      }];
}

- (void)stopPlayback {
  [_view stopPlayback];
  _view = nil;
}

- (void)toggleFullscreen:(BOOL)isFullscreen {
  [_view setFullscreen:isFullscreen];
}

- (void)toggleInViewPort:(BOOL)inViewPort {
  [_view toggleInViewPort:inViewPort];
}

#pragma mark - Handle events

- (void)emitEvent:(NSString *_Nonnull)name
      withPayload:(NSDictionary<NSString *, id> *_Nullable)payload {
  if ([name isEqualToString:@"onReady"]) {
    BrightcoveViewEventEmitter::OnReady eventStruct;
    self.eventEmitter.onReady(eventStruct);
    return;
  }

  if ([name isEqualToString:@"onPlay"]) {
    BrightcoveViewEventEmitter::OnPlay eventStruct;
    self.eventEmitter.onPlay(eventStruct);
    return;
  }

  if ([name isEqualToString:@"onPause"]) {
    BrightcoveViewEventEmitter::OnPause eventStruct;
    self.eventEmitter.onPause(eventStruct);
    return;
  }

  if ([name isEqualToString:@"onEnd"]) {
    BrightcoveViewEventEmitter::OnEnd eventStruct;
    self.eventEmitter.onEnd(eventStruct);
    return;
  }

  if ([name isEqualToString:@"onProgress"]) {
    BrightcoveViewEventEmitter::OnProgress eventStruct;
    id val = payload[@"currentTime"];
    int currentTime = 0;
    if (val && val != (id)kCFNull && [val respondsToSelector:@selector(intValue)]) {
      currentTime = [val intValue];
    }
    eventStruct.currentTime = currentTime;
    self.eventEmitter.onProgress(eventStruct);
    return;
  }

  if ([name isEqualToString:@"onUpdateBufferProgress"]) {
    BrightcoveViewEventEmitter::OnUpdateBufferProgress eventStruct;
    id val = payload[@"bufferProgress"];
    float bufferProgress = 0;
    if (val && val != (id)kCFNull && [val respondsToSelector:@selector(floatValue)]) {
      bufferProgress = [val floatValue];
    }
    eventStruct.bufferProgress = bufferProgress;
    self.eventEmitter.onUpdateBufferProgress(eventStruct);
    return;
  }

  if ([name isEqualToString:@"onChangeDuration"]) {
    BrightcoveViewEventEmitter::OnChangeDuration eventStruct;
    id val = payload[@"duration"];
    int duration = 0;
    if (val && val != (id)kCFNull && [val respondsToSelector:@selector(intValue)]) {
      duration = [val intValue];
    }
    eventStruct.duration = duration;
    self.eventEmitter.onChangeDuration(eventStruct);
    return;
    return;
  }

  if ([name isEqualToString:@"onEnterFullscreen"]) {
    BrightcoveViewEventEmitter::OnEnterFullscreen eventStruct;
    self.eventEmitter.onEnterFullscreen(eventStruct);
    return;
  }

  if ([name isEqualToString:@"onExitFullscreen"]) {
    BrightcoveViewEventEmitter::OnExitFullscreen eventStruct;
    self.eventEmitter.onExitFullscreen(eventStruct);
    return;
  }
}

// Event emitter convenience method
- (const BrightcoveViewEventEmitter &)eventEmitter {
  return static_cast<const BrightcoveViewEventEmitter &>(*_eventEmitter);
}

// Override the default handleCommand with RCTBrightcoveViewHandleCommand helper
- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  RCTBrightcoveViewHandleCommand(self, commandName, args);
}

// for Fabric component, use componentDescriptorProvider instead
// Class<RCTComponentViewProtocol> RCTBrightcoveViewCls(void) { return RCTBrightcoveView.class; }

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<BrightcoveViewComponentDescriptor>();
}

@end
