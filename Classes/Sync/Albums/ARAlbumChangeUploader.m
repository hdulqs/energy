#import <AFNetworking/AFNetworking.h>

#import "ARAlbumArtworksDownloader.h"
#import "ARRouter.h"
#import "AlbumEdit.h"
#import "ARAlbumEditOperation.h"
#import "ARAlbumChangeUploader.h"


@interface ARAlbumChangeUploader ()
@property (nonatomic, strong, readonly) NSManagedObjectContext *context;
@end


@implementation ARAlbumChangeUploader

- (instancetype)initWithContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (!self) {
        return nil;
    }

    _context = context;

    return self;
}

- (void)operationTree:(DRBOperationTree *)tree objectsForObject:(NSString *)partnerID completion:(void (^)(NSArray *))completion
{
    NSArray *albumEdits = [AlbumEdit findAllSortedBy:@"createdAt" ascending:YES inContext:self.context];
    NSArray *albumsPlusEndingSentinel = [albumEdits arrayByAddingObject:[NSNull null]];
    completion(albumsPlusEndingSentinel);
}

- (NSOperation *)operationTree:(DRBOperationTree *)node
            operationForObject:(AlbumEdit *)albumUpload
                  continuation:(void (^)(id, void (^)()))continuation
                       failure:(void (^)())failure
{
    if ([albumUpload isEqual:[NSNull null]]) {
        NSBlockOperation *noopOperation = [[NSBlockOperation alloc] init];

        noopOperation.completionBlock = ^{
            continuation([NSNull null], nil);
        };

        return noopOperation;
    } else {
        ARAlbumEditOperation *operation = [[ARAlbumEditOperation alloc] initWithAlbum:albumUpload.album createModel:albumUpload.albumWasCreated.boolValue toAdd:albumUpload.addedArtworks toRemove:albumUpload.removedArtworks];

        operation.onCompletion = ^() {
            [albumUpload deleteInContext:albumUpload.managedObjectContext];
            continuation(nil, nil);
        };

        return operation;
    }
}

@end
