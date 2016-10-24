//
//  ViewController.m
//  MyPhoto
//
//  Created by 宝龙董 on 2016/10/21.
//  Copyright © 2016年 dbl. All rights reserved.
//

#define kScreenBounds   [UIScreen mainScreen].bounds
#define kScreenWidth  kScreenBounds.size.width*1.0
#define kScreenHeight kScreenBounds.size.height*1.0

#import "ViewController.h"
#import "GPUImage.h"
#import "FilterView.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate,UIAlertViewDelegate>

//捕获设备，通常是前置摄像头，后置摄像头，麦克风
@property (nonatomic , strong) AVCaptureDevice * device;

//AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property (nonatomic , strong) AVCaptureDeviceInput * input;

//当摄像头凯斯捕获输入
@property (nonatomic , strong) AVCaptureMetadataOutput * output;

@property (nonatomic , strong) AVCaptureStillImageOutput * imageOutput;

//session:由他把输入输出结合在一起，并开始启动捕获设备
@property (nonatomic , strong) AVCaptureSession * session;

//图像预览层，实时显示捕获的图像
@property (nonatomic , strong) AVCaptureVideoPreviewLayer * previewLayer;

@property (nonatomic , strong) UIButton * photoButton;
@property (nonatomic , strong) UIImageView * imageView;
@property (nonatomic , strong) UIView * focusView;
@property (nonatomic , strong) UIImage * image;
@property (nonatomic , strong) UIButton * flashButton;
@property (nonatomic , strong) UIButton * changeCameraButton;
@property (nonatomic , strong) UIView * backView;
@property (nonatomic , strong) UIImageView * bigImageView;
@property (nonatomic , strong) UIView * topView;

@property (nonatomic , strong) FilterView * filterView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customUI];
    [self customCamera];
    
}

- (void)customUI {
    
    _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 30+128/4+10)];
    _topView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_topView];
    
    _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _flashButton.frame = CGRectMake(20, 30, 128/2/2, 128/2/2);
    [_flashButton setImage:[UIImage imageNamed:@"闪光灯"] forState:UIControlStateNormal];
    [_flashButton setImage:[UIImage imageNamed:@"闪光灯_canon"] forState:UIControlStateSelected];
    [_flashButton addTarget:self action:@selector(FlashButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:_flashButton];
    
    _changeCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _changeCameraButton.frame = CGRectMake(kScreenWidth-20-128/4, 30, 128/4, 128/4);
    [_changeCameraButton setImage:[UIImage imageNamed:@"转换"] forState:UIControlStateNormal];
    [_changeCameraButton addTarget:self action:@selector(changeDevicePosition) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:_changeCameraButton];
    
    _backView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight-80, kScreenWidth, 80)];
    _backView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_backView];
    
    _photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _photoButton.frame = CGRectMake(kScreenWidth/2-60/2, 10, 60, 60);
    [_photoButton setImage:[UIImage imageNamed:@"拍照按钮"] forState:UIControlStateNormal];
    [_photoButton addTarget:self action:@selector(takePhoto) forControlEvents:UIControlEventTouchUpInside];
    [_backView addSubview:_photoButton];
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kScreenWidth-65, 25/2, 50, 55)];
    _imageView.backgroundColor = [UIColor grayColor];
    _imageView.image = [UIImage imageNamed:@"cameraAlbumEntry"];
    _imageView.layer.masksToBounds = YES;
    _imageView.layer.cornerRadius = 4;
    [_backView addSubview:_imageView];
}

- (void)customCamera {
    self.view.backgroundColor = [UIColor whiteColor];
    //使用AVMediaTypeVideo指明self.device代表视频，默认使用后置摄像头初始化
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //使用设备初始化输入
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    
    //生成输出对象
    self.output = [[AVCaptureMetadataOutput alloc] init];
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    
    //生成会话，用来结合输入数车
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetPhoto]) {
        self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    }
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.imageOutput]) {
        [self.session addOutput:self.imageOutput];
    }
    
    //使用self.session,初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = CGRectMake(0, 30+128/4+10, kScreenWidth, kScreenHeight-80-30-128/4-10);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    
    //开始启动
    [self.session startRunning];
    //请求调节硬件配置的权限
    if ([_device lockForConfiguration:nil]) {
        if ([_device isFlashModeSupported:AVCaptureFlashModeAuto]) {
            [_device setFlashMode:AVCaptureFlashModeAuto];
        }
        //自动白平衡
        if ([_device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [_device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        //放弃调节硬件配置的权限
        [_device unlockForConfiguration];
    }
}

//转换摄像头
- (void)changeDevicePosition {
    NSLog(@"转换摄像头");
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        
        CATransition *animation = [CATransition animation];
        
        animation.duration = .5f;
        
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        animation.type = @"oglFlip";
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        AVCaptureDevicePosition position = [[_input device] position];
        if (position == AVCaptureDevicePositionFront){
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            animation.subtype = kCATransitionFromLeft;
        }
        else {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            animation.subtype = kCATransitionFromRight;
        }
        
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
        [self.previewLayer addAnimation:animation forKey:nil];
        if (newInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:_input];
            if ([self.session canAddInput:newInput]) {
                [self.session addInput:newInput];
                self.input = newInput;
                
            } else {
                [self.session addInput:self.input];
            }
            
            [self.session commitConfiguration];
            
        } else if (error) {
            NSLog(@"toggle carema failed, error = %@", error);
        }
        
    }
    
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position ) return device;
    return nil;
}

//闪光灯开启与关闭
- (void)FlashButtonClick:(UIButton *)button {
    if ([_device lockForConfiguration:nil]) {
        button.selected = !button.selected;
        if (button.selected) {
            NSLog(@"关闭闪光灯");
            if ([_device isFlashModeSupported:AVCaptureFlashModeOff]) {
                [_device setFlashMode:AVCaptureFlashModeOff];
            }
        } else {
            NSLog(@"开启闪光灯");
            if ([_device isFlashModeSupported:AVCaptureFlashModeOn]) {
                [_device setFlashMode:AVCaptureFlashModeOn];
            }
        }
        [_device unlockForConfiguration];
    }
}

//点击照相
- (void)takePhoto {
    NSLog(@"照相");
    AVCaptureConnection * videoConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    NSLog(@"%@",videoConnection);
    if (!videoConnection) {
        NSLog(@"拍照失败");
        return;
    }
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (imageDataSampleBuffer == NULL) {
            return ;
        }
        NSData * imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        self.image = [UIImage imageWithData:imageData];
        [_imageView removeFromSuperview];
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(kScreenWidth-15-25, 80/2, 10, 10)];
        _imageView.backgroundColor = [UIColor grayColor];
        _imageView.image = self.image;
        _imageView.layer.masksToBounds = YES;
        _imageView.layer.cornerRadius = 4;
        _imageView.userInteractionEnabled = YES;
        [_backView addSubview:_imageView];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeFilterView)];
        tap.numberOfTapsRequired = 1;
        [_imageView addGestureRecognizer:tap];
        [UIView animateWithDuration:0.4 animations:^{
            _imageView.frame = CGRectMake(kScreenWidth-65, 21/2, 50, 59);
        }];
        NSLog(@"image size = %@",NSStringFromCGSize(self.image.size));
    }];
}

- (void)changeFilterView {
    
    self.filterView = [[FilterView alloc] initWithFrame:CGRectMake(kScreenWidth, 0, kScreenWidth, kScreenHeight) image:self.image];
    self.filterView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.filterView];
    NSLog(@"转换到滤镜页面");
    [UIView animateWithDuration:0.35 animations:^{
        
        self.filterView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        
    }];
}

@end
