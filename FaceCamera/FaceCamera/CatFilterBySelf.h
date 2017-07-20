//
//  CatFilterBySelf.h
//  FaceCamera
//
//  Created by CSX on 2017/7/19.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface CatFilterBySelf : GPUImageFilter

- (instancetype)initWithInput:(GPUImageStillCamera*)input;
@end
