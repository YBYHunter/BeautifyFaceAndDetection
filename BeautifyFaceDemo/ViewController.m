//
//  ViewController.m
//  BeautifyFaceDemo
//
//  Created by guikz on 16/4/27.
//  Copyright © 2016年 guikz. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"
#import <Masonry/Masonry.h>

@interface ViewController ()<GPUImageVideoCameraDelegate,AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) UIButton *beautifyButton;
@property (strong, nonatomic) AVCaptureMetadataOutput *medaDataOutput;
@property (strong, nonatomic) dispatch_queue_t captureQueue;
@property (nonatomic, strong) NSArray *faceObjects;

@property (nonatomic,strong) UILabel * faceBorderLab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.captureQueue = dispatch_queue_create("com.kimsungwhee.mosaiccamera.videoqueue", NULL);
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset352x288 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.delegate = self;
    self.videoCamera.videoCaptureConnection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
//    self.videoCamera.outputImageOrientation = UIInterfaceOrientationLandscapeLeft;
//    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
//    self.videoCamera.horizontallyMirrorRearFacingCamera = NO;
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.filterView.center = self.view.center;
    
    [self.view addSubview:self.filterView];
    
    [self.videoCamera addTarget:self.filterView];
    [self.videoCamera startCameraCapture];
    
    self.beautifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.beautifyButton.backgroundColor = [UIColor whiteColor];
    [self.beautifyButton setTitle:@"翻转" forState:UIControlStateNormal];
    [self.beautifyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.beautifyButton addTarget:self action:@selector(beautifyButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.beautifyButton];
    [self.beautifyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-20);
        make.width.equalTo(@100);
        make.height.equalTo(@40);
        make.centerX.equalTo(self.view);
    }];

    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    });
    [self beautify];
    
    //Meta data
    self.medaDataOutput = [[AVCaptureMetadataOutput alloc] init];
    if ([self.videoCamera.captureSession canAddOutput:self.medaDataOutput]) {
        [self.videoCamera.captureSession addOutput:self.medaDataOutput];
        
        self.medaDataOutput.metadataObjectTypes = @[AVMetadataObjectTypeFace];
        [self.medaDataOutput setMetadataObjectsDelegate:self queue:self.captureQueue];
        
    }
    [self.view addSubview:self.faceBorderLab];
}

- (void)beautifyButtonAction {

    NSLog(@"做个动画");
    [self.videoCamera rotateCamera];
    self.videoCamera.videoCaptureConnection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    self.faceBorderLab.hidden = YES;
    
}

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
    CIImage *sourceImage;
    

    
        CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        sourceImage = [CIImage imageWithCVPixelBuffer:imageBuffer
                                              options:nil];
        
        if (self.faceObjects && self.faceObjects.count > 0) {
            [self makeFaceWithCIImage:sourceImage];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.faceBorderLab.hidden = YES;
            });
            
        }
    
    [self imageFromSampleBuffer:sampleBuffer];

}

- (void)makeFaceWithCIImage:(CIImage *)inputImage
{
    CGSize mainScreenSize = [UIScreen mainScreen].bounds.size;
    for (AVMetadataFaceObject *faceObject in self.faceObjects) {
        CGRect faceBounds = faceObject.bounds;
        CGFloat centerX = inputImage.extent.size.width * (faceBounds.origin.x + faceBounds.size.width/2);
        CGFloat centerY = inputImage.extent.size.height * (1 - faceBounds.origin.y - faceBounds.size.height /2);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.faceBorderLab.hidden = NO;
            self.faceBorderLab.frame = CGRectMake(0, 0, faceBounds.size.width * mainScreenSize.width, faceBounds.size.height * (self.filterView.frame.size.height));
            self.faceBorderLab.center = CGPointMake(centerX, centerY + 44);
        });
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    self.faceObjects = metadataObjects;
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    uint8_t *baseAddress = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    CGImageRelease(quartzImage);
    if (image) {
//        NSLog(@"image ------------------------- %@",image);
    }
    return (image);
}

- (AVCaptureVideoOrientation) videoOrientationFromCurrentDeviceOrientation {
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationPortrait: {
            return AVCaptureVideoOrientationPortrait;
        }
        case UIInterfaceOrientationLandscapeLeft: {
            return AVCaptureVideoOrientationLandscapeLeft;
        }
        case UIInterfaceOrientationLandscapeRight: {
            return AVCaptureVideoOrientationLandscapeRight;
        }
        case UIInterfaceOrientationPortraitUpsideDown: {
            return AVCaptureVideoOrientationPortraitUpsideDown;
        }
            default:
            return AVCaptureVideoOrientationPortrait;
    }
}

- (void)beautify {
    
    
    [self.videoCamera removeAllTargets];
    GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.videoCamera addTarget:beautifyFilter];
    [beautifyFilter addTarget:self.filterView];
    
//    关闭
//    [self.videoCamera removeAllTargets];
//    [self.videoCamera addTarget:self.filterView];

}

- (UILabel *)faceBorderLab {
    if (_faceBorderLab == nil) {
        _faceBorderLab = [[UILabel alloc] init];
        _faceBorderLab.backgroundColor = [UIColor clearColor];
        _faceBorderLab.layer.borderColor = [UIColor blackColor].CGColor;
        _faceBorderLab.layer.borderWidth = 2;
    }
    return _faceBorderLab;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
