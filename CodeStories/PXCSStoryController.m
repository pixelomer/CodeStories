#import "PXCSStoryController.h"
#import "NSData+Fetch.h"
#import <Highlightr/Highlightr.h>
#import "UIColor+BackgroundColor.h"

@implementation PXCSStoryController {
  NSArray *frames;
}

static Highlightr *highlighter;

+ (void)load {
  if (self == [PXCSStoryController class]) {
    highlighter = [[Highlightr alloc] initWithThemeString:@"vs2015"];
  }
}

- (instancetype)initWithData:(NSDictionary *)dict {
  if ((self = [super init])) {  
    self.title = [NSString stringWithFormat:@"%@'s Story",
      dict[@"creatorUsername"]
    ];
    self.view.backgroundColor = [UIColor stories_backgroundColor];

    UITextView *codeView = [UITextView new];
    codeView.hidden = YES;
    codeView.backgroundColor = [UIColor blackColor];
    codeView.translatesAutoresizingMaskIntoConstraints = NO;
    codeView.alwaysBounceVertical = YES;

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
    [self.view addSubview:codeView];
    [self.view addSubview:errorLabel];

    [self.view addConstraints:@[
      [codeView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
      [codeView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor],
      [codeView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
      [codeView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
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
      stringWithFormat:@"https://bowl.azurewebsites.net/text-story/%@",
      dict[@"id"]
    ]] completionHandler:^(NSData *data){
      NSDictionary *dict = nil;
      if (data) {
        dict = [NSJSONSerialization
          JSONObjectWithData:data
          options:0
          error:nil
        ];
      }
      NSAttributedString *highlighted = nil;
      dict = [dict isKindOfClass:[NSDictionary class]] ? dict[@"story"] : nil;
      if (
        [dict isKindOfClass:[NSDictionary class]] &&
        [dict[@"text"] isKindOfClass:[NSString class]] &&
        [dict[@"programmingLanguageId"] isKindOfClass:[NSString class]] &&
        [dict[@"numLikes"] isKindOfClass:[NSNumber class]]
      ) {
        highlighted = [highlighter
          highlight:dict[@"text"]
          as:dict[@"programmingLanguageId"]
          fastRender:YES
        ];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        [indicator removeFromSuperview];
        if (highlighted) {
          self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:[NSString stringWithFormat:@"%@ Likes", dict[@"numLikes"]]
            style:UIBarButtonItemStylePlain
            target:nil
            action:nil
          ];
          [errorLabel removeFromSuperview];
          codeView.attributedText = highlighted;
          codeView.hidden = NO;
        }
        else {
          [codeView removeFromSuperview];
          errorLabel.hidden = NO;
        }
      });
    }];
  }
  return self;
}

@end