#import "PXCSAppDelegate.h"
#import "PXCSStoriesController.h"

@implementation PXCSAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	NSLog(@"Finished launching");
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	_rootViewController = [UITabBarController new];
	_rootViewController.viewControllers = @[
		[[UINavigationController alloc] initWithRootViewController:[PXCSStoriesController new]]
	];
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}

@end
