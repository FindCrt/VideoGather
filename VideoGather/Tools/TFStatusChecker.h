//
//  TFStatusChecker.h
//  VideoGather
//
//  Created by shiwei on 17/10/25.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef TFStatusChecker
#define TFStatusChecker

#define TFCheckStatus(status, log)    if(status != 0) {\
int bigEndian = CFSwapInt32HostToBig(status);\
char *statusTex = (char*)&bigEndian;\
NSLog(@"%@ error: %s",log,statusTex); return;\
}

#define TFCheckStatusReturnStatus(status, log)    if(status != 0) {\
int bigEndian = CFSwapInt32HostToBig(status);\
char *statusTex = (char*)&bigEndian;\
NSLog(@"%@ error: %s",log,statusTex); return status;\
}

#define TFCheckStatusUnReturn(status, log)    if(status != 0) {\
uint64_t bigEndian = CFSwapInt32HostToBig(status);\
char *statusTex = (char*)&bigEndian;\
NSLog(@"%@ error: %s",log,statusTex);\
}

#define TFCheckStatusGoToFail(status, log)    if(status != 0) {\
int bigEndian = CFSwapInt32HostToBig(status);\
char *statusTex = (char*)&bigEndian;\
NSLog(@"%@ error: %s",log,statusTex); goto fail;\
}

#define TFCheckError(error, log)    if(error) {\
NSLog(@"%@ error:\n{%@}",log,error); return;\
}

#endif
