//
//  TFPhotoAlbumWriter.m
//  VideoGather
//
//  Created by shiwei on 17/9/6.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFPhotoAlbumWriter.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

@interface TFPhotoAlbumWriter ()<UIAlertViewDelegate>

@end

@implementation TFPhotoAlbumWriter

+(instancetype)shareInstance{
    static TFPhotoAlbumWriter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TFPhotoAlbumWriter alloc] init];
    });
    
    return instance;
}

-(BOOL)writeAssertToPhotoAlbumFrom:(NSString *)path{
//    if( [ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusNotDetermined){
////        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"photo album isn't authrized, do you wang to authrize it?" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes"  , nil];
//        return NO;
//    }
    
    ALAssetsLibrary *assertLib = [[ALAssetsLibrary alloc] init];
    [assertLib writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:path] completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            NSLog(@"write video (%@) to photos album error:%@",path, error);
        }
    }];
    
    return YES;
}

@end
