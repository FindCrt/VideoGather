//
//  TFMediaListViewController.m
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import "TFMediaListViewController.h"
#import "TFMediaDataAnalyzer.h"
#import "TFMediaCell.h"
//#import "TFVideoPlayerViewController.h"
@import MobileCoreServices;

static NSString *mediaCellIdentifier = @"MediaCell";

@interface TFMediaListViewController ()<UITableViewDelegate, UITableViewDataSource, TFMediaCellDelegate>{
    NSMutableArray<TFMediaData *> *_mediaItems;
    
    UITableView *_tableView;
}

@end

@implementation TFMediaListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mediaItems = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"clear" style:(UIBarButtonItemStylePlain) target:self action:@selector(clear)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    [self loadMediaItems];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:(UITableViewStyleGrouped)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[TFMediaCell class] forCellReuseIdentifier:mediaCellIdentifier];
    [self.view addSubview:_tableView];
}

-(void)loadMediaItems{
    NSError *error = nil;
    NSArray *items = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:self.mediaDir] includingPropertiesForKeys:nil options:0 error:&error];
    if (error) {
        NSLog(@"fetch contents at (%@) error:\n%@",self.mediaDir, error);
        return;
    }
    for (NSURL *item in items) {
        NSString *extension = [item pathExtension];
        if ([preferredUTIForExtention(extension) isEqualToString:@"public.mpeg-4"]) {
            TFMediaData *mediaData = [TFMediaDataAnalyzer mediaDataForItemAt:[item path]];
            [_mediaItems addObject:mediaData];
        }else{
            TFMediaData *mediaData = [TFMediaDataAnalyzer mediaDataForItemAt:[item path]];
            [_mediaItems addObject:mediaData];
        }
    }
    
    [_tableView reloadData];
}

#pragma mark - tableview

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _mediaItems.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TFMediaCell *cell = [tableView dequeueReusableCellWithIdentifier:mediaCellIdentifier];
    
    cell.media = _mediaItems[indexPath.row];
    cell.delegate = self;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    TFMediaData *media = _mediaItems[indexPath.row];
    return [TFMediaCell heightForMedia:media];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.selectHandler) {
        self.selectHandler(_mediaItems[indexPath.row]);
    }
}

NSString *preferredUTIForExtention(NSString *ext)
{
    //Request the UTI via the file extension
    NSString *theUTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)(ext), NULL);
    return theUTI;
}

NSString *preferredUTIForMIMEType(NSString *mime)
{
    //request the UTI via the file extention
    NSString *theUTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType,(__bridge CFStringRef)mime, NULL);
    return theUTI;
}

#pragma mark - cell delegate

-(void)mediaCell:(TFMediaCell *)cell deleteMedia:(TFMediaData *)media{
    if ([[NSFileManager defaultManager] fileExistsAtPath:media.filePath]) {
        
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:media.filePath error:&error];
        
        if (error) {
            NSLog(@"delete media file at (%@) error:\n%@",media.filePath, error);
        }
        
        [_mediaItems removeObject:media];
        
        [_tableView reloadData];
    }
}

-(void)mediaCell:(TFMediaCell *)cell shareMedia:(TFMediaData *)media{
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:media.filePath]] applicationActivities:nil];
    activity.excludedActivityTypes = @[UIActivityTypeAirDrop];
    
    [self presentViewController:activity animated:YES completion:NULL];
}

-(void)clear{
    
    NSError *error = nil;
    for (TFMediaData *media in _mediaItems) {
        [[NSFileManager defaultManager]removeItemAtPath:media.filePath error:&error];
        if (error) {
            NSLog(@"delete media file at (%@) error:\n%@",media.filePath, error);
        }
    }
    
    [_mediaItems removeAllObjects];
    [_tableView reloadData];
}

@end
