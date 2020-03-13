#pragma once

#ifdef __cplusplus
extern "C"
{
#endif


#include "reverb.h"

typedef signed short                    SInt16;

#if __LP64__
    typedef unsigned int                    UInt32;
    typedef signed int                      SInt32;
#else
    typedef unsigned long                   UInt32;
    typedef signed long                     SInt32;
#endif


//#define UInt32 unsigned long
//#define SInt16 short
#define OSStatus int
#define noErr 0

//�����������
Reverb* createReverb();
OSStatus deleteReverb(Reverb* pobj);

//��������
OSStatus simpleDelay1 (Reverb* pobj, //�������
					  void *inRefCon, // scope reference
					  UInt32 inNumberFrames, // number of frames to process
					  SInt16 *sampleBuffer,//����
					  int samplingFreqHz, 
					  int channelNum);//�Ƿ�˫����

//��������
OSStatus setReverbParem(Reverb* pobj,
						float drytime, 
						float wettime, 
						float dampness, 
						float roomwidth, 
						float roomsize);

//��ȡ����
OSStatus getReverbParem(Reverb* pobj,
						float* drytime, 
						float* wettime, 
						float* dampness, 
						float* roomwidth, 
						float* roomsize);



#ifdef __cplusplus
}
#endif