//
//  VRvideoEncoder.m
//  videoRecord
//
//  Created by shiwei on 16/4/20.
//  Copyright © 2016年 施卫. All rights reserved.
//

#import "VRVideoEncoder.h"
#import "VRColorSpaceExchanger.h"
#import <CoreMedia/CoreMedia.h>
#ifdef __cplusplus
extern "C" {
#endif
    
#include <libavutil/opt.h>
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/imgutils.h>
    
#ifdef __cplusplus
};
#endif

#define noVideoStreamIndex  -1
#define UsingN12        0

@implementation VRVideoEncoder{
//    int64_t test_pts;
    NSString *_filePath;
    AVFormatContext *_outputFormatCtx;
    AVCodecContext *_outputCodecCtx;
    CGSize _outputSize;
    int videoStreamIndex;
    AVFrame *pFrame;
    AVPacket pkt;
    
    AVStream *outputStream;
    
    int64_t _startTime;
    AVRational _srcTimeBase;
}

-(BOOL)setupWithOutputPath:(NSString *)filePath videoSize:(CGSize)videoSize timeScale:(int)timeScale startTime:(int64_t)startTime{
    _filePath = filePath;
    _outputSize = videoSize;
    videoStreamIndex = noVideoStreamIndex;
    _startTime = startTime;
    _srcTimeBase.den = timeScale;
    _srcTimeBase.num = 1;
    
    printf("timeScale: %d\n",timeScale);
    
    av_register_all();
    
    _outputFormatCtx = avformat_alloc_context();
    AVOutputFormat *outputFormat = av_guess_format(NULL, [_filePath UTF8String], NULL);
    _outputFormatCtx->oformat = outputFormat;
    
    //打开文件
    if (avio_open(&_outputFormatCtx->pb, [_filePath UTF8String], AVIO_FLAG_READ_WRITE) < 0){
        NSLog(@"打开文件错误");
        return NO;
    }
    
    //打开输出流
    outputStream = avformat_new_stream(_outputFormatCtx, 0);
    if (outputStream == NULL) {
        NSLog(@"打开输出流错误");
        return NO;
    }
    av_dict_set(&outputStream->metadata,"rotate","90",0);
//    outputStream->time_base.num = 1;
//    outputStream->time_base.den = 30;
    
    videoStreamIndex = outputStream->index;
    
    _outputCodecCtx = outputStream->codec;
    _outputCodecCtx->codec_id = AV_CODEC_ID_H264;  //outputFormat->video_codec;
    _outputCodecCtx->codec_type = AVMEDIA_TYPE_VIDEO;
#if UsingN12
    _outputCodecCtx->pix_fmt = AV_PIX_FMT_NV12;
#else
    _outputCodecCtx->pix_fmt = AV_PIX_FMT_YUV420P;
#endif

    _outputCodecCtx->width = _outputSize.width;
    _outputCodecCtx->height = _outputSize.height;
    _outputCodecCtx->time_base.num = 1;
    _outputCodecCtx->time_base.den = 30;
    _outputCodecCtx->bit_rate = 1600000;
    _outputCodecCtx->gop_size = 150;
    _outputCodecCtx->keyint_min =30;
    _outputCodecCtx->thread_count =15;
    _outputCodecCtx->me_range = 16;
    _outputCodecCtx->max_qdiff = 4;
    _outputCodecCtx->qcompress = 0.6;
    
    _outputCodecCtx->max_b_frames = 0;
    _outputCodecCtx->b_frame_strategy = true;
    
    _outputCodecCtx->qmin = 16;
    _outputCodecCtx->qmax = 24;
    
    av_opt_set(_outputCodecCtx->priv_data, "preset", "ultrafast", 0);
    av_opt_set(_outputCodecCtx->priv_data, "tune", "zerolatency", 0);
    
    AVDictionary *param = 0;
    av_dict_set(&param, "preset", "ultrafast", 0);
    av_dict_set(&param, "tune", "zerolatency", 0);
    
    AVCodec* codec = avcodec_find_encoder(_outputCodecCtx->codec_id);
    if (!codec) {
        printf("can't find codec!\n");
        return NO;
    }
    int retval = avcodec_open2(_outputCodecCtx, codec, &param);
    if (retval != 0) {
        printf("avcodec open error: %d\n",retval);
        return NO;
    }
    
    pFrame = av_frame_alloc();
    int picture_size = av_image_get_buffer_size(_outputCodecCtx->pix_fmt, _outputCodecCtx->width, _outputCodecCtx->height, 1);
    uint8_t *picture_buf = (uint8_t *)av_malloc(picture_size);
    av_image_fill_arrays(pFrame->data, pFrame->linesize, picture_buf, _outputCodecCtx->pix_fmt, _outputSize.width, _outputSize.height, 1);
    
//    av_new_packet(&pkt, 0);
    
    avformat_write_header(_outputFormatCtx, NULL);
    
    return YES;
    
}

-(void)encodeToH264ForPixelBuffer:(CVPixelBufferRef)pixelBuffer pts:(int64_t)pts duration:(int64_t)duration{
    
    
    if (!avcodec_is_open(_outputCodecCtx) || !av_codec_is_encoder(_outputCodecCtx->codec)){
        printf("encode when avcodec is not aviable\n");
        return;
    }
    
    if (CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly) == kCVReturnSuccess) {
        
        
        
        UInt8 *N12Buffer[2];
        for (unsigned long i = 0; i<2; i++) {
            N12Buffer[i] = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
        }
        
#if UsingN12
        pFrame->data[0] = N12Buffer[0];
        pFrame->data[1] = N12Buffer[1];
#else
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        
        uint8_t *yuv420Buffer[3];
        NV12_to_YUV420p(N12Buffer, yuv420Buffer, width , height);
        
        pFrame->data[0] = yuv420Buffer[0];
        pFrame->data[1] = yuv420Buffer[1];
        pFrame->data[2] = yuv420Buffer[2];
#endif
        
        pFrame->pts=av_rescale_q(pts-_startTime, _srcTimeBase, outputStream->time_base);
//        printf("framePts: %lld\n (pts: %lld) (time: %.6f)",pFrame->pts, pts-_startTime, pFrame->pts * av_q2d(outputStream->time_base));
        pFrame->width = _outputSize.width;
        pFrame->height = _outputSize.height;
        pFrame->format = _outputCodecCtx->pix_fmt;
        
        int retval = av_new_packet(&pkt,0);
        if (retval < 0) {
            printf("new packet error: %d\n",retval);
            goto unlock;
        }
        
        retval = avcodec_send_frame(_outputCodecCtx, pFrame);
        if (retval != 0) {
            printf("avcodec_send_frame error: %d\n",retval);
            goto unlock;
        }
        retval = avcodec_receive_packet(_outputCodecCtx, &pkt);
        if (retval != 0) {
            printf("avcodec_receive_packet error: %d\n",retval);
            goto unlock;
        }else{
//            printf("avcodec_receive_packet OK!");
        }
        
        printf("framePts: %lld\n",pkt.pts);
        
        pkt.stream_index = _outputFormatCtx->streams[videoStreamIndex]->index;
        
        if (av_write_frame(_outputFormatCtx, &pkt) < 0) {
            printf("写入frame出错\n");
            return;
        }
        av_packet_unref(&pkt);
        
    unlock:
        //free(yuv420Buffer[0]);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    }
}

-(void)finishedRecording{
    printf("finishedRecording1\n");
//    int ret = flush_encoder(_outputFormatCtx,0);
//    if (ret < 0) {
//        
//        printf("Flushing encoder failed\n");
//    }
    
    //写入尾部
    av_write_trailer(_outputFormatCtx);
    
    //释放资源
    if (videoStreamIndex != noVideoStreamIndex){
        avcodec_close(_outputFormatCtx->streams[videoStreamIndex]->codec);
        av_free(pFrame);
        videoStreamIndex = noVideoStreamIndex;
    }
    avio_close(_outputFormatCtx->pb);
    avformat_free_context(_outputFormatCtx);
    printf("finishedRecording2\n");
}

int flush_encoder(AVFormatContext *fmt_ctx,unsigned int stream_index)
{
    int ret;
    AVPacket enc_pkt;
    if (!(fmt_ctx->streams[stream_index]->codec->codec->capabilities &
          CODEC_CAP_DELAY))
        return 0;
    
    while (1) {
        enc_pkt.data = NULL;
        enc_pkt.size = 0;
        av_init_packet(&enc_pkt);
        
        ret = avcodec_send_frame(fmt_ctx->streams[stream_index]->codec, NULL);
        if (ret < 0) {
            printf("avcodec_send_frame error: %d\n",ret);
        }
        ret = avcodec_receive_packet(fmt_ctx->streams[stream_index]->codec, &enc_pkt);
        av_frame_free(NULL);
        if (ret < 0){
            printf("avcodec_receive_packet error: %d\n",ret);
            break;
        }
        printf("Flush Encoder: Succeed to encode 1 frame!\tsize:%5d\n",enc_pkt.size);
        /* mux encoded frame */
        ret = av_write_frame(fmt_ctx, &enc_pkt);
        if (ret < 0)
            break;
    }
    return ret;
}


@end
