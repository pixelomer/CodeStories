#import "PXCSStoryController.h"
#import "FLAnimatedImage/FLAnimatedImage.h"
#import "FLAnimatedImage/FLAnimatedImageView.h"
#import "NSData+Fetch.h"
#import "UIColor+BackgroundColor.h"

@implementation PXCSStoryController

- (instancetype)initWithData:(NSDictionary *)dict {
  if ((self = [super init])) {  
    self.title = [NSString stringWithFormat:@"%@'s Story",
      dict[@"creatorUsername"]
    ];
    self.view.backgroundColor = [UIColor stories_backgroundColor];

    FLAnimatedImageView *imageView = [FLAnimatedImageView new];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    UIActivityIndicatorViewStyle style;
    if (@available(iOS 13.0, *)) {
      style = UIActivityIndicatorViewStyleMedium;
    }
    else {
      style = UIActivityIndicatorViewStyleGray;
    }
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:style
    ];
    indicator.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *errorLabel = [UILabel new];
    errorLabel.text = @"Could not load this story.";
    errorLabel.hidden = YES;
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:indicator];
    [self.view addSubview:imageView];
    [self.view addSubview:errorLabel];

    [self.view addConstraints:@[
      [imageView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
      [imageView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor],
      [imageView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
      [imageView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
      [indicator.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
      [indicator.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor],
      [indicator.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
      [indicator.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
      [errorLabel.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
      [errorLabel.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor],
      [errorLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
      [errorLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor]
    ]];
    [indicator startAnimating];
    [NSData fetchDataAtURL:[NSURL URLWithString:[NSString
      stringWithFormat:@"https://teriyaki.azureedge.net/main/%@",
      dict[@"mediaId"]
    ]] completionHandler:^(NSData *data){
      dispatch_async(dispatch_get_main_queue(), ^{
        [indicator removeFromSuperview];
        imageView.animatedImage = data ? [FLAnimatedImage animatedImageWithGIFData:data] : nil;
        if (!imageView.animatedImage) {
          [imageView removeFromSuperview];
          errorLabel.hidden = NO;
        }
        else {
          [errorLabel removeFromSuperview];
        }
      });
    }];
  }
  return self;
}

@end