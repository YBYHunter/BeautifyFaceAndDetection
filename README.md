# BeautifyFaceDemo

It's a simple demo of realtime face beautification based on GPUImage

GPUImageBeautifyFilter is my custom beauty filter which can be used to beautify live video or static images.

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
