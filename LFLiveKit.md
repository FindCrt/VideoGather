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

滤镜的实现部分，先看一个简单的例子：`GPUImageCropFilter`。在上面也用到了，就是用来做裁剪的。

它继承于`GPUImageFilter`,而`GPUImageFilter`继承于`GPUImageOutput <GPUImageInput>`,它既是一个output也是input。

作为input，会接收处理的图像,看`GPUImageVideoCamera`的`updateTargetsForVideoCameraUsingCacheTextureAtWidth`方法可以知道，传递给input的方法有两个：

 * `setInputFramebuffer:atIndex`: 这个是传递`GPUImageFramebuffer`对象
 * `newFrameReadyAtTime:atIndex:` 这个才是开启下一环节的处理。

`GPUImageFramebuffer`是LFLiveKit封装的数据，用来在图像处理组件之间传递，包含了图像的大小、纹理、纹理类型、采样格式等。在图像处理链里传递图像，肯定需要一个统一的类型，除了图像本身，肯定还需要关于图像的信息，这样每个组件可以按相同的标准对待图像。`GPUImageFramebuffer`就起的这个作用。

`GPUImageFramebuffer`内部核心的东西是`GLuint framebuffer`,即OpenGL里的frameBufferObject(FBO).关于FBO我也不是很了解，只知道它像一个容器，可以挂载了render buffer、texture、depth buffer等，也就是原本渲染输出到屏幕的东西，可以输出到一个FBO，然后可以拿这个渲染的结果进行再一次的处理。

![FBO的结构图](http://my.csdn.net/uploads/201206/26/1340675754_8379.png)

在这个项目里，就是在FBO上挂载纹理，一次图像处理就是经历一次OpenGL渲染，处理前的图像用纹理的形式传入OpenGL，经历渲染流程输出到FBO, 图像数据就输出到FBO绑定的纹理上了。这样做了一次处理后数据结构还是一样，即绑定texture的FBO，可以再作为输入源提供给下一个组件。

FBO的构建具体看`GPUImageFramebuffer `的方法`generateFramebuffer`。

最后还一个值得学习的是`GPUImageFramebuffer`使用了一个缓存池，核心类`GPUImageFramebufferCache`。从流程里可以看得出`GPUImageFramebuffer`它是一个中间量，从组件A传递给组件B之后，B会使用这个framebuffer,B调用framebuffer的`lock`，使用完之后调用`unlock`。跟OC内存管理里的引用计数原理类似，`lock`引用计数+1，`unlock`-1，引用计数小于1就回归缓存池。需要一个新的frameBuffer的时候从优先从缓存池里拿，没有才构建。这一点又跟tableView的cell重用机制有点像。

**缓冲区是一个常用的功能,这种方案值得学习一下**

说完`GPUImageFramebuffer`,再回到`newFrameReadyAtTime:atIndex `方法。

它里面就两个方法：`renderToTextureWithVertices`这个是执行渲染，`informTargetsAboutNewFrameAtTime`是通知它的target，把图像传递给下一环节处理。

对`renderToTextureWithVertices`做一步步的解析：

* `[GPUImageContext setActiveShaderProgram:filterProgram];`内部做了两件事：`[EAGLContext setCurrentContext:imageProcessingContext];`把contex切换到图像处理的context, context这种东西就是用来把一些东西关联在一起的，执行的OpenGL函数`glxxx`为什么起作用，回执的结果为什么知道输出到哪个FBO,靠的就是它们关联在同一个context下。`[shaderProgram use]`开启`program`使用，`program`关联了vertext shader和fragment shader,也就是它知道这个渲染程序到底要干啥。总结来说就是：环境切换好了，程序开启了。
* 设置FBO接收输出：

 ```
    outputFramebuffer = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
```
* 然后就是一群gl开头的OpenGL ES的函数，先清空颜色缓冲区，在把`[firstInputFramebuffer texture]`作为输入传递，然后传入`vertices`作为顶点数据，`textureCoordinates`作为纹理坐标，最后`glDrawArrays`绘制一个矩形。这一段需要配合shader代码来看。

上面的这些都是`GPUImageFilter`这个基类的，再回到`GPUImageCropFilter`这个裁剪功能的滤镜里。

它的贡献是根据裁剪区域的不同，提供了不同的`textureCoordinates`,这个是纹理坐标。它的init方法里使用的shader是`kGPUImageCropFragmentShaderString`，核心也就一句话：`gl_FragColor = texture2D(inputImageTexture, textureCoordinate);`,使用纹理坐标采样纹理。所以对于输出结果而言，`textureCoordinates `就是关键因素。

然后再看`calculateCropTextureCoordinates`方法，纹理坐标是怎么计算的。

顶点数据是：

```
static const GLfloat cropSquareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
```
只有4个顶点，因为绘制矩形时使用的是`GL_TRIANGLE_STRIP`图元。OpenGL的坐标是y向上，x向右，配合顶点数据可知4个角的索引是这个样子的：

|2|3|
|:--:|:--:|
|0|1|

而纹理坐标跟OpenGL坐标是上下颠倒的：
![纹理坐标](http://images2015.cnblogs.com/blog/782376/201610/782376-20161016200410077-635750941.png)

所以在没有旋转的情况下,，顶点0对应纹理左下角,左下角是（0，0），考虑到裁剪，那么顶点0纹理坐标采用(minX, minY)。