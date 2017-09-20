* 以LFLiveSession为分界点，切面是相机到目标数据的处理过程，包含各种图像处理，有滤镜、颜色空间转换、OpenGLES渲染等，之后是把数据推送到服务器。
* 链式滤镜：使用texture输入，输出到FBO,而FBO的内容是还是texture。这样完成了从纹理到纹理的转变，下一次处理还是纹理，因为输入和输出相同，可以建立链式处理。
* 相机的视频数据流：videoCamera --> GPUImageCropFilter --> filter(LFGPUImageBeautyFilter) --> output(LFGPUImageEmptyFilter) --> gpuImageView
* GPUImageOutput是类，GPUImageInput是协议，不知为什么这么设计。
* 所有图像处理都是FBO到FBO，但中间件前后FBO挂载的是texture,但gpuImageView结果挂载的是renderBuffer，和CAEAGLLayer共享内存，因为是用来显示，不再进行下一步的处理了。
* 图像链式处理，是可以开多个output的，也就是多个输出，某个环节只负责一个任务。然后FBO使用引用计数的方式来管理回收、重用。
* GPUImageFilter有一个frameProcessingCompletionBlock，在本环节图像处理完之后，调用这个完成的block. videoCapture的output调用这个回到videoCapture的processVideo，然后把数据通过delegate到liveSession，在liveSession里再完成音视频的编码，videoEncoder。编码完之后推送到服务器。

* 总体分为3部分：视频捕获和处理、编码、推送。

* sps和pps的头信息流是：
 * iIndex:23,sps_len:10 
 * iIndex:30, pps_len:4 
 * 17 00 00 00 00 01 4d 00 1e ff e1 00 0a 27 4d 00 1e ab 40 b8 28 f2 e8 01 00 04 28 ee 3c 30

* videoToolBox编码关键方法：VTCompressionSessionCreate， VTCompressionSessionEncodeFrame和指定的编码后的回调VideoCompressonOutputCallback。
* 编码后从CMSampleBufferRef中得到的数据注意：1. 以MP4风格存放，即[长度值][数据][长度值][数据]，长度值是4个字节，长度值是数据的长度。 2.长度值是大端模式的
* 从写入文件中的代码看：1. 头信息确实是 00 00 00 01或00 00 01；2. 类型数据时直接在数据里的，不需要额外添加。
* 流的数据格式是根据flv的方式组装的，所以跟写入h264文件不同。

* GPUImageVideoCamera流程：
 * captureSession的配置：相机前后、输出分辨率、输出格式(YUV/BGRA)、YUV转RGB的OpenGL program
 * 数据输出从`captureOutput`开始，视频到`processVideoSampleBuffer`
 * 如果需要转格式，则从YUV转到RGBA,使用OpenGL程序渲染一次，输入Y和UV的texture，以RGBA的格式输出到的frameBuffer的texture,frameBuffer只是一段数据，本身不带格式标记的，只是OpenGL的fragmentShader里输出color是按RGBA来排列的。不用转，直接数据导入到新的RGBA纹理中。这时是空壳frameBuffer.
 * `updateTargetsForVideoCameraUsingCacheTextureAtWidth`这里是传递frameBuffer到下一个处理点，和所有的滤镜一致。这里又回到了上一个抽象层次了。

* [GPUImageContext deviceSupportsRedTextures]里说的GL_RED_EXT的问题，这个有什么用？什么好处？什么情况下可用？
* [GPUImageContext sharedFramebufferCache] frameBuffer作为图象处理链中的输入输出，是重用的，有一个FBO池循环使用。
* `generateFramebuffer`注意一下构建frameBuffer的不同，特别是使用coreVideo的方法构建的FBO有什么区别。





