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
    
    UIView *headContentView;
}
@end

@implementation CatLayer


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self createViewWithFrame:[[UIScreen mainScreen] bounds]];
    }
    return self;
}
- (void)createViewWithFrame:(CGRect)frame{
    
    headContentView = [[UIView alloc]init];
    headContentView.frame = CGRectMake(0, 0, 0, 0);
    headContentView.backgroundColor = [UIColor clearColor];
    [self addSubview:headContentView];
    
    
    headView = [[UIView alloc]init];
    headView.backgroundColor = [UIColor clearColor];
    [headContentView addSubview:headView];
    
    earImageView = [[UIImageView  alloc]init];
    UIImage *image = [UIImage imageNamed:@"2"];
    CGSize picSize = [image size];
    sizeBite = picSize.width/picSize.height;
    earImageView.image = image;
    earImageView.backgroundColor = [UIColor clearColor];
    [headContentView addSubview:earImageView];
    
}

- (void)addPictureForCatEarWithRect:(CGRect)frame WithRowAngle:(CGFloat)row WithYawAngle:(CGFloat)angle{
//    做双耳朵的时候，这里添加一个笔率等比例放大缩小。
//    CGFloat sizeBite = frame.size.width/200;
    
    headContentView.center = CGPointMake(frame.origin.x+frame.size.width/2, frame.origin.y+frame.size.height/2);
    headContentView.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height+frame.size.width/sizeBite*2);
//        这里只做一个头上面的兔子耳朵的样式
     headView.center = headContentView.center;
    headView.bounds = CGRectMake(0, 0, frame.size.width, frame.size.height);
    earImageView.frame = CGRectMake(0, 0, frame.size.width, frame.size.width/sizeBite);
    NSLog(@">>>>>>>>>>>>>>%f",row);

    
//    2d旋转（如果可以的话，这个界面的显示可以使用一整个图片的套壳imageview，直接贴在上面）
    headContentView.transform = CGAffineTransformMakeRotation(row/180.0f*M_PI);
    

    //    3d旋转
    CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
    rotationAndPerspectiveTransform.m34 = 1.0 / -500;
    rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, -angle/180.0f*M_PI, 0.0f, 1.0f, 0.0f);
    earImageView.layer.transform = rotationAndPerspectiveTransform;
    
    //    缩放：
    //            CGAffineTransform transform = map.transform;
    //            transform = CGAffineTransformScale(transform, 2,2);
    //            map.transform = transform;
    
}






/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
