//
//  MNTimeLineView.m
//  实验
//
//  Created by 蛮牛科技 on 16/10/8.
//  Copyright © 2016年 孙慕. All rights reserved.
//

#import "MNTimeLineView.h"
#import "MNDrawRect.h"
#define kWinH [UIScreen mainScreen].bounds.size.height
#define kWinW [UIScreen mainScreen].bounds.size.width
#define totalDay 7
#define MNColorA(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)/255.0]
#define MNColor(r, g, b) MNColorA((r), (g), (b), 255)
#define changeBase 1440



@interface MNTimeLineView()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic,strong,nonnull) NSMutableArray *rectDateArray;                    // 报警区域的数组

// 关于时间轴的属性
@property (nonatomic,nullable,strong) UIPinchGestureRecognizer *PinchGestureRecognizer;    // 放大手势
@property (nonatomic,assign) float CellWidth;                                              // 一天的View的宽度
@property (nonatomic,assign) float unitTime;                                    // 每隔对应的时间
@property (nonatomic,assign) float unitLength;                                  // 每隔对应的长度
@property (nonatomic,assign) float maxContentOffsetX;                           // 时间最大偏移量（当前时间）
@property (nonatomic,assign) float minContentOffsetX;                           // 时间轴最小偏移量（七天前）
@property (nonatomic,strong,nonnull) MNTimeLine *timeLine;                              // 绘图的View
@property (nonatomic,strong,nonnull) UICollectionView *MNTimeLineCollction;             // View加在collction实现重用
@property (nonatomic,assign) float addX;
//@property (nonatomic,strong,nonnull) NSMutableArray *playBacklistArray;
@property (nonatomic,assign) float videoX;                                      // 放大时标记可视区域，不断重绘时只绘制可视区域，最后绘制完整一次
@property (nonatomic,assign) BOOL endDrawRect;                                  // 区分是否是最后一次
@property (nonatomic,assign) int updateRow;                                     // 报警区域是否画上去
@property (strong, nonatomic,nonnull) NSDateFormatter           *dateFormat;
// 时间转换
@property (nonatomic,strong,nonnull)NSCalendar *calendar;
@property (nonatomic,strong,nonnull)NSDateComponents *comps;

@property (nonatomic,strong) NSMutableArray *rectangleArray;                    // 报警区域的数组

//@property (nonatomic,strong,nonnull) NSDate *moveDate;

@end
@implementation MNTimeLineView


-(NSMutableArray *)rectangleArray{
    if (!_rectangleArray) {
        _rectangleArray = [NSMutableArray array];
    }
    return _rectangleArray;
}

-(NSMutableArray *)rectDateArray{
    if (!_rectDateArray) {
        _rectDateArray = [NSMutableArray array];
    }
    return _rectDateArray;
}

-(NSDateFormatter *)dateFormat{
    if (!_dateFormat) {
        _dateFormat = [[NSDateFormatter alloc] init];
        //        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        //        [_dateFormat setTimeZone:timeZone];
        [_dateFormat setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
        
    }
    return _dateFormat;
}
-(NSCalendar *)calendar{
    if (!_calendar) {
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    }
    return _calendar;
}

-(NSDateComponents *)comps{
    if (!_comps) {
        _comps = [[NSDateComponents alloc] init];
    }
    return _comps;
}

//刷新动画
-(UIView *)updateView{
    if (!_updateView) {
        _updateView = [[UIView alloc] initWithFrame:CGRectMake(-50, 100, 50, timelineW)];
        _updateView.backgroundColor  = [UIColor colorWithRed:120/255.0f green:210/255.0f blue:1.0f alpha:1.0f];
        _updateView.alpha = 0.5;
        [self addSubview:_updateView];
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
        
        //    animation.toValue = x;
        animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, 100)];      // 起始点
        animation.toValue = [NSValue valueWithCGPoint:CGPointMake(kWinW + 50, 100)]; // 终了点
        animation.duration = 0.5;
        
        animation.removedOnCompletion = NO;//yes的话，又返回原位置了。
        animation.repeatCount = LONG_MAX;
        
        animation.fillMode = kCAFillModeForwards;
        animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        
        [_updateView.layer addAnimation:animation forKey:nil];
        
    }
    return _updateView;
}


-(instancetype)initWithFrame:(CGRect)frame{
    if (self == [super initWithFrame:frame]) {
        [self initTimeLine];
    }
    return self;
}

-(void)setMoveDate:(NSDate *)moveDate{
     float x = [self timeLineXoneTime:moveDate];
    self.MNTimeLineCollction.contentOffset = CGPointMake(x, 0);
    self.timeLabel.text = [self setLabelText:x];

}
#pragma mark 时间轴初始化

-(void)initTimeLine{
    
    UICollectionViewFlowLayout *flowLayout= [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;//滚动方向
    flowLayout.minimumLineSpacing = 0;//行间距(最小值)
    flowLayout.minimumInteritemSpacing = 0;//item间距(最小值)
    //flowLayout.sectionInset = UIEdgeInsetsMake(10,10, 10, 10);
    //flowLayout.collectionViewContent.frame.size.height = 80;
    self.MNTimeLineCollction = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, kWinW, timelineW) collectionViewLayout:flowLayout];
    [self addSubview:self.MNTimeLineCollction];
    self.MNTimeLineCollction.userInteractionEnabled = YES;
    self.MNTimeLineCollction.showsVerticalScrollIndicator = NO;
    static NSString * CellIdentifier = @"TimeLinecell";
    
    //collection 注册Cell
    [self.MNTimeLineCollction registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
    
    //collection位置和单元格属性
    self.CellWidth = changeBase;
    self.unitTime = 24 * 3600 / 720;
    self.unitLength = self.CellWidth / 720;
    NSDate *date=[NSDate date];
    [self.dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    float x = [self timeLineXAboutpresentTime:date];
    self.MNTimeLineCollction.contentOffset =CGPointMake(self.CellWidth * totalDay + x - kWinW/2,0);
    self.updateRow = (self.CellWidth * totalDay + x) / (int)self.CellWidth;
    self.MNTimeLineCollction.delegate = self;
    self.MNTimeLineCollction.dataSource = self;
    
    
    self.endDrawRect = YES;
    [self initTimeLineRedViewAndLabel];
   
    
    //添加放大缩小手势
    self.PinchGestureRecognizer
    = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinches:)];
    [self.MNTimeLineCollction addGestureRecognizer:self.PinchGestureRecognizer];

    // 当天时间请求列表
//    [self.dateFormat setDateFormat:@"yyyy-MM-dd"];
//    self.requestTimeStr = [self.dateFormat stringFromDate:[NSDate date]];
//    [self.dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    
    
    
}
-(void)initTimeLineRedViewAndLabel{
    UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(kWinW/2 - 0.5, 10, 1, timelineW - 15)];
    redView.backgroundColor = MNColor(295, 195, 43);
    [self addSubview:redView];
    redView.tag = 101;
    self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kWinW/2 - 65, 0, 130, 15)];
    self.timeLabel.font = [UIFont systemFontOfSize:12];
    self.timeLabel.layer.masksToBounds = YES;
    float x = [self timeLineXAboutpresentTime:[NSDate date]];
    self.maxContentOffsetX = self.CellWidth * totalDay + x - kWinW/2;
    self.timeLabel.text = [self setLabelText:self.MNTimeLineCollction.contentOffset.x];
    [self.timeLabel setTextAlignment:NSTextAlignmentCenter];
    
    [self addSubview:self.timeLabel];
}

#pragma mark 手势方法
-(void)handlePinches:(UIPinchGestureRecognizer *)pinch{
    // self.isUpdateRect = YES;
    if (pinch.state == UIGestureRecognizerStateChanged) {
        
        int touchCount = (int )pinch.numberOfTouches;
        
        if (touchCount == 2) {
            
            CGPoint p1 = [pinch locationOfTouch: 0 inView:self.MNTimeLineCollction];
            
            CGPoint p2 = [pinch locationOfTouch: 1 inView:self.MNTimeLineCollction];
            
            self.addX =  (p1.x+p2.x)/(2 * self.CellWidth) * changeBase;
            
            NSLog(@"手势的位置%f%f",p1.x,p2.x);
        }
        
        if (pinch.scale > 1) {
            if (self.CellWidth < 45000) {
                self.CellWidth = self.CellWidth + changeBase;
                [self updatelabelText];
                [self updateRect];
                self.videoX = (int)(self.MNTimeLineCollction.contentOffset.x + self.addX) % (int)self.CellWidth;
                self.endDrawRect = NO;
                [self.MNTimeLineCollction reloadData];
                self.MNTimeLineCollction.contentOffset =CGPointMake(self.MNTimeLineCollction.contentOffset.x + self.addX,0);
            }
        }else{
            if (self.CellWidth > changeBase) {
                self.CellWidth = self.CellWidth - changeBase;
                [self updatelabelText];
                [self updateRect];
                self.videoX = (int)(self.MNTimeLineCollction.contentOffset.x - self.addX) % (int)self.CellWidth;
                self.endDrawRect = NO;
                [self.MNTimeLineCollction reloadData];
                self.MNTimeLineCollction.contentOffset =CGPointMake(self.MNTimeLineCollction.contentOffset.x - self.addX,0);
            }
        }
    }
    
    if (pinch.state == UIGestureRecognizerStateEnded) {
        [self updateRect];
        self.endDrawRect = YES;
        [self.MNTimeLineCollction reloadData];
    }
}


-(void)updatelabelText{
    // 当每格宽度大于60的时候一天分成7200格
    if (self.CellWidth > 60 * 720) {
        self.unitTime = 24 * 3600 / 7200;
        self.unitLength = self.CellWidth / 7200;
        
    }else if (self.CellWidth > 30 * 720){
        self.unitTime = 24 * 3600 / 3600;
        self.unitLength = self.CellWidth / 3600;
        
    }
    else{
        self.unitTime = 24 * 3600 / 720;
        self.unitLength = self.CellWidth / 720;
        
    }
    
    
    NSDate *date=[NSDate date];
    float x = [self timeLineXAboutpresentTime:date];
    self.maxContentOffsetX = self.CellWidth * totalDay + x - kWinW/2;
    self.timeLabel.text = [self setLabelText:self.MNTimeLineCollction.contentOffset.x];
    
}


#pragma mark --UICollectionViewDelegate

// 定义展示的UICollectionViewCell的个数
-(NSInteger)collectionView:( UICollectionView *)collectionView numberOfItemsInSection:( NSInteger )section{
    return 9;
}

// 定义展示的Section的个数
-(NSInteger)numberOfSectionsInCollectionView:( UICollectionView *)collectionView{
    return 1;
}

// 每个UICollectionView展示的内容
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (collectionView == self.MNTimeLineCollction) {
        UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TimeLinecell" forIndexPath:indexPath];
        cell.backgroundColor = [UIColor whiteColor];
        self.timeLine = [[MNTimeLine alloc] initWithFrame:CGRectMake(0, 0, self.CellWidth , timelineW)];
        if (self.updateRow == indexPath.row) {
            self.timeLine.rectangleArray = self.rectangleArray;
        }
        self.timeLine.videoX = self.videoX;
        self.timeLine.endDrawRect = self.endDrawRect;
        
        //清楚cell的缓存
        for (UIView *subview in [cell.contentView subviews]) {
            [subview removeFromSuperview];
        }
        [cell.contentView addSubview:self.timeLine];
        return cell;
    }
    return nil;
}


#pragma mark --UICollectionViewDelegateFlowLayout

// 定义每个UICollectionView 的大小
- ( CGSize )collectionView:( UICollectionView *)collectionView layout:( UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:( NSIndexPath *)indexPath{
    return CGSizeMake(_CellWidth,timelineW);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}
#pragma mark - UITableViewDataSource

// 绑定时间轴和collection
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (self.MNTimeLineCollction == scrollView) {
        
        //回调出当前时间
        [self.delegate MNTimeLinePresentTime:[self datewithOffSet:scrollView.contentOffset.x]];
        
        // 当前时间对应今天的偏移量
        NSDate *date=[NSDate date];
        
        // 重新计算时间label时间
        float x = [self timeLineXAboutpresentTime:date];
        self.maxContentOffsetX = self.CellWidth * totalDay + x - kWinW/2;
        // 走到下一天还未更新列表示，下一天的报警区域，不该画上去BUG
        NSDate *curDate = [self.dateFormat dateFromString:self.timeLabel.text];
        float curOfset = [self timeLineXAboutpresentTime:curDate];
//        if ((curOfset < (kWinW/2 + 10) ) || (self.CellWidth - curOfset) < (kWinW/2 + 10)) {
//            self.isUpDate = NO;
//        }
        
        // 定位要报警区域要画的那天
        self.updateRow = ((int)scrollView.contentOffset.x + kWinW/2) / (int)self.CellWidth;
        if(scrollView.contentOffset.x < self.maxContentOffsetX || (scrollView.contentOffset.x > (x - kWinW/2))){
            //在时间轴表示时间范围内，时间label才会走
            self.timeLabel.text = [self setLabelText:scrollView.contentOffset.x];
              
        }
        if (scrollView.contentOffset.x > self.maxContentOffsetX) {
            self.MNTimeLineCollction.contentOffset = CGPointMake(self.maxContentOffsetX,0);
            
           }else if (scrollView.contentOffset.x < (x - kWinW/2)){
            
            self.MNTimeLineCollction.contentOffset = CGPointMake((x - kWinW/2), 0);
        }
        
    }
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{

    [self.delegate scrollViewWillBegin];
}


-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    [self.delegate touchViewEnd];

}


// 某个偏移对应的时间
-(NSString *)setLabelText:(float)setX{
    NSTimeInterval cha = ((self.maxContentOffsetX - setX) / self.unitLength )* self.unitTime;
    NSDate *date = [NSDate dateWithTimeInterval:-cha sinceDate:[NSDate date]];
    NSString *timestr = [self.dateFormat stringFromDate: date];
    return timestr;
}


-(NSDate *)datewithOffSet:(float)setX{
    NSTimeInterval cha = ((self.maxContentOffsetX - setX) / self.unitLength )* self.unitTime;
    NSDate *date = [NSDate dateWithTimeInterval:-cha sinceDate:[NSDate date]];

    return date;
}

// 当前时间对应当天偏移量的位置
-(float)timeLineXAboutpresentTime:(NSDate *)date{
    NSInteger unitFlags =  NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday |
    NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    self.comps = [self.calendar components:unitFlags fromDate:date];
    NSInteger hour = [self.comps hour];
    NSInteger min = [self.comps minute];
    NSInteger sec = [self.comps second];
    NSTimeInterval cha = hour * 3600 + min * 60 + sec ;
    float x = (cha/self.unitTime) * self.unitLength;
    return x;
}




//任意时间对应偏移量的位置
-(float)timeLineXoneTime:(NSDate *)date{
    // 当前时间对应今天的偏移量
    NSDate *currDate = [NSDate date];
    
    // 重新计算时间label时间
    float x = [self timeLineXAboutpresentTime:currDate];
    self.maxContentOffsetX = self.CellWidth * totalDay + x - kWinW/2;
    
    NSTimeInterval end  = [[NSDate date] timeIntervalSince1970]*1;
    
    NSTimeInterval start = [date timeIntervalSince1970]*1;
    
    NSTimeInterval cha = end - start;
    float x1 = (cha/self.unitTime) * self.unitLength;
    
    return (self.maxContentOffsetX - x1);
}


-(void)setTimeLineWithDate:(nonnull NSDate * )date{
    float x = [self timeLineXoneTime:date];
    self.MNTimeLineCollction.contentOffset = CGPointMake(x, 0);
    self.timeLabel.text = [self setLabelText:x];

}


-(void)joinDrawTimeLineRectWithStart:(NSDate *)start stop:(NSDate *)stop alarmevent:(MNAlarmevent )event{
    MNRectDate *rect = [[MNRectDate alloc] init];
    rect.stop_time = stop;
    rect.start_time = start;
    rect.event = event;
    [self.rectDateArray addObject:rect];

}

-(void)updateRect{
    [self.rectangleArray removeAllObjects];
    if (self.rectDateArray.count == 0) {
        return;
    }
    for (MNRectDate *rect in self.rectDateArray) {
        float startX = [self timeLineXAboutpresentTime:rect.start_time];
        float stopX = [self timeLineXAboutpresentTime:rect.stop_time];
        if ((stopX - startX) > 0){
            CGRect rectangleRect = CGRectMake(startX, 0, stopX - startX, timelineW);
            NSValue *value = [NSValue valueWithCGRect:rectangleRect];
            
            MNDrawRect *drawRect = [[MNDrawRect alloc] init];
            drawRect.start_time = startX;
            drawRect.stop_time = stopX;
            drawRect.event = rect.event;
            [self.rectangleArray addObject:drawRect];
        }
   }
    
 }

-(void)updateTimeline{
    [self updateRect];
    [self.MNTimeLineCollction reloadData];
    
}

-(void)stopUpdateAnimation{
    self.updateView.hidden = YES;
 };
-(void)startUpdateAnimation{
    self.updateView.hidden = NO;
    [self addSubview:self.updateView];
    [self.rectDateArray removeAllObjects];

};


-(void)removeAllRect{
    [self.rectDateArray removeAllObjects];
    [self.rectangleArray removeAllObjects];
}



//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
//    return self.MNTimeLineCollction;
//}



@end
