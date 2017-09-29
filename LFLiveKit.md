###整体架构

以`LFLiveSession`为中心切分成3部分：

* 前面是音视频的数据采集
* 后面是音视频数据推送到服务器
* 中间是音视频数据的编码

数据采集分为视频和音频：

* 视频由相机和一系列的滤镜组成，最后输出到预览界面(preview)和`LFLiveSession`
* 音频使用`AudioUnit`读取音频，输出到`LFLiveSession`

编码部分：

* 视频提供软编码和硬编码，硬编码使用VideoToolBox。编码h264
* 音频提供AudioToolBox的硬编码,编码AAC

推送部分：

* 编码后的音视频按帧装入队列，循环推送
* 容器采用FLV，按照FLV的数据格式组装
* 使用librtmp库进行推送。


###视频采集

视频采集部分内容比较多，可以分为几点：

* 相机
* 滤镜
* 链式图像处理方案
* opengl es

核心类，也是承担控制器角色的是`LFVideoCapture`,负责组装相机和滤镜，管理视频数据流。

#####相机

相机的核心类是`GPUImageVideoCamera`

视频采集使用系统库`AVFoundation`的`AVCaptureSession`，所以就是常规性的几步：

 1. 构建`AVCaptureSession`:`_captureSession = [[AVCaptureSession alloc] init];`
 2. 配置输入和输出，输入是设备，一般就有前后摄像头的区别
 
  ```
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) 
	{
		if ([device position] == cameraPosition)
		{
			_inputCamera = device;
		}
	}
	
	.....
	NSError *error = nil;
	videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_inputCamera error:&error];
	if ([_captureSession canAddInput:videoInput]) 
	{
		[_captureSession addInput:videoInput];
	}
  ```
 3. 输出可以是文件也可以是数据，这里因为要推送到服务器，而且也为了后续的图像处理，显然要用数据输出。
 
  ```
  videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setAlwaysDiscardsLateVideoFrames:NO];
	......
	[videoOutput setSampleBufferDelegate:self queue:cameraProcessingQueue];
	if ([_captureSession canAddOutput:videoOutput])
	{
		[_captureSession addOutput:videoOutput];
	}
  ```
  中间还一大段`captureAsYUV`为YES时执行的代码，有两种方式，一个是相机输出YUV格式，然后转成RGBA，还一种是直接输出BGRA，然后转成RGBA。前一种对应的是`kCVPixelFormatType_420YpCbCr8BiPlanarFullRange`或`kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`，后一种对应的是`kCVPixelFormatType_32BGRA`,相机数据输出格式只接受这3种。中间的这一段的目的就是设置相机输出YUV,然后再转成RGBA。OpenGL和滤镜的问题先略过。
  
  >这里有个问题：h264编码时用的是YUV格式的，这里输出RGB然后又转回YUV不是浪费吗？还有输出YUV，然后自己转成RGB,然后编码时再转成YUV不是傻？如果直接把输出的YUV转码推送会怎么样？考虑到滤镜的使用，滤镜方便处理YUV格式的图像吗？
  
  >这些问题以后再深入研究，先看默认的流程里的处理原理。
  
  
配置完session以及输入输出，开启session后，数据从设备采集，然后调用dataOutput的委托方法：`captureOutput:didOutputSampleBuffer:fromConnection`

这里还有针对audio的处理，但音频不是在这采集的，这里的audio没启用，可以直接忽略先。

然后到方法`processVideoSampleBuffer:`，代码不少，干的就一件事：把相机输出的视频数据转到RGBA的格式的texture里。然后调用`updateTargetsForVideoCameraUsingCacheTextureAtWidth`这个方法把处理完的数据传递给下一个图像处理组件。


整体而言，相机就是收集设备的视频数据，然后倒入到图像处理链里。所以要搞清楚视频输出怎么传递到预览界面和`LFLiveSession `的，需要先搞清楚滤镜/图像处理链是怎么传递数据的。

#####图像处理链

这里有两种处理组件：`GPUImageOutput`和`GPUImageInput`。

`GPUImageOutput`有一个target的概念的东西，在它处理完一个图像后，把图像传递给它的target。而`GPUImageInput`怎么接受从其他对象那传递过来的图像。通过这两个组件，就可以把一个图像从一个组件传递另一个组件，形成链条。

而且可以是交叉性的，比如A输出到B和C，然后C输出到D，然后B和D可以同时输出到E。也就是输出对象和输入对象都不是单一的，所以非常灵活。也很适合图像处理的这种应用情景。

>我比较好奇的是为什么`GPUImageOutput`定义成了类，而`GPUImageInput `却是协议，这也是值得思考的问题。

有了这两个组件的认识，再去到`LFVideoCapture`的`reloadFilter`方法。在这里，它把视频采集的处理链组装起来了，在这可以很清晰的看到图像数据的流动路线。

相机组件`GPUImageVideoCamera`继承于`GPUImageOutput`,它会把数据输出到它的target.

```
//< 480*640 比例为4:3  强制转换为16:9
if([self.configuration.avSessionPreset isEqualToString:AVCaptureSessionPreset640x480]){
        CGRect cropRect = self.configuration.landscape ? CGRectMake(0, 0.125, 1, 0.75) : CGRectMake(0.125, 0, 0.75, 1);
        self.cropfilter = [[GPUImageCropFilter alloc] initWithCropRegion:cropRect];
        [self.videoCamera addTarget:self.cropfilter];
        [self.cropfilter addTarget:self.filter];
    }else{
        [self.videoCamera addTarget:self.filter];
    }
```
如果是640x480的分辨率，则路线是：videoCamera --> cropfilter --> filter,否则是videoCamera --> filter。

其他部分类似，就是条件判断是否加入某个组件，最后都会输出到：`self.gpuImageView`和`self.output`。

`self.gpuImageView`是视频预览图的内容视图,设置preview的代码：

```
- (void)setPreView:(UIView *)preView {
    if (self.gpuImageView.superview) [self.gpuImageView removeFromSuperview];
    [preView insertSubview:self.gpuImageView atIndex:0];
    self.gpuImageView.frame = CGRectMake(0, 0, preView.frame.size.width, preView.frame.size.height);
}
```

有了这个就可以看到经过一系列处理的视频图像了，这个是给拍摄者自己看到。

`self.output`本身没什么内容，只是作为最后一个节点，把内容往外界传递出去：

```
    __weak typeof(self) _self = self;
    [self.output setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
       [_self processVideo:output];
    }];
    
    ......
    
    - (void)processVideo:(GPUImageOutput *)output {
    __weak typeof(self) _self = self;
    @autoreleasepool {
        GPUImageFramebuffer *imageFramebuffer = output.framebufferForOutput;
        CVPixelBufferRef pixelBuffer = [imageFramebuffer pixelBuffer];
        
        if (pixelBuffer && _self.delegate && [_self.delegate respondsToSelector:@selector(captureOutput:pixelBuffer:)]) {
            [_self.delegate captureOutput:_self pixelBuffer:pixelBuffer];
        }
    }
}
```

`self.delegate`就是`LFLiveSession`对象，视频数据就流到了session部分，进入编码阶段。

#####滤镜和OpenGL
