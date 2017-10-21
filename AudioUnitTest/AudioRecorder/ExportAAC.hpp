//
//  ExportAAC.hpp
//  VideoGather
//
//  Created by shiwei on 17/10/21.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#ifndef ExportAAC_hpp
#define ExportAAC_hpp

#include <stdio.h>

extern "C" void writeNoiseToAudioFile(const char *fName,int mChannels,bool compress_with_m4a);

#endif /* ExportAAC_hpp */
