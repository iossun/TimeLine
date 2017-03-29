//
//  MNTimeLineView.h
//  实验
//
//  Created by 蛮牛科技 on 16/10/8.
//  Copyright © 2016年 孙慕. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MNTimeLine.h"
#import "MNRectDate.h"
#define timelineW 60


typedef NS_ENUM(NSUInteger, MNAlarmevent) {
    
    // 普通录制
    MNREC = 0x00,
    // 移动侦测
    MNAlarmeventMove = 0x01,
    // 视频遮挡
    MNAlarmeventCovert = 0x02,
    // 外部报警（外接传感器）
    MNAlarmeventExtern = 0x04,
    // 人群检测
    MNAlarmeventStaff = 0x08,
    // 车辆检测
    MNAlarmeventVehicle = 0x10,
    // 区域检测
    MNAlarmeventArea = 0x20,
    
    // 移盗报警
    MNAlarmeventShift = 0x40,
    // 本地报警
    MNAlarmeventLocal = 0x80
};

@protocol MNTimeLineTimeDelegate <NSObject>

-(void)MNTimeLinePresentTime:( NSDate * _Nonnull )time;
- (void)scrollViewWillBegin;
-(void)touchViewEnd;


@end

@interface MNTimeLineView : UIView

@property (nonatomic,weak,null_unspecified) id< MNTimeLineTimeDelegate > delegate;


@property (nonatomic,strong,nonnull) UILabel *timeLabel;                                // 时间轴上指示时间的label
@property (nonatomic,strong,nonnull) UIView *updateView;                                // 更新时间轴动画的View

-(void)stopUpdateAnimation;
-(void)startUpdateAnimation;
-(void)setTimeLineWithDate:(nonnull NSDate * )date;
//报警标注区域
-(void)joinDrawTimeLineRectWithStart:(NSDate *_Nonnull)start stop:(NSDate *_Nonnull)stop alarmevent:(MNAlarmevent)event;
-(void)updateTimeline;
-(void)removeAllRect;
@end
