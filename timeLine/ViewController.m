//
//  ViewController.m
//  timeLine
//
//  Created by 蛮牛科技 on 17/3/29.
//  Copyright © 2017年 孙慕. All rights reserved.
//

#import "ViewController.h"
#import "MNTimeLineView.h"

@interface ViewController ()<MNTimeLineTimeDelegate>
@property (nonatomic,strong)MNTimeLineView *timeLineView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _timeLineView  = [[MNTimeLineView alloc] initWithFrame:CGRectMake(0, 200, self.view.frame.size.width, 80)];
    _timeLineView.backgroundColor = [UIColor whiteColor];
    _timeLineView.delegate = self;
    [self.view addSubview:_timeLineView];

}

#pragma mark -- MNTimeLineTimeDelegate
-(void)MNTimeLinePresentTime:( NSDate * _Nonnull )time{
    
}
- (void)scrollViewWillBegin{
    
}
-(void)touchViewEnd{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
