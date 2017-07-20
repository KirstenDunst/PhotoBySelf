//
//  CatFilterBySelf.m
//  FaceCamera
//
//  Created by CSX on 2017/7/19.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "CatFilterBySelf.h"

@implementation CatFilterBySelf



- (instancetype)initWithInput:(GPUImageStillCamera*)input{
    if ( [super init]) {
        [self createViewWithInput:input];
    }
    return self;
}


- (void)createViewWithInput:(GPUImageStillCamera*)input{
    
    CIImage *image = input.imageFromCurrentFramebuffer.CIImage;
    
    CIContext *context = [CIContext contextWithOptions:nil]; //1。创建一个上下文。当你创建一个检测器的时候可以传一个nil的上下文。
    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh }; //2，创建一个选项字典，它用来指定检测器的精度。你可以指定低精度或者高精度。低精度（CIDetectorAccuracyLow）执行得更快，而这个例子中的高精度将会比较慢。
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:opts]; //3，创建一个人脸检测器。你唯一能创建的识别器类型就是人脸检测。
    opts = @{ CIDetectorImageOrientation :
                          [[image properties] valueForKey:CIDetectorImageOrientation] }; // 4，找到人脸，我们需要设置一个选项字典。让CoreImage知道图像的转向是相当重要的，如此一来检测器就知道它能在哪找到摆正的脸。大多数情况你都需要从图像中获取图像的转向，然后将它作为选项字典的值。
    NSArray *features = [detector featuresInImage:image options:opts]; //5，使用检测器来发现图像中的特征，该图像必须是一个CIImage对象。CoreImage将会返回一个CIFeature对象的数组，每个元素都代表了图像中的一张脸。
    
    NSLog(@">>>>>>>>>>>>>>>%lu",(unsigned long)features.count);
    
    if (features.count>0) {
        for (CIFaceFeature *f in features)
        {
            NSLog(@"%@",NSStringFromCGRect(f.bounds));
            if (f.hasLeftEyePosition)
                NSLog(@"Left eye %g %g", f.leftEyePosition.x, f.leftEyePosition.y);
            if (f.hasRightEyePosition)
                NSLog(@"Right eye %g %g", f.rightEyePosition.x, f.rightEyePosition.y);
            if (f.hasMouthPosition)
                NSLog(@"Mouth %g %g", f.mouthPosition.x, f.mouthPosition.y);
        }
        
    }
   
}
@end
