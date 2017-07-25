//
//  CameraViewController.m
//  PhotoByAVFou
//
//  Created by CSX on 2017/7/20.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "CameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <GLKit/GLKit.h>
#import "AppDelegate.h"
#import "CatLayer.h"

#define kMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight  [UIScreen mainScreen].bounds.size.height

typedef enum: NSInteger{
    BTNTAG = 10,
}BTNTags;

@interface CameraViewController ()<UIGestureRecognizerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate>
{
     BOOL isUsingFrontFacingCamera;
    AVCaptureVideoDataOutput *videoDataOutput;
    UIImage *largeImage;
    BOOL isNeedBeautiful;
    CatLayer *layerView;
}
@property GLKView *videoPreviewView;
@property CIContext *ciContext;
@property EAGLContext *eaglContext;
@property CGRect videoPreviewViewBounds;
@property AVCaptureDevice *videoDevice;

@property (nonatomic) dispatch_queue_t sessionQueue;
/**
 *  AVCaptureSession对象来执行输入设备和输出设备之间的数据传递
 */
@property (nonatomic, strong) AVCaptureSession* session;
/**
 *  输入设备
 */
@property (nonatomic, strong) AVCaptureDeviceInput* videoInput;
/**
 *  照片输出流
 */
@property (nonatomic, strong) AVCaptureStillImageOutput* stillImageOutput;
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;

/**
 *  记录开始的缩放比例
 */
@property(nonatomic,assign)CGFloat beginGestureScale;
/**
 *  最后的缩放比例
 */
@property(nonatomic,assign)CGFloat effectiveScale;

@property(nonatomic, strong)AVCaptureMetadataOutput *metadataOutput;


@end

@implementation CameraViewController
-(AVCaptureMetadataOutput *)metadataOutput{
    if (_metadataOutput == nil) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc]init];
        [_metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        //设置扫描区域
        _metadataOutput.rectOfInterest = self.view.bounds;
    }
    return _metadataOutput;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    if (self.session) {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
    if (self.session) {
        [self.session stopRunning];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createView];

}
- (void)createView{
    isUsingFrontFacingCamera = NO;
    self.effectiveScale = self.beginGestureScale = 1.0f;
    // obtain the preset and validate the preset
    NSString *preset = AVCaptureSessionPresetHigh;
    //    if (![_videoDevice supportsAVCaptureSessionPreset:preset])
    //    {
    //        NSLog(@"%@", [NSString stringWithFormat:@"Capture session preset not supported by video device: %@", preset]);
    //        return;
    //    }
    
    self.session = [[AVCaptureSession alloc] init];
    self.session.sessionPreset = preset;
    
    NSError *error;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    后置摄像头（稍后做安全判断）
    AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
    
    for (AVCaptureDevice *device in _videoDevice)
    {
        if (device.position == position) {
            _videoDevice = device;
            break;
        }
    }
    
    //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
    [device lockForConfiguration:nil];
    //设置闪光灯为自动
    [device setFlashMode:AVCaptureFlashModeAuto];
    [device unlockForConfiguration];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }else{
        if ([self.session canAddInput:self.videoInput]) {
            [self.session addInput:self.videoInput];
        }
    }
    
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    if ([self.session canAddOutput:self.stillImageOutput]) {
        [self.session addOutput:self.stillImageOutput];
    }
    //输出设置。AVVideoCodecJPEG   输出jpeg格式图片
    NSDictionary * outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    
   
    
    // CoreImage wants BGRA pixel format
    NSDictionary *outputSettingsVideo = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
    // create and configure video data output
    videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoDataOutput.videoSettings = outputSettingsVideo;
    
    // create the dispatch queue for handling capture session delegate method calls
    _sessionQueue = dispatch_queue_create("capture_session_queue", NULL);
    [videoDataOutput setSampleBufferDelegate:self queue:_sessionQueue];
    
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    // begin configure capture session
    
    
    if (![self.session canAddOutput:videoDataOutput])
    {
        NSLog(@"Cannot add video data output");
        self.session = nil;
        return;
    }else{
        [self.session addOutput:videoDataOutput];
    }
    
//使用二维码扫描和人脸识别的metadataOutput
    if ([self.session canAddOutput:self.metadataOutput]) {
        [self.session addOutput:self.metadataOutput];
        //设置扫码格式，
//        self.metadataOutput.metadataObjectTypes = @[
//                                                    AVMetadataObjectTypeQRCode,
//                                                    AVMetadataObjectTypeEAN13Code,
//                                                    AVMetadataObjectTypeEAN8Code,
//                                                    AVMetadataObjectTypeCode128Code
//                                                    ];
        
//        设置人脸识别的扫码格式
        self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }
    [self.session beginConfiguration];

    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = CGRectMake(0, 0,kMainScreenWidth, kMainScreenHeight);
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:self.previewLayer];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
    
    
    //    创建猫耳朵图层
    layerView = [[CatLayer alloc]init];
    layerView.hidden = YES;
    [self.previewLayer addSublayer:layerView.layer];
    
    
    NSArray *Arr  =@[@"返回",@"拍照",@"闪光灯",@"滤镜",@"特效",@"切换摄像"];
    for (int i = 0; i<Arr.count; i++) {
        UIButton *myCreateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        myCreateButton.frame = CGRectMake(0, 20+50*i, 100, 50);
        myCreateButton.layer.cornerRadius = 50;
        myCreateButton.clipsToBounds = YES;
        myCreateButton.tag = BTNTAG+i;
        [myCreateButton setBackgroundColor:[UIColor grayColor]];
        [myCreateButton setTitle:Arr[i] forState:UIControlStateNormal];
        [myCreateButton addTarget:self action:@selector(buttonChoose:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:myCreateButton];
    }
    
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _videoPreviewView = [[GLKView alloc] initWithFrame:self.previewLayer.bounds context:_eaglContext];
    _videoPreviewView.enableSetNeedsDisplay = NO;
    _videoPreviewView.transform = CGAffineTransformMakeRotation(M_PI_2);
    _videoPreviewView.frame = self.view.bounds;
//    [self.previewLayer addSublayer:_videoPreviewView.layer];
//    [self.previewLayer sendSubviewToBack:_videoPreviewView];
    isNeedBeautiful = YES;
    
    [_videoPreviewView bindDrawable];
    _videoPreviewViewBounds = CGRectZero;
    _videoPreviewViewBounds.size.width = _videoPreviewView.drawableWidth;
    _videoPreviewViewBounds.size.height = _videoPreviewView.drawableHeight;
    
    _ciContext = [CIContext contextWithEAGLContext:_eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
    
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0)
    {
        [self initWithCamera];
    }
    else
    {
        NSLog(@"No device with AVMediaTypeVideo");
    }
}
- (void)initWithCamera{
    
//    NSDictionary *outputSettingsVideo = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
//    // create and configure video data output
//    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
//    videoDataOutput.videoSettings = outputSettingsVideo;
//    
//    // create the dispatch queue for handling capture session delegate method calls
//    _sessionQueue = dispatch_queue_create("capture_session_queue", NULL);
//    [videoDataOutput setSampleBufferDelegate:self queue:_sessionQueue];
//    
//    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
//    [self.session beginConfiguration];
//    if ([self.session canAddOutput:videoDataOutput]) {
//        [self.session addOutput:videoDataOutput];
//    }else{
//        NSLog(@"Cannot add video data output");
//        self.session = nil;
//        return;
//    }
//    [self.session commitConfiguration];
//    
//    // then start everything
//    [self.session startRunning];
    
    
   
    [self.session commitConfiguration];
    
    // then start everything
    [self.session startRunning];
    
    
    
    
    
}
#pragma mark gestureRecognizer delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}


- (void)buttonChoose:(UIButton *)sender{
    switch (sender.tag-BTNTAG) {
        case 0:
        {
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
            break;
        case 1:
        {
//            拍照
            [self takePhotoPicture];
        }
            break;
        case 2:
        {
//            闪光灯
            [self openFlashOrClose];
        }
            break;
        case 3:
        {
//            美颜
            [self beautifulFace];
        }
            break;
        case 4:
        {
//            特效
            [self specialPic];
        }
            break;
        case 5:
        {
//            切换摄像头
            [self changePhotoFront];
        }
            break;
            
        default:
            break;
    }
}


//拍照
- (void)takePhotoPicture{
//    AVCaptureConnection *stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
//    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
//    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
//    [stillImageConnection setVideoOrientation:avcaptureOrientation];
//    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    
//    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
//    
//    jpegData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:imageDataSampleBuffer previewPhotoSampleBuffer:nil];
    
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusDenied) {
            NSLog(@"用户拒绝当前应用访问相册,我们需要提醒用户打开访问开关");
        }else if (status == PHAuthorizationStatusRestricted){
            NSLog(@"家长控制,不允许访问");
        }else {
            NSLog(@"用户允许当前应用访问相册");
            //2.保存图片到系统相册
            UIImageWriteToSavedPhotosAlbum(largeImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
        
//    }];
}
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}
// 成功保存图片到系统相册中, 必须调用此方法, 否则会报参数越界错误
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存失败");
        NSLog(@">>>>>>>>>>>%@",error.localizedDescription);
    }else{
        NSLog(@"保存成功");
    }
}



//打开闪光灯
- (void)openFlashOrClose{
    static BOOL openFlash = NO;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//   前摄像头的时候闪光灯不可用。
    if (!isUsingFrontFacingCamera) {
        //修改前必须先锁定
        [device lockForConfiguration:nil];
        //必须判定是否有闪光灯，否则如果没有闪光灯会崩溃
        if ([device isFlashAvailable]) {
            if (openFlash) {
                [device setTorchMode:AVCaptureTorchModeOff];
                NSLog(@"关闭闪光灯");
            }else{
                [device setTorchMode:AVCaptureTorchModeOn];
                NSLog(@"打开闪光灯");
            }
        } else {
            NSLog(@"设备不支持闪光灯");
        }
        [device unlockForConfiguration];
    }else{
        NSLog(@"使用的前置摄像头");
    }
    openFlash = !openFlash;
}




//美颜,即添加滤镜。
- (void)beautifulFace{
    if (isNeedBeautiful) {
        [self.previewLayer addSublayer:_videoPreviewView.layer];
        isNeedBeautiful = NO;
    }else{
        [_videoPreviewView.layer removeFromSuperlayer];
        isNeedBeautiful = YES;
    }
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    AVCaptureConnection *stillImageConnection = [captureOutput connectionWithMediaType:AVMediaTypeVideo];
//    
//    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
//        
//        jpegData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:imageDataSampleBuffer previewPhotoSampleBuffer:nil];
//        
//    }];    
    if (!isNeedBeautiful) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
        CGRect sourceExtent = sourceImage.extent;
        
        // Image processing
        CIFilter * vignetteFilter = [CIFilter filterWithName:@"CIVignetteEffect"];
        [vignetteFilter setValue:sourceImage forKey:kCIInputImageKey];
        [vignetteFilter setValue:[CIVector vectorWithX:sourceExtent.size.width/2 Y:sourceExtent.size.height/2] forKey:kCIInputCenterKey];
        [vignetteFilter setValue:@(sourceExtent.size.width/2) forKey:kCIInputRadiusKey];
        CIImage *filteredImage = [vignetteFilter outputImage];
        
        CIFilter *effectFilter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];
        [effectFilter setValue:filteredImage forKey:kCIInputImageKey];
        filteredImage = [effectFilter outputImage];
        
        
        CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
        CGFloat previewAspect = _videoPreviewViewBounds.size.width  / _videoPreviewViewBounds.size.height;
        
        // we want to maintain the aspect radio of the screen size, so we clip the video image
        CGRect drawRect = sourceExtent;
        if (sourceAspect > previewAspect)
        {
            // use full height of the video image, and center crop the width
            drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect) / 2.0;
            drawRect.size.width = drawRect.size.height * previewAspect;
        }
        else
        {
            // use full width of the video image, and center crop the height
            drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect) / 2.0;
            drawRect.size.height = drawRect.size.width / previewAspect;
        }
        
        [_videoPreviewView bindDrawable];
        
        if (_eaglContext != [EAGLContext currentContext])
            [EAGLContext setCurrentContext:_eaglContext];
        
        // clear eagl view to grey
        glClearColor(0.5, 0.5, 0.5, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // set the blend mode to "source over" so that CI will use that
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        if (filteredImage)
            [_ciContext drawImage:filteredImage inRect:_videoPreviewViewBounds fromRect:drawRect];
        
        [_videoPreviewView display];
    }
    
    
   largeImage = [self imageFromSampleBuffer:sampleBuffer];
}


//CMSampleBufferRef转NSImage
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    // 释放context和颜色空间
    CGContextRelease(context); CGColorSpaceRelease(colorSpace);
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return (image);
}


//特效
- (void)specialPic{
    static BOOL isNeedSpecial = YES;
    if (isNeedSpecial) {
        layerView.hidden = NO;
    }else{
        layerView.hidden = YES;
    }
    isNeedSpecial = !isNeedSpecial;
}

//检测面部识别代理方法
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
//    NSLog(@">>>>>>>>>%@",metadataObjects);
    
    if (metadataObjects.count>0) {
//        [self.session stopRunning];
        
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex :0];
        if (metadataObject.type == AVMetadataObjectTypeFace) {
            AVMetadataObject *objec = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
            
            AVMetadataFaceObject *face = (AVMetadataFaceObject *)objec;
//            NSLog(@">>>>>>>>>>>>%f>>>>>>>>>%f>>>>>>>>%f>>>>>>>>>>%f",face.bounds.origin.x,face.bounds.origin.y,face.bounds.size.width,face.bounds.size.height);
//           face.rollAngle图片的2d旋转
//           face.yawAngle图片的3d旋转偏移量
            [layerView addPictureForCatEarWithRect:face.bounds WithRowAngle:face.rollAngle WithYawAngle:face.yawAngle];
            
            NSLog(@">>>>>>>>>>>>>>%f",face.yawAngle);
            
            
           
            
            
            
//            图片的面部识别
//            CIImage* image = [CIImage imageWithCGImage:aImage.CGImage];
//            
//            NSDictionary  *opts = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
//                                                              forKey:CIDetectorAccuracy];
//            
//            CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
//                                                      context:nil
//                                                      options:opts];
//            
//            //得到面部数据  
//            NSArray* features = [detector featuresInImage:image];
//            for (CIFaceFeature *f in features)
//            {
//                CGRect aRect = f.bounds;
//                NSLog(@"%f, %f, %f, %f", aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height);
//                
//                //眼睛和嘴的位置
//                if(f.hasLeftEyePosition) NSLog(@"Left eye %g %g\n", f.leftEyePosition.x, f.leftEyePosition.y);
//                if(f.hasRightEyePosition) NSLog(@"Right eye %g %g\n", f.rightEyePosition.x, f.rightEyePosition.y);
//                if(f.hasMouthPosition) NSLog(@"Mouth %g %g\n", f.mouthPosition.x, f.mouthPosition.y);  
//            }
            
        }
    }
}





//调换摄像头
- (void)changePhotoFront{
    AVCaptureDevicePosition desiredPosition;
    if (isUsingFrontFacingCamera){
        desiredPosition = AVCaptureDevicePositionBack;
    }else{
        desiredPosition = AVCaptureDevicePositionFront;
    }
    
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == desiredPosition) {
            [self.previewLayer.session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in self.previewLayer.session.inputs) {
                [[self.previewLayer session] removeInput:oldInput];
            }
            [self.previewLayer.session addInput:input];
            [self.previewLayer.session commitConfiguration];
            break;
        }
    }
    
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
//缩放手势 用于调整焦距
- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer{
    
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [recognizer numberOfTouches], i;
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [recognizer locationOfTouch:i inView:self.view];
        CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
        if ( ! [self.previewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        
        
        self.effectiveScale = self.beginGestureScale * recognizer.scale;
        if (self.effectiveScale < 1.0){
            self.effectiveScale = 1.0;
        }
        
        NSLog(@"%f-------------->%f------------recognizerScale%f",self.effectiveScale,self.beginGestureScale,recognizer.scale);
        
        CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
        
        NSLog(@"%f",maxScaleAndCropFactor);
        if (self.effectiveScale > maxScaleAndCropFactor)
            self.effectiveScale = maxScaleAndCropFactor;
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.025];
        [self.previewLayer setAffineTransform:CGAffineTransformMakeScale(self.effectiveScale, self.effectiveScale)];
        [CATransaction commit];
        
    }
    
}
@end
