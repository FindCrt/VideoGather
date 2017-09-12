//
//  VRColorSpaceExchanger.h
//  VedioRecord
//
//  Created by shiwei on 16/4/19.
//  Copyright © 2016年 施卫. All rights reserved.
//


#ifndef VRColorSpaceExchanger_h
#define VRColorSpaceExchanger_h

#include <stdio.h>

static void YUV420p_to_RGB24(unsigned char *yuv420[3], unsigned char *rgb24, int width, int height)
{
    int R,G,B,Y,U,V;
    int x,y;
    int nWidth = width>>1; //色度信号宽度
    for (y=0;y<height;y++)
    {
        for (x=0;x<width;x++)
        {
            Y = *(yuv420[0] + y*width + x);
            U = *(yuv420[1] + ((y>>1)*nWidth) + (x>>1));
            V = *(yuv420[2] + ((y>>1)*nWidth) + (x>>1));
            R = Y + 1.402*(V-128);
            G = Y - 0.34414*(U-128) - 0.71414*(V-128);
            B = Y + 1.772*(U-128);
            
            //防止越界
            if (R>255)R=255;
            if (R<0)R=0;
            if (G>255)G=255;
            if (G<0)G=0;
            if (B>255)B=255;
            if (B<0)B=0;
            
            *(rgb24 + (y*width + x)*3) = R;
            *(rgb24 + (y*width + x)*3 + 1) = G;
            *(rgb24 + (y*width + x)*3 + 2) = B;
        }
    }
}


static void NV12_to_YUV420p(unsigned char *N12[2], unsigned char *yuv420[3], int width ,int height){
    
    unsigned char *yuvBuffer = (unsigned char*)malloc(width * height * 3 / 2);
    yuv420[0] = yuvBuffer;                          //Y的开头地址
    yuv420[1] = yuvBuffer + width * height;         //U的开头地址
    yuv420[2] = yuvBuffer + width * height * 5 / 4; //V的开头地址
    
    unsigned char *yBaseAdrr = N12[0];
    for (int i = 0; i< width * height; i++) {
        yuvBuffer[i] = yBaseAdrr[i];
    }
    
    unsigned char *uvBaseAdrr = N12[1];
    
    //每次取两个，第一个值为U,第二个值为V
    unsigned char *Pu = yuv420[1];
    unsigned char *Pv = yuv420[2];
    for (int i = 0; i< width * height / 2; i += 2) {
        char U = uvBaseAdrr[i];
        char V = uvBaseAdrr[i+1];
        
        *(Pu++) = U;
        *(Pv++) = V;
    }
}


#endif /* VRColorSpaceExchanger_h */
