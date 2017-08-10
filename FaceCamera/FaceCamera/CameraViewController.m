//
//  CameraViewController.m
//  FaceCamera
//
//  Created by CSX on 2017/7/17.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "CameraViewController.h"

#import <Photos/Photos.h>

#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"

#import "CatLayer.h"


#define kMainScreenWidth [UIScreen mainScreen].bounds.size.width
#define kMainScreenHeight  [UIScreen mainScreen].bounds.size.height

typedef enum: NSInteger{
    BTNTAG = 10,
}BTNTags;

@interface CameraViewController ()<AVCaptureMetadataOutputObjectsDelegate>
{
    CatLayer *layerView;
    BOOL isNeedCatLayer;
}
/**
 *  预览图层
 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer* previewLayer;

@property (nonatomic, strong) GPUImageStillCamera *picCamera;
@property (nonatomic, strong) GPUImageFilter *filterView;

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
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initAVCaptureSession];
    [self createView];
}
- (void)createView{
    NSArray *Arr = @[@"返回",@"拍照",@"闪光灯",@"美颜",@"特效",@"切换摄像"];
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
}

- (void)initAVCaptureSession{

//    AVCaptureSessionPreset640x480设置过大的话会导致摄像头切换不了，canAddInput不支持那么大的输入比率

    self.picCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    //    [self.videoCamera setCaptureSessionPreset:AVCaptureSessionPreset640x480];
    self.picCamera.outputImageOrientation = UIInterfaceOrientationPortraitUpsideDown;
    self.picCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.filterView = [[GPUImageFilter alloc] init];
    [self.picCamera addTarget:self.filterView];
    //使用二维码扫描和人脸识别的metadataOutput
    if ([self.picCamera.captureSession canAddOutput:self.metadataOutput]) {
        [self.picCamera.captureSession addOutput:self.metadataOutput];
        //设置扫码格式，
//                self.metadataOutput.metadataObjectTypes = @[
//                                                            AVMetadataObjectTypeQRCode,
//                                                            AVMetadataObjectTypeEAN13Code,
//                                                            AVMetadataObjectTypeEAN8Code,
//                                                            AVMetadataObjectTypeCode128Code
//                                                            ];
        
        //        设置人脸识别的扫码格式
        self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
    }
    [self.picCamera startCameraCapture];
    
    
    //初始化预览图层，这里只是为了下面的获取人脸识别解析使用和上面的[self.picCamera.captureSession addOutput:self.metadataOutput]添加使用
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.picCamera.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = self.view.frame;
//    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:self.previewLayer];
    
    
    GPUImageView *iv=[[GPUImageView alloc] initWithFrame:self.view.frame];
    iv.fillMode=kGPUImageFillModePreserveAspectRatioAndFill;
    /*显示模式分为三种
     typedef NS_ENUM(NSUInteger, GPUImageFillModeType) {
     kGPUImageFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio   拉伸以填充完整的视图，这可能会扭曲图像的正常宽比
     kGPUImageFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color   维护源图像的纵横比，添加指定背景色的栏
     kGPUImageFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view   保持源图像的纵横比，放大到其中心以填充视图
     };
     */
    [self.filterView addTarget:iv];
    [self.view addSubview:iv];
    
    [self.picCamera setOutputImageOrientation:UIInterfaceOrientationPortrait];
    [self.picCamera setJpegCompressionQuality:1.0];
    
    //    创建猫耳朵图层，这里坐标控制大小要和图像采集的大小相适应。不然合并图层的时候会存在压缩的问题。
    layerView = [[CatLayer alloc]initWithFrame:CGRectMake((iv.frame.size.width-480)/2, (iv.frame.size.height-640)/2, 480, 640)];
    layerView.hidden = YES;
    [iv addSubview:layerView];
   
}

- (void)buttonChoose:(UIButton *)sender{
    switch (sender.tag-BTNTAG) {
        case 0:
        {
            //            返回上一界面
            [self dismissViewControllerAnimated:YES completion:^{
            }];
        }
            break;
        case 1:
        {
            //            拍照
            [self takePhotoButtonClick:sender];
        }
            break;
        case 2:
        {
            //            闪光灯
            [self flashButtonClick:sender];
        }
            break;
        case 3:
        {
            //            美颜
            [self beautifulButtonClick:sender];
        }
            break;
        case 4:
        {
            //            特效
            [self refreshButtonClick:sender];
        }
            break;
        case 5:
        {
            //            切换摄像头
            [self changePhotoClick:sender];
        }
            break;
            
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];

    
}


- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
    
    
}
//获取设备的前后摄像头状态
-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

//拍照按钮
- (void)takePhotoButtonClick:(UIButton *)sender {
    [self.picCamera capturePhotoAsJPEGProcessedUpToFilter:self.filterView withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        if (error) {
            NSLog(@"%@",error.localizedDescription);
        }else{
            
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            if (status == PHAuthorizationStatusDenied) {
                NSLog(@"用户拒绝当前应用访问相册,我们需要提醒用户打开访问开关");
            }else if (status == PHAuthorizationStatusRestricted){
                NSLog(@"家长控制,不允许访问");
            }else {
                NSLog(@"用户允许当前应用访问相册");
                //2.保存图片到系统相册。
                UIImageWriteToSavedPhotosAlbum([self addImageToImage:[UIImage imageWithData:processedJPEG]], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            }
        }
    }];
}
//图片的合并处理
- (UIImage *)addImageToImage:(UIImage *)image2 {
    UIGraphicsBeginImageContext(CGSizeMake(image2.size.width, image2.size.height));
    [layerView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image1 = UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"?????????????%f>>>>>>>>>>>>>%f>>>>>>>>>>>>>%f>>>>>>>>>>>>>>>%f",image1.size.width,image1.size.height,image2.size.width,image2.size.height);
    // Draw image2，先画背景大的image
    [image2 drawInRect:CGRectMake(0, 0, image2.size.width, image2.size.height)];
    
    // Draw image1 然后画图像的添加
    [image1 drawInRect:CGRectMake((image2.size.width-image1.size.width)/2, (image2.size.height-image1.size.height)/2, image1.size.width, image1.size.height)];
    
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resultingImage;
}
//测试时的一个view转image的处理方式
//- (UIImage*) imageWithUIView:(UIView*) view
//{
//    UIGraphicsBeginImageContext(view.bounds.size);
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    [view.layer renderInContext:context];
//    
//    UIImage* tImage = UIGraphicsGetImageFromCurrentImageContext();
//    
//    UIGraphicsEndImageContext();
//    
//    return tImage;
//}

// 成功保存图片到系统相册中, 必须调用此方法, 否则会报参数越界错误
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"保存失败");
        NSLog(@">>>>>>>>>>>%@",error.localizedDescription);
    }else{
        NSLog(@"保存成功");
    }
}

//保存图片到自定义相册
/**
 *  返回相册
 */
- (PHAssetCollection *)collection{
    static NSString *BSCollectionName = @"自定义相册";
    // 先获得之前创建过的相册
    PHFetchResult<PHAssetCollection *> *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collectionResult) {
        if ([collection.localizedTitle isEqualToString:BSCollectionName]) {
            return collection;
        }
    }
    
    // 如果相册不存在,就创建新的相册(文件夹)
    __block NSString *collectionId = nil; // __block修改block外部的变量的值
    // 这个方法会在相册创建完毕后才会返回
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        // 新建一个PHAssertCollectionChangeRequest对象, 用来创建一个新的相册
        collectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:BSCollectionName].placeholderForCreatedAssetCollection.localIdentifier;
    } error:nil];
    
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].firstObject;
}
/**
 *  返回相册,避免重复创建相册引起不必要的错误
 */
- (void)saveImageWithImage:(UIImage *)image{
    /*
     PHAsset : 一个PHAsset对象就代表一个资源文件,比如一张图片
     PHAssetCollection : 一个PHAssetCollection对象就代表一个相册
     */
    
    __block NSString *assetId = nil;
    // 1. 存储图片到"相机胶卷"
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{ // 这个block里保存一些"修改"性质的代码
        // 新建一个PHAssetCreationRequest对象, 保存图片到"相机胶卷"
        // 返回PHAsset(图片)的字符串标识
        assetId = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            NSLog(@"保存图片到相机胶卷中失败");
            return;
        }
        
        NSLog(@"成功保存图片到相机胶卷中");
        
        // 2. 获得相册对象
        PHAssetCollection *collection = [self collection];
        
        // 3. 将“相机胶卷”中的图片添加到新的相册
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
            
            // 根据唯一标示获得相片对象
            PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetId] options:nil].firstObject;
            // 添加图片到相册中
            [request addAssets:@[asset]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (error) {
               NSLog(@"添加图片到相册中失败");
                return;
            }
            NSLog(@"成功添加图片到相册中");
        }];
    }];
}



//开启／关闭 闪光灯
- (void)flashButtonClick:(UIButton *)sender {
    if (self.picCamera.inputCamera.position == AVCaptureDevicePositionBack) {
         [self.picCamera.inputCamera lockForConfiguration:nil];
        if (sender.selected) {
            [self.picCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        }else{
            [self.picCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        }
        [self.picCamera.inputCamera unlockForConfiguration];
        
        sender.selected = !sender.selected;
    }else{
        NSLog(@"当前使用前置摄像头,未能开启闪光灯");
    }
}


//美颜
- (void)beautifulButtonClick:(UIButton *)sender{
    if (sender.selected) {
        [self.picCamera removeAllTargets];
        [self.picCamera addTarget:self.filterView];
    }
    else {
        [self.picCamera removeAllTargets];
        GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
        [self.picCamera addTarget:beautifyFilter];
        [beautifyFilter addTarget:self.filterView];
    }
    sender.selected = !sender.selected;
}


//特效
- (void)refreshButtonClick:(UIButton *)sender{
     isNeedCatLayer = !isNeedCatLayer;
    
    if (isNeedCatLayer) {
        layerView.hidden = NO;
//        添加美颜处理
        [self.picCamera removeAllTargets];
        GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
        [self.picCamera addTarget:beautifyFilter];
        [beautifyFilter addTarget:self.filterView];
    }else {
        layerView.hidden = YES;
//        去除美颜效果
        [self.picCamera removeAllTargets];
        [self.picCamera addTarget:self.filterView];
    }
}

//切换摄像头
- (void)changePhotoClick:(UIButton *)sender{
    [self.picCamera rotateCamera];
    
}


//检测面部识别代理方法
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    static BOOL haveFace;
    
    NSLog(@"//////////////%@",metadataObjects);
    if (metadataObjects.count>0) {
        haveFace = YES;
    }else{
        haveFace = NO;
    }
    
    if (isNeedCatLayer) {
        if (haveFace) {
            AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex :0];
            if (metadataObject.type == AVMetadataObjectTypeFace) {
                AVMetadataObject *objec = [self.previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
                
                AVMetadataFaceObject *face = (AVMetadataFaceObject *)objec;
                NSLog(@">>>>>>>>>>>>%f>>>>>>>>>%f>>>>>>>>%f>>>>>>>>>>%f",face.bounds.origin.x,face.bounds.origin.y,face.bounds.size.width,face.bounds.size.height);
                layerView.hidden = NO;
                //            这里像素位置的叠加是添加layer图层的没有像素采集的480*640的差距位置信息。
                [layerView addPictureForCatEarWithRect:CGRectMake(face.bounds.origin.x-(self.view.frame.size.width-480)/2,face.bounds.origin.y-(self.view.frame.size.height-640)/2,face.bounds.size.width,face.bounds.size.height) WithRowAngle:face.rollAngle WithYawAngle:face.yawAngle];
            }
        }else{
            layerView.hidden = YES;
        }
    }else{
        layerView.hidden = YES;
    }
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

@end
