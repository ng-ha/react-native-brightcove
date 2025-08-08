#import "RCTBrightcoveView.h"

#import <BrightcovePlayerSDK/BCOVPUIPlayerView.h>
#import <react/renderer/components/BrightcoveCodegenSpec/ComponentDescriptors.h>
#import <react/renderer/components/BrightcoveCodegenSpec/EventEmitters.h>
#import <react/renderer/components/BrightcoveCodegenSpec/Props.h>
#import <react/renderer/components/BrightcoveCodegenSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import "react_native_brightcove-Swift.h"

using namespace facebook::react;

@interface RCTBrightcoveView () <RCTBrightcoveViewViewProtocol, BCOVPUIPlayerViewDelegate>

@end

@implementation RCTBrightcoveView {
  //  UIView *_view;
  RCTBrightcoveViewImpl *_brightcoveView;
}

//- (instancetype)init {
//  if (self = [super init]) {
//    _brightcoveView = [[RCTBrightcoveViewImpl alloc] init];
//    [self addSubview:_brightcoveView];
//  }
//  return self;
//}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const BrightcoveViewProps>();
    _props = defaultProps;
    _brightcoveView = [[RCTBrightcoveViewImpl alloc] init];
    //    _brightcoveView.delegate = self;
    self.contentView = _brightcoveView;
  }
  return self;
}

- (void)dealloc {
  if (_brightcoveView) {
    //    _brightcoveView.delegate = nil;
    _brightcoveView = nil;
  }
}

//  You can listen to this lifecycle event to pause / resume operations as Fabric components are
//  kept in memory to be reused later
//- (void)didMoveToSuperview {
//  if (self.superview != nil) {
//    // Manually triggering events that child third-party views/controllers listen to resume
//    // operations
//    [_brightcoveView triggerViewWillAppear];
//  }
//}

- (void)layoutSubviews {
  [super layoutSubviews];
  _brightcoveView.frame = self.bounds;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps {
  const auto &oldViewProps = *std::static_pointer_cast<BrightcoveViewProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<BrightcoveViewProps const>(props);

  //  if (oldViewProps.color != newViewProps.color) {
  //    NSString *colorToConvert = [[NSString alloc] initWithUTF8String:newViewProps.color.c_str()];
  //    [_view setBackgroundColor:[self hexStringToColor:colorToConvert]];
  //  }

  [super updateProps:props oldProps:oldProps];
}

//Class<RCTComponentViewProtocol> RCTBrightcoveViewCls(void) { return RCTBrightcoveView.class; }

- (void)pause {
}

- (void)play {
}

- (void)seekTo:(NSInteger)seconds {
}

- (void)stopPlayback {
}

- (void)toggleFullscreen:(BOOL)isFullscreen {
}

- (void)toggleInViewPort:(BOOL)inViewPort {
}

// Event emitter convenience method
- (const BrightcoveViewEventEmitter &)eventEmitter {
  return static_cast<const BrightcoveViewEventEmitter &>(*_eventEmitter);
}

// Override the default handleCommand with RCTBrightcoveViewHandleCommand helper
- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args {
  RCTBrightcoveViewHandleCommand(self, commandName, args);
}

+ (ComponentDescriptorProvider)componentDescriptorProvider {
  return concreteComponentDescriptorProvider<BrightcoveViewComponentDescriptor>();
}

@end
