#import "UIColor+BackgroundColor.h"

@implementation UIColor(BackgroundColor)

+ (instancetype)stories_backgroundColor {
  if (@available(iOS 13.0, *)) {
    return [UIColor systemBackgroundColor];
  }
  else {
    return [UIColor whiteColor];
  }
}

@end