#import "PXCSStoryController.h"
#import "NSData+Fetch.h"
#import <Highlightr/Highlightr.h>
#import "UIColor+BackgroundColor.h"

@implementation PXCSStoryController {
  NSArray *_frames;
  NSTimer *_timer;
  NSUInteger _index;
  UITextView *_codeView;
  NSString *_originalCode;
  NSString *_language;
  NSMutableString *_currentCode;
}

static Highlightr *highlighter;

+ (void)load {
  if (self == [PXCSStoryController class]) {
    highlighter = [[Highlightr alloc] initWithThemeString:@"vs2015"];
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  [_timer invalidate];
  _timer = nil;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)showNextFrame:(id)sender {
  if (++_index >= _frames.count) {
    _index = 0;
    _currentCode = [_originalCode mutableCopy];
  }
  for (NSArray *change in _frames[_index]) {
    [_currentCode
      replaceCharactersInRange:NSMakeRange(
        [(NSNumber *)(change[0]) unsignedIntegerValue],
        [(NSNumber *)(change[1]) unsignedIntegerValue]
      )
      withString:change[2]
    ];
  }
  _codeView.attributedText = [highlighter
    highlight:_currentCode
    as:_language
    fastRender:YES
  ];
}

- (instancetype)initWithData:(NSDictionary *)dict {
  if ((self = [super init])) {  
    self.title = [NSString stringWithFormat:@"%@'s Story",
      dict[@"creatorUsername"]
    ];
    self.view.backgroundColor = [UIColor stories_backgroundColor];

    _codeView = [UITextView new];
    _codeView.hidden = YES;
    _codeView.editable = NO;
    _codeView.backgroundColor = [UIColor blackColor];
    _codeView.translatesAutoresizingMaskIntoConstraints = NO;
    _codeView.alwaysBounceVertical = YES;

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
    [self.view addSubview:_codeView];
    [self.view addSubview:errorLabel];

    [self.view addConstraints:@[
      [_codeView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor],
      [_codeView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor],
      [_codeView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
      [_codeView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
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
      NSLog(@"Data: %@", data);
      NSLog(@"JSON: %@", dict);
      dict = [dict isKindOfClass:[NSDictionary class]] ? dict[@"story"] : nil;
      NSLog(@"Inner dictionary: %@", dict);
      BOOL success = NO;
      if (
        [dict isKindOfClass:[NSDictionary class]] &&
        [dict[@"text"] isKindOfClass:[NSString class]] &&
        [dict[@"programmingLanguageId"] isKindOfClass:[NSString class]] &&
        [dict[@"numLikes"] isKindOfClass:[NSNumber class]]
      ) {
        // Parse the JSON and create each frame of the animation.
        if ([dict[@"recordingSteps"] isKindOfClass:[NSArray class]]) {
          NSUInteger frameCount = 0;
          for (NSArray *step in dict[@"recordingSteps"]) {
            if (
              (step.count < 2) ||
              (![step[0] isKindOfClass:[NSNumber class]]) ||
              (![step[1] isKindOfClass:[NSArray class]])
            ) {
              NSLog(@"Invalid step: %@", step);
              frameCount = 0;
              break;
            }
            NSUInteger newFrameCount = (
              ([(NSNumber *)(step[0]) unsignedIntegerValue] / 50) +
              !!([(NSNumber *)(step[0]) unsignedIntegerValue] % 50)
            );
            if (newFrameCount > frameCount) {
              frameCount = newFrameCount;
            }
          }
          NSLog(@"Final frame count: %lu", (unsigned long)frameCount);
          if (frameCount) {
            frameCount += 20; // Extra second
            NSMutableArray *frames = [NSMutableArray arrayWithCapacity:frameCount];
            for (NSUInteger i=0; i<frameCount; i++) {
              @autoreleasepool {
                NSMutableArray *changes = [NSMutableArray arrayWithCapacity:[dict[@"recordingSteps"] count]];
                for (NSArray *step in dict[@"recordingSteps"]) {
                  // "step" value is verified in the previous loop
                  if (
                    ([(NSNumber *)(step[0]) unsignedIntegerValue] >= (i * 50)) &&
                    ([(NSNumber *)(step[0]) unsignedIntegerValue] < ((i+1) * 50))
                  ) {
                    for (NSDictionary *change in step[1]) {
                      if (
                        ![change isKindOfClass:[NSDictionary class]] ||
                        ![change[@"rangeOffset"] isKindOfClass:[NSNumber class]] ||
                        ![change[@"rangeLength"] isKindOfClass:[NSNumber class]] ||
                        ![change[@"text"] isKindOfClass:[NSString class]]
                      ) {
                        frames = (id)@[];
                        break;
                      }
                      [changes addObject:@[
                        change[@"rangeOffset"],
                        change[@"rangeLength"],
                        change[@"text"]
                      ]];
                    }
                  }
                  if (![frames isKindOfClass:[NSMutableArray class]]) break;
                }
                if (![frames isKindOfClass:[NSMutableArray class]]) break;
                [frames addObject:changes.copy];
              }
            }
            _frames = frames.copy;
          }
          else {
            _frames = @[];
          }
        }
        _originalCode = dict[@"text"];
        success = YES;
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        [indicator removeFromSuperview];
        if (success) {
          _codeView.attributedText = [highlighter
            highlight:dict[@"text"]
            as:dict[@"programmingLanguageId"]
            fastRender:YES
          ];
          self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:[NSString stringWithFormat:@"%@ Likes", dict[@"numLikes"]]
            style:UIBarButtonItemStylePlain
            target:nil
            action:nil
          ];
          [errorLabel removeFromSuperview];
          _codeView.hidden = NO;
          if (_frames.count > 1) {
            _index = _frames.count-1;
            _language = dict[@"programmingLanguageId"];
            _timer = [NSTimer
              timerWithTimeInterval:(50.0/1000.0)
              target:self
              selector:@selector(showNextFrame:)
              userInfo:nil
              repeats:YES
            ];
            [[NSRunLoop mainRunLoop]
              addTimer:_timer
              forMode:NSRunLoopCommonModes
            ];
          }
        }
        else {
          [_codeView removeFromSuperview];
          errorLabel.hidden = NO;
        }
      });
    }];
  }
  return self;
}

@end