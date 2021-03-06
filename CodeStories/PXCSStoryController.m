#import "PXCSStoryController.h"
#import "NSData+Fetch.h"
#import <Highlightr/Highlightr.h>
#import "UIColor+BackgroundColor.h"

@implementation PXCSStoryController {
  NSArray<NSArray *> *_frames;
  NSTimer *_timer;
  NSUInteger _index;
  UITextView *_codeView;
  NSString *_originalCode;
  NSAttributedString *_lastFrame;
  UIView *_progressView;
  NSString *_language;
  NSAttributedString *_previousFrame;
  NSMutableString *_currentCode;
  BOOL _paused;
  int _speed;
  int _frameCounter;
}

static Highlightr *_highlighter;

+ (NSArray<UIBarButtonItem *> *)centeredTextForToolbar:(NSString *)text {
  NSArray<UIBarButtonItem *> *items = @[
    [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
      target:nil
      action:nil
    ],
    [[UIBarButtonItem alloc]
      initWithTitle:text
      style:UIBarButtonItemStylePlain
      target:nil
      action:nil
    ],
    [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
      target:nil
      action:nil
    ]
  ];
  if (@available(iOS 13.0, *)) {
    items[1].tintColor = [UIColor labelColor];
  }
  else {
    items[1].tintColor = [UIColor blackColor];
  }
  items[1].enabled = NO;
  return items;
}

+ (void)load {
  if (self == [PXCSStoryController class]) {
    _highlighter = [[Highlightr alloc] initWithThemeString:@"vs2015"];
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

- (void)changeSpeed:(id)sender {
  if (_speed == 4) {
    _speed = 1;
  }
  else {
    _speed *= 2;
  }
  [self updateToolbarItems];
}

- (UIBarButtonItem *)speedButton {
  return [[UIBarButtonItem alloc]
    initWithTitle:[NSString stringWithFormat:@"%dx", _speed]
    style:UIBarButtonItemStylePlain
    target:self
    action:@selector(changeSpeed:)
  ];
}

- (UIBarButtonItem *)pauseResumeButton {
  return [[UIBarButtonItem alloc]
    initWithTitle:(_paused ? @"Resume" : @"Pause")
    style:UIBarButtonItemStylePlain
    target:self
    action:@selector(togglePauseResume:)
  ];
}

// Recordings are assumed to be less than an hour long.
- (UIBarButtonItem *)currentFrameButton {
  unsigned long secondsRemaining = (_frames.count - _index) / 20;
  UIBarButtonItem *button = [[UIBarButtonItem alloc]
    initWithTitle:[NSString
      stringWithFormat:@"-%02lu:%02lu",
      (secondsRemaining / 60) % 60,
      secondsRemaining % 60
    ]
    style:UIBarButtonItemStylePlain
    target:nil
    action:nil
  ];
  if (@available(iOS 13.0, *)) {
    button.tintColor = [UIColor labelColor];
  }
  else {
    button.tintColor = [UIColor blackColor];
  }
  button.enabled = NO;
  return button;
}

- (void)updateToolbarItems {
  self.toolbarItems = @[
    [self pauseResumeButton],
    [self speedButton],
    (
      (self.toolbarItems.count > 2) ?
      self.toolbarItems[2] :
      [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
        target:nil
        action:nil
      ]
    ),
    [self currentFrameButton]
  ];
}

- (void)togglePauseResume:(id)sender {
  _paused = !_paused;
  if (sender) {
    [self updateToolbarItems];
  }
}

- (void)resetAnimation {
  _index = 0;
  _lastFrame = nil;
  _currentCode = [_originalCode mutableCopy];
}

- (void)showNextFrame:(id)sender {
  if (_paused) return;
  if (++_frameCounter >= (4 / _speed)) _frameCounter = 0;
  else return;
  if (++_index >= _frames.count) {
    [self resetAnimation];
    [self updateToolbarItems];
  }
  if (_frames[_index].count || !_lastFrame) {
    for (NSArray *change in _frames[_index]) {
      NSRange range = NSMakeRange(
        [(NSNumber *)(change[0]) unsignedIntegerValue],
        [(NSNumber *)(change[1]) unsignedIntegerValue]
      );
      if ((range.location + range.length) > _currentCode.length) {
        [_timer invalidate];
        _timer = nil;
        _paused = YES;
        self.toolbarItems = [self.class centeredTextForToolbar:@"Playback error"];
        return;
      }
      [_currentCode
        replaceCharactersInRange:range
        withString:change[2]
      ];
    }
    _lastFrame = [_highlighter
      highlight:_currentCode
      as:_language
      fastRender:YES
    ];
  }
  _codeView.attributedText = _lastFrame;
  if ((_index % 20) == 19) {
    [self updateToolbarItems];
  }
}

- (instancetype)initWithData:(NSDictionary *)dict {
  if ((self = [super init])) {  
    _speed = 1;
    _frameCounter = 0;
    self.title = [NSString stringWithFormat:@"%@",
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
      stringWithFormat:@"https://vscode-stories-295306.uk.r.appspot.com/text-story/%@",
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
                    if (![frames isKindOfClass:[NSMutableArray class]]) break;
                  }
                }
                if (![frames isKindOfClass:[NSMutableArray class]]) {
                  break;
                }
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
          _codeView.attributedText = [_highlighter
            highlight:dict[@"text"]
            as:dict[@"programmingLanguageId"]
            fastRender:YES
          ];
          self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:[NSString stringWithFormat:@"%@ Like%@",
              dict[@"numLikes"],
              [dict[@"numLikes"] isEqual:@(1)] ? @"" : @"s"
            ]
            style:UIBarButtonItemStylePlain
            target:nil
            action:nil
          ];
          [errorLabel removeFromSuperview];
          _codeView.hidden = NO;
          if (_frames.count > 1) {
            _language = dict[@"programmingLanguageId"];
            [self resetAnimation];
            [self updateToolbarItems];
            _timer = [NSTimer
              timerWithTimeInterval:(12.5/1000.0)
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
          else {
            self.toolbarItems = [self.class centeredTextForToolbar:@"No playback available"];
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