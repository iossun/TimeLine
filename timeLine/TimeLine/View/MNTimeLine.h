//
//  MNTimeLine.h
//  text
//
//  Created by 蛮牛科技 on 16/3/23.
//  Copyright © 2016年 蛮牛科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MNDrawRect.h"


@interface MNTimeLine : UIView{
    float m_nStartX;
    float m_nEndX;
    float currentOffsetX;
    CGContextRef context;
    BOOL ok;
}

@property (nonatomic,strong) NSArray  <MNDrawRect *>*rectangleArray;
@property (nonatomic,assign) float videoX;
@property (nonatomic,assign) BOOL endDrawRect;
@property (nonatomic,assign) BOOL isUpdateRect;
@end
