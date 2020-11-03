#import <Foundation/Foundation.h>

@interface NSData(Fetch)
+ (void)fetchDataAtURL:(NSURL *)URL completionHandler:(void(^)(NSData *))handler;
@end