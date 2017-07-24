//
//  CatLayer.m
//  PhotoByAVFou
//
//  Created by CSX on 2017/7/24.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "CatLayer.h"

@implementation CatLayer


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self createViewWithFrame:frame];
    }
    return self;
}

- (void)createViewWithFrame:(CGRect)frame{
    
    UILabel *label = [[UILabel alloc]init];
    label.frame = CGRectMake(frame.origin.x, frame.origin.y, 100, 50);
    label.font = [UIFont systemFontOfSize:17];
    label.text = @"测试文字显示";
    label.textColor = [UIColor grayColor];
    label.textAlignment = 1;
    [self addSubview:label];
    
}



- (void)drawRect:(CGRect)rect{
    
    
}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
