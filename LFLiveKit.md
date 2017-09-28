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

 * 构建`AVCaptureSession`:`_captureSession = [[AVCaptureSession alloc] init];`
 * 配置输入和输出，输入是设备，一般就有前后摄像头的区别
 
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
 * 输出可以是文件也可以是数据，这里因为要推送到服务器，而且也为了后续的图像处理，显然要用数据输出。
 
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
  中间还一大段`captureAsYUV`为YES时执行的代码，是用来把
 * 