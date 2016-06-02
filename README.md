# BeautifyFaceDemo

基于GPUImage的人脸磨皮、美白、提亮的美颜滤镜

GPUImageBeautifyFilter是一个自定义的美颜滤镜，可以用来处理实时视频流或者是静态图片

主要原理是双边滤波、Canny边缘检测和肤色检测

# Sample Code
You can easily beautify a live video using the following code:
<pre><code> 
GPUImageVideoCamera *videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;

GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, viewHeight)];

GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
[videoCamera addTarget:beautifyFilter];
[beautifyFilter addTarget:filterView];

[videoCamera startCameraCapture];
</code></pre>


# Reference
http://www.csie.ntu.edu.tw/~fuh/personal/FaceBeautificationandColorEnhancement.A2-1-0040.pdf

http://m.blog.csdn.net/article/details?id=50496969
