//
//  TFVideoPlayerControls.h
//  VideoGather
//
//  Created by shiwei on 17/9/1.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TFVideoControlView;
@protocol TFVideoControlViewControlDelegate <NSObject>

-(void)play;
-(void)pause;


@optional
-(void)next;
-(void)pre;
-(void)goForwardWithTimeInterval:(NSTimeInterval)interval;
-(void)goBackWithTimeInterval:(NSTimeInterval)interval;
-(void)skipToTime:(NSTimeInterval)time;
-(void)skipToProgress:(float)progress;
-(void)changePlayRate:(float)rate; //TODO:负值倒放？

@end

@protocol TFVideoControlViewScreenDelegate <NSObject>

-(void)extendToFullScreen;
-(void)shrinkFromFullScreen;

@end



/**
 * this is a abstract class, please subclass it and add many real controls.
 * But you should only use TFVideoPlayerControlsDelegate to control video player, don't access player directly.
 * player controls ---> control forwarder ---> video Player
 */
@interface TFVideoControlView : UIView

@property (nonatomic, weak) id<TFVideoControlViewControlDelegate> controlDelegate;

@property (nonatomic, weak) id<TFVideoControlViewScreenDelegate> screenDelegate;

//just UI change
-(void)UIChangeByplay;
-(void)UIChangeBypause;
-(void)UIChangeByGetDuration:(NSTimeInterval)duration;
-(void)UIChangeByUpdateCurTime:(NSTimeInterval)curTime;

@end
