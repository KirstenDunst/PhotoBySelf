//
//  CameraViewController.m
//  FaceCamera
//
//  Created by CSX on 2017/7/17.
//  Copyright © 2017年 宗盛商业. All rights reserved.
//

#import "CameraViewController.h"
//由于后面我们需要将拍摄好的照片写入系统相册中，所以我们在这里还需要导入一个相册需要的头文件
#import <Photos/Photos.h>

#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"
#import "CatFilterBySelf.h"

@interface CameraViewController ()

@property (nonatomic, strong) GPUImageStillCamera *picCamera;
@property (nonatomic, strong) GPUImageFilter *filterView;

@end

@implementation CameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initAVCaptureSession];
    [self createView];
}
- (void)createView{
    UIButton *myCreateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    myCreateButton.frame = CGRectMake(0, 20, 100, 50);
    myCreateButton.layer.cornerRadius = 50;
    myCreateButton.clipsToBounds = YES;
    [myCreateButton setBackgroundColor:[UIColor grayColor]];
    [myCreateButton setTitle:@"返回" forState:UIControlStateNormal];
    [myCreateButton addTarget:self action:@selector(buttonChoose:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myCreateButton];

    UIButton *myCreateButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    myCreateButton1.frame = CGRectMake(0, 50+20, 100, 50);
    myCreateButton1.layer.cornerRadius = 50;
    myCreateButton1.clipsToBounds = YES;
    [myCreateButton1 setBackgroundColor:[UIColor grayColor]];
    [myCreateButton1 setTitle:@"拍照" forState:UIControlStateNormal];
    [myCreateButton1 addTarget:self action:@selector(takePhotoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myCreateButton1];
    
    UIButton *myCreateButton2 = [UIButton buttonWithType:UIButtonTypeCustom];
    myCreateButton2.frame = CGRectMake(0, 100+20, 100, 50);
    myCreateButton2.layer.cornerRadius = 50;
    myCreateButton2.clipsToBounds = YES;
    [myCreateButton2 setBackgroundColor:[UIColor grayColor]];
    [myCreateButton2 setTitle:@"闪光灯" forState:UIControlStateNormal];
    [myCreateButton2 addTarget:self action:@selector(flashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myCreateButton2];
    
    
    UIButton *myCreateButton3 = [UIButton buttonWithType:UIButtonTypeCustom];
    myCreateButton3.frame = CGRectMake(0, 150+20, 100, 50);
    myCreateButton3.layer.cornerRadius = 50;
    myCreateButton3.clipsToBounds = YES;
    [myCreateButton3 setBackgroundColor:[UIColor grayColor]];
    [myCreateButton3 setTitle:@"美颜" forState:UIControlStateNormal];
    [myCreateButton3 addTarget:self action:@selector(beautifulButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myCreateButton3];
    
    
    UIButton *myCreateButton4 = [UIButton buttonWithType:UIButtonTypeCustom];
    myCreateButton4.frame = CGRectMake(0, 200+20, 100, 50);
    myCreateButton4.layer.cornerRadius = 50;
    myCreateButton4.clipsToBounds = YES;
    [myCreateButton4 setBackgroundColor:[UIColor grayColor]];
    [myCreateButton4 setTitle:@"特效" forState:UIControlStateNormal];
    [myCreateButton4 addTarget:self action:@selector(refreshButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myCreateButton4];
    
    
    UIButton *myCreateButton5 = [UIButton buttonWithType:UIButtonTypeCustom];
    myCreateButton5.frame = CGRectMake(0, 250+20, 100, 50);
    myCreateButton5.layer.cornerRadius = 50;
    myCreateButton5.clipsToBounds = YES;
    [myCreateButton5 setBackgroundColor:[UIColor grayColor]];
    [myCreateButton5 setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [myCreateButton5 addTarget:self action:@selector(changePhotoClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myCreateButton5];
}
- (void)initAVCaptureSession{
    
//    AVCaptureSessionPreset640x480设置过大的话会导致摄像头切换不了，canAddInput不支持那么大的输入比率
    self.picCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    //    [self.videoCamera setCaptureSessionPreset:AVCaptureSessionPreset640x480];
    self.picCamera.outputImageOrientation = UIInterfaceOrientationPortraitUpsideDown;
    self.picCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.filterView = [[GPUImageFilter alloc] init];
    [self.picCamera addTarget:self.filterView];
    [self.picCamera startCameraCapture];
    
   
    
    
    GPUImageView *iv=[[GPUImageView alloc] initWithFrame:self.view.frame];
    iv.fillMode=kGPUImageFillModePreserveAspectRatioAndFill;
    /*显示模式分为三种
     typedef NS_ENUM(NSUInteger, GPUImageFillModeType) {
     kGPUImageFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio
     kGPUImageFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color
     kGPUImageFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view
     };
     */
    [self.filterView addTarget:iv];
    [self.view addSubview:iv];
    
    [self.picCamera setOutputImageOrientation:UIInterfaceOrientationPortrait];
    [self.picCamera setJpegCompressionQuality:1.0];
    
    
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
        
//        // 1.保存图片到自定义相册
//        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
//        if (status == PHAuthorizationStatusDenied) {
//            NSLog(@"用户拒绝当前应用访问相册,我们需要提醒用户打开访问开关");
//        }else if (status == PHAuthorizationStatusRestricted){
//            NSLog(@"家长控制,不允许访问");
//        }else if (status == PHAuthorizationStatusNotDetermined){
//            NSLog(@"用户还没有做出选择");
//            [self saveImageWithImage:[UIImage imageWithData:processedJPEG]];
//        }else if (status == PHAuthorizationStatusAuthorized){
//            NSLog(@"用户允许当前应用访问相册");
//            [self saveImageWithImage:[UIImage imageWithData:processedJPEG]];
//        }
        
        
        //2.保存图片到系统相册
        UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:processedJPEG], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }];
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


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
}
//特效
- (void)refreshButtonClick:(UIButton *)sender{
    CatFilterBySelf *catFilter = [[CatFilterBySelf alloc]initWithInput:self.picCamera];
    [self.picCamera addTarget:catFilter];
    [catFilter addTarget: catFilter];
   

}

//切换摄像头
- (void)changePhotoClick:(UIButton *)sender{

    [self.picCamera rotateCamera];
    
}



//返回按钮
- (void)buttonChoose:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
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
