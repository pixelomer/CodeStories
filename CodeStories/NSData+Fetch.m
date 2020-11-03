#import "NSData+Fetch.h"

@implementation NSData(Fetch)

+ (void)fetchDataAtURL:(NSURL *)URL completionHandler:(void(^)(NSData *))handler {
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
  request.cachePolicy = NSURLRequestReloadRevalidatingCacheData;
  [[[NSURLSession sharedSession]
    downloadTaskWithRequest:request
    completionHandler:^(NSURL *location, id _response, id error){
      NSHTTPURLResponse *response = _response;
      if (!error && (response.statusCode == 200)) {
        handler([NSData dataWithContentsOfURL:location]);
      }
      else {
        handler(nil);
      }
    }
  ] resume];
}

@end