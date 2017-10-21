//
//  ExportAAC.cpp
//  VideoGather
//
//  Created by shiwei on 17/10/21.
//  Copyright © 2017年 shiwei. All rights reserved.
//

#include "ExportAAC.hpp"
#include <AudioToolbox/AudioToolbox.h>
#include <stdio.h>
#include <iostream>
using namespace std;

void writeNoiseToAudioFile(const char *fName,int mChannels,bool compress_with_m4a)
{
    OSStatus err; // to record errors from ExtAudioFile API functions
    
    // create file path as CStringRef
    CFStringRef fPath;
    fPath = CFStringCreateWithCString(kCFAllocatorDefault,
                                      fName,
                                      kCFStringEncodingMacRoman);
    
    
    // specify total number of samples per channel
    UInt32 totalFramesInFile = 100000;
    
    /////////////////////////////////////////////////////////////////////////////
    ////////////// Set up Audio Buffer List For Interleaved Audio ///////////////
    /////////////////////////////////////////////////////////////////////////////
    
    AudioBufferList outputData;
    outputData.mNumberBuffers = 1;
    outputData.mBuffers[0].mNumberChannels = mChannels;
    outputData.mBuffers[0].mDataByteSize = sizeof(AudioUnitSampleType)*totalFramesInFile*mChannels;
    
    
    
    /////////////////////////////////////////////////////////////////////////////
    //////// Synthesise Noise and Put It In The AudioBufferList /////////////////
    /////////////////////////////////////////////////////////////////////////////
    
    // create an array to hold our audio
    AudioUnitSampleType audioFile[totalFramesInFile*mChannels];
    
    // fill the array with random numbers (white noise)
    for (int i = 0;i < totalFramesInFile*mChannels;i++)
    {
        audioFile[i] = ((AudioUnitSampleType)(rand() % 100))/100.0;
        audioFile[i] = audioFile[i]*0.2;
        // (yes, I know this noise has a DC offset, bad)
    }
    
    // set the AudioBuffer to point to the array containing the noise
    outputData.mBuffers[0].mData = &audioFile;
    
    
    /////////////////////////////////////////////////////////////////////////////
    ////////////////// Specify The Output Audio File Format /////////////////////
    /////////////////////////////////////////////////////////////////////////////
    
    
    // the client format will describe the output audio file
    AudioStreamBasicDescription clientFormat;
    
    // the file type identifier tells the ExtAudioFile API what kind of file we want created
    AudioFileTypeID fileType;
    
    // if compress_with_m4a is tru then set up for m4a file format
    if (compress_with_m4a)
    {
        // the file type identifier tells the ExtAudioFile API what kind of file we want created
        // this creates a m4a file type
        fileType = kAudioFileM4AType;
        
        // Here we specify the M4A format
        clientFormat.mSampleRate         = 44100.0;
        clientFormat.mFormatID           = kAudioFormatMPEG4AAC;
        clientFormat.mFormatFlags        = kMPEG4Object_AAC_Main;
        clientFormat.mChannelsPerFrame   = mChannels;
        clientFormat.mBytesPerPacket     = 0;
        clientFormat.mBytesPerFrame      = 0;
        clientFormat.mFramesPerPacket    = 1024;
        clientFormat.mBitsPerChannel     = 0;
        clientFormat.mReserved           = 0;
    }
    else // else encode as PCM
    {
        // this creates a wav file type
        fileType = kAudioFileWAVEType;
        
        // This function audiomatically generates the audio format according to certain arguments
        FillOutASBDForLPCM(clientFormat,44100.0,mChannels,32,32,true,false,false);
    }
    
    
    
    /////////////////////////////////////////////////////////////////////////////
    ///////////////// Specify The Format of Our Audio Samples ///////////////////
    /////////////////////////////////////////////////////////////////////////////
    
    // the local format describes the format the samples we will give to the ExtAudioFile API
    AudioStreamBasicDescription localFormat;
    FillOutASBDForLPCM (localFormat,44100.0,mChannels,32,32,true,false,false);
    
    
    
    /////////////////////////////////////////////////////////////////////////////
    ///////////////// Create the Audio File and Open It /////////////////////////
    /////////////////////////////////////////////////////////////////////////////
    
    // create the audio file reference
    ExtAudioFileRef audiofileRef;
    
    // create a fileURL from our path
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,fPath,kCFURLPOSIXPathStyle,false);
    
    // open the file for writing
    err = ExtAudioFileCreateWithURL((CFURLRef)fileURL, fileType, &clientFormat, NULL, kAudioFileFlags_EraseFile, &audiofileRef);
    
    if (err != noErr)
    {
        cout << "Problem when creating audio file: " << err << "\n";
    }
    
    
    /////////////////////////////////////////////////////////////////////////////
    ///// Tell the ExtAudioFile API what format we'll be sending samples in /////
    /////////////////////////////////////////////////////////////////////////////
    
    // Tell the ExtAudioFile API what format we'll be sending samples in
    err = ExtAudioFileSetProperty(audiofileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(localFormat), &localFormat);
    
    if (err != noErr)
    {
        cout << "Problem setting audio format: " << err << "\n";
    }
    
    /////////////////////////////////////////////////////////////////////////////
    ///////// Write the Contents of the AudioBufferList to the AudioFile ////////
    /////////////////////////////////////////////////////////////////////////////
    
    UInt32 rFrames = (UInt32)totalFramesInFile;
    // write the data
    err = ExtAudioFileWrite(audiofileRef, rFrames, &outputData);
    
    if (err != noErr)
    {
        cout << "Problem writing audio file: " << err << "\n";
    }
    
    
    /////////////////////////////////////////////////////////////////////////////
    ////////////// Close the Audio File and Get Rid Of The Reference ////////////
    /////////////////////////////////////////////////////////////////////////////
    
    // close the file
    ExtAudioFileDispose(audiofileRef);
    
    
//    NSLog(@"Done!");
}
