#import "PXCSStoryCell.h"
#import "NSData+Fetch.h"

#define min(x,y) ((x>y)?y:x)
#define max(x,y) ((x>y)?x:y)

@implementation PXCSStoryCell {
  UIImageView *_imageView;
  UILabel *_nameLabel;
  UILabel *_imageLabel;
  UIImageView *_flairView;
}

static NSDictionary *_flairs;

+ (void)load {
  if (self == [PXCSStoryCell class]) {
    _flairs = @{
      @"react" : [UIImage imageNamed:@"flair_react"],
      @"angular" : [UIImage imageNamed:@"flair_angular"],
      @"vue" : [UIImage imageNamed:@"flair_vue"],
      @"flutter" : [UIImage imageNamed:@"flair_flutter"]
    };
  }
}

- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    _imageView = [UIImageView new];
    _flairView = [UIImageView new];
    _imageLabel = [UILabel new];
    _nameLabel = [UILabel new];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _imageLabel.textAlignment = NSTextAlignmentCenter;
    _imageLabel.textColor = [UIColor whiteColor];
    _imageView.backgroundColor = [UIColor blackColor];
    _imageView.clipsToBounds = YES;
    [self.contentView addSubview:_imageView];
    [self.contentView addSubview:_nameLabel];
    [self.contentView addSubview:_imageLabel];
    [self.contentView addSubview:_flairView];
  }
  return self;
}

- (void)layoutSubviews {
  CGFloat imageSize = min(self.frame.size.width - 20.0, self.frame.size.height - 45.0);
  CGFloat imageX = (self.frame.size.width / 2.0) - (imageSize / 2.0);
  _imageView.layer.cornerRadius = imageSize / 2.0;
  _imageView.frame = CGRectMake(
    imageX,
    10.0,
    imageSize,
    imageSize
  );
  _nameLabel.frame = CGRectMake(
    imageX,
    10.0 + imageSize + 5.0,
    imageSize,
    20.0
  );
  _imageLabel.frame = CGRectMake(
    imageX,
    10.0 + (imageSize / 4.0),
    imageSize,
    (imageSize / 2.0)
  );
  _flairView.frame = CGRectMake(
    imageX + ((imageSize / 4.0) * 3),
    10.0 + ((imageSize / 4.0) * 3),
    imageSize / 4.0,
    imageSize / 4.0
  );
  _imageLabel.font = [UIFont boldSystemFontOfSize:imageSize / 2.0];
}

- (void)prepareForReuse {
  [super prepareForReuse];
  _imageView.image = nil;
  _flairView.image = nil;
  _imageLabel.hidden = NO;
}

- (void)setData:(NSDictionary *)data {
  [NSData
    fetchDataAtURL:[NSURL URLWithString:data[@"creatorAvatarUrl"]]
    completionHandler:^(NSData *receivedData){
      UIImage *image = receivedData ? [UIImage imageWithData:receivedData] : nil;
      if (image) dispatch_async(dispatch_get_main_queue(), ^{
        if (data != _data) return;
        _imageView.image = image;
        [_imageView setNeedsDisplay];
        _imageLabel.hidden = YES;
      });
    }
  ];
  _nameLabel.text = data[@"creatorUsername"];
  _flairView.image = (
    [data[@"flair"] isKindOfClass:[NSString class]] ?
    _flairs[data[@"flair"]] :
    nil
  );
  _imageLabel.text = [[data[@"creatorUsername"] substringWithRange:NSMakeRange(0,1)] uppercaseString];
  srand([data[@"creatorUsername"] hash]);
  _imageView.backgroundColor = [UIColor
    colorWithRed:(0.25 + ((CGFloat)(rand() % 500) / 1000.0))
    green:(0.25 + ((CGFloat)(rand() % 500) / 1000.0))
    blue:(0.25 + ((CGFloat)(rand() % 500) / 1000.0))
    alpha:1.0
  ];
  _data = data;
}

@end