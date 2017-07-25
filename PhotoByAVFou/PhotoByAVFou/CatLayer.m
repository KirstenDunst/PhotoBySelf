//
//  CatLayer.m
//  PhotoByAVFou
//
//  Created by CSX on 2017/7/24.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "CatLayer.h"

@interface CatLayer ()
{
    UIView *headView;
    UIImageView *earImageView;
    
//    兔子头部的双耳朵在一个地方的显示宽高比率
    CGFloat sizeBite;
}
@end

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
    
    headView = [[UIView alloc]init];
    headView.backgroundColor = [UIColor clearColor];
    [self addSubview:headView];
    
    earImageView = [[UIImageView  alloc]init];
    UIImage *image = [UIImage imageNamed:@"1"];
    CGSize picSize = [image size];
    sizeBite = picSize.width/picSize.height;
    earImageView.image = [UIImage imageNamed:@"1"];
    
    [self addSubview:earImageView];
    
}

- (void)addPictureForCatEarWithRect:(CGRect)frame{
//    做双耳朵的时候，这里添加一个笔率等比例放大缩小。
//    CGFloat sizeBite = frame.size.width/200;
    
//    这里只做一个头上面的兔子耳朵的样式
    headView.frame = frame;
    earImageView.frame = CGRectMake(frame.origin.x, frame.origin.y-frame.size.height/sizeBite*(4/3), frame.size.width, frame.size.height/sizeBite);
    
    
}






/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
