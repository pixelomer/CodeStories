#import "PXCSStoriesController.h"
#import "PXCSStoryCell.h"
#import "UIColor+BackgroundColor.h"
#import "PXCSStoryController.h"
#import "NSData+Fetch.h"

@implementation PXCSStoriesController {
	BOOL _isReloadingStories;
	BOOL _hasMore;
	unsigned int _index;
	NSArray<NSDictionary *> *_cells;
	NSUInteger _counter;
}

- (void)openTwitter {
	[[UIApplication sharedApplication]
		openURL:[NSURL URLWithString:@"https://twitter.com/pixelomer"]
	];
}

- (void)reloadAll {
	_counter++;
	_index = 0;
	_hasMore = YES;
	_isReloadingStories = NO;
	_cells = @[];
	[self.collectionView reloadData];
	[self loadMore];
}

- (void)loadMore {
	NSUInteger counter = _counter;

	// If done loading, stop
	if (!_hasMore) return;

	// This method is only called from the main thread.
	// Thread safety is not an issue.
	if (_isReloadingStories) return;
	_isReloadingStories = YES;

	// Start fetching new cells.
	__block BOOL hasMore = _hasMore;
	__block unsigned int index = _index;
	NSMutableArray *newCells = [_cells mutableCopy];
	NSUInteger oldCount = _cells.count;
	NSURL *URL = [NSURL URLWithString:[NSString
		stringWithFormat:@"https://bowl.azurewebsites.net/stories/hot/%u",
		index
	]];
	[NSData fetchDataAtURL:URL completionHandler:^(NSData *data){
		// Fail without any state changes if null
		if (!data) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (_counter == counter) {
					_isReloadingStories = NO;
				}
			});
			return;
		}

		// Parse the returned JSON
		NSDictionary *dictionary = [NSJSONSerialization
			JSONObjectWithData:data
			options:0
			error:nil
		];
		if ([dictionary[@"hasMore"] isKindOfClass:[NSNumber class]] && [dictionary[@"stories"] isKindOfClass:[NSArray class]]) {
			hasMore = [dictionary[@"hasMore"] boolValue];
			for (NSDictionary *story in dictionary[@"stories"]) {
				// Check dictionary's contents and data
				if (
					![story isKindOfClass:[NSDictionary class]] ||
					![story[@"mediaId"] isKindOfClass:[NSString class]] ||
					![story[@"id"] isKindOfClass:[NSString class]] ||
					![story[@"creatorUsername"] isKindOfClass:[NSString class]] ||
					![story[@"numLikes"] isKindOfClass:[NSNumber class]]
				) continue;

				// Filter
				if ([story[@"creatorUsername"] isEqualToString:@"bbeenniiee"]) {
					continue;
				}

				// Add the dictionary to the cells array
				[newCells addObject:story];
			}
		}
		else {
			hasMore = NO;
		}
		index++;

		// Get back to the main thread and store the new cells
		dispatch_sync(dispatch_get_main_queue(), ^{
			if (_counter == counter) {
				_hasMore = hasMore;
				_index = index;
				_cells = newCells.copy;
				_isReloadingStories = NO;
				[self.collectionView
					performBatchUpdates:^{
						for (NSUInteger i=oldCount; i<_cells.count; i++) {
							[self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath
								indexPathForItem:i
								inSection:0
							]]];
						}
					}
					completion:nil
				];
			}
		});
	}];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
	numberOfItemsInSection:(NSInteger)section
{
	return _cells.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (PXCSStoryCell *)collectionView:(UICollectionView *)collectionView 
	cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	PXCSStoryCell *cell = [collectionView
		dequeueReusableCellWithReuseIdentifier:@"cell"
  	forIndexPath:indexPath
	];
	cell.data = _cells[indexPath.item];
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView
	didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	UIViewController *vc = [[PXCSStoryController alloc] initWithData:_cells[indexPath.item]];
	[self.navigationController
		pushViewController:vc
		animated:YES
	];
}

- (void)collectionView:(UICollectionView *)collectionView 
  willDisplayCell:(UICollectionViewCell *)cell 
  forItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.item >= ((NSInteger)_cells.count - 10)) {
		[self loadMore];
  }
}

- (instancetype)init {
	UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
	layout.estimatedItemSize = CGSizeMake(165, 165);
	if ((self = [super initWithCollectionViewLayout:layout])) {
		self.tabBarItem = [[UITabBarItem alloc]
			initWithTabBarSystemItem:UITabBarSystemItemFeatured
			tag:0
		];
		self.collectionView.backgroundColor =
			self.view.backgroundColor =
			[UIColor stories_backgroundColor];
		[self.collectionView
			registerClass:[PXCSStoryCell class]
			forCellWithReuseIdentifier:@"cell"
		];
		self.title = @"Stories";
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
			initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
			target:self
			action:@selector(reloadAll)
		];
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
      initWithTitle:@"@pixelomer"
      style:UIBarButtonItemStylePlain
      target:self
      action:@selector(openTwitter)
    ];
		[self reloadAll];
	}
	return self;
}

@end
