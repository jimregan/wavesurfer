/* 
 * Copyright (C) 1997-2002 Kare Sjolander <kare@speech.kth.se>
 *
 * This file is part of the Snack Sound Toolkit.
 * The latest version can be found at http://www.speech.kth.se/snack/
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */
#include <string.h>
#include "tcl.h"
#include "jkAudIO.h"
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <portaudio.h>

extern void Snack_WriteLog(char *s);
extern void Snack_WriteLogInt(char *s, int n);

#ifndef min
#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))
#endif

#define SNACK_NUMBER_MIXERS 1
#define FRAMES_PER_BUFFER   (1024)

struct MixerLink mixerLinks[SNACK_NUMBER_MIXERS][2];

int
SnackAudioOpen(ADesc *A, Tcl_Interp *interp, char *device, int mode, int freq,
	       int nchannels, int encoding)
{
  PaStreamParameters      params, *inparams_p, *outparams_p;
  PaError                 err;

  // First set device to default 
  if (mode == PLAY) {  
    params.device = Pa_GetDefaultOutputDevice();
    A->wpos = 0;
  } else {
    params.device = Pa_GetDefaultInputDevice();
    A->rpos = 0;
  }

  // Then set to named device, if existing
  for (int i = 0; i < Pa_GetDeviceCount(); i++) {
    PaDeviceInfo* dev =  Pa_GetDeviceInfo(i);
    if (strncmp(dev->name,device,strlen(device)) == 0) {
      params.device = i;
      break;
    }
  }
 


  params.channelCount = nchannels;
  params.suggestedLatency = Pa_GetDeviceInfo(params.device)->defaultLowOutputLatency;
  params.hostApiSpecificStreamInfo = NULL;
  switch(encoding) {
  case LIN16:      
    params.sampleFormat = paInt16; 
    A->bytesPerSample   = 2; 
    break;
  case LIN8OFFSET: 
    params.sampleFormat = paUInt8; 
    A->bytesPerSample   = 1; 
    break;
  case LIN8:
    params.sampleFormat = paInt8; 
    A->bytesPerSample   = 1; 
    break;
  case LIN24:
    params.sampleFormat = paInt24; 
    A->bytesPerSample   = 3; 
    break;
  case LIN32:
    params.sampleFormat = paInt32;
    A->bytesPerSample   = 4; 
    break;
  case SNACK_FLOAT:
    params.sampleFormat = paFloat32;
    A->bytesPerSample   = 4; 
    break;
    
  default:
    Tcl_SetObjResult(interp,Tcl_ObjPrintf("for now unsupported encoding (%d)",encoding));
    return TCL_ERROR;
  }
  
  const PaDeviceInfo *devinfo = Pa_GetDeviceInfo(params.device);

  // {char tmp[1000]; sprintf(tmp,"  mode = %d\ndevice = %d\n  channelCount = %d\n  latency = %d\n  sampleFormat = %d\n",mode, params.device,params.channelCount,params.suggestedLatency,params.sampleFormat); Snack_WriteLog(tmp);}
  // {char tmp[1000];sprintf(tmp,"  deviceinfo - name = %s, maxInputChannels = %d, maxOutputChannels = %d\n",devinfo->name,devinfo->maxInputChannels,devinfo->maxOutputChannels); Snack_WriteLog(tmp);}

  A->nChannels = nchannels;
  A->mode = mode;
    
  if (mode == PLAY) {  
    
    A->time = SnackCurrentTime();
    inparams_p  = NULL;
    outparams_p = &params;
  } else {

    inparams_p  = &params;
    outparams_p = NULL;
  }

  err = Pa_OpenStream(&A->stream,inparams_p,outparams_p,(double)freq,FRAMES_PER_BUFFER,paClipOff,NULL, NULL);

  if(err != paNoError) {
    Tcl_SetObjResult(interp,Tcl_ObjPrintf("PortAudio error %s",Pa_GetErrorText(err)));
    return TCL_ERROR;
  }

  err = Pa_StartStream(A->stream);
  if(err != paNoError) {
    Tcl_SetObjResult(interp,Tcl_ObjPrintf("PortAudio error %s",Pa_GetErrorText(err)));
    return TCL_ERROR;
  }

  return TCL_OK;
}

int
SnackAudioClose(ADesc *A)
{  

  //  printf("  Pa_CloseStream()\n");

  Pa_CloseStream(A->stream);
  return(0);
}

long
SnackAudioPause(ADesc *A)
{
  return(-1);
}

void
SnackAudioResume(ADesc *A)
{
}

void
SnackAudioFlush(ADesc *A)
{
}

void
SnackAudioPost(ADesc *A)
{
}

int
SnackAudioRead(ADesc *A, void *buf, int nFrames)
{
  
  // if (nFrames)  {Snack_WriteLog("SnackAudioRead() nframes>0\n");}

  if (Pa_ReadStream(A->stream, buf, nFrames) == paNoError) {
    A->rpos += nFrames;

    return nFrames;
  } else {
    Snack_WriteLog("  err\n");
    return 0;
  }
}

int
SnackAudioWrite(ADesc *A, void *buf, int nFrames)
{
  // printf("writing audio: nframes=%d\n",nFrames);
  if (Pa_WriteStream(A->stream, buf, nFrames) == paNoError) {
    //printf("  wrote %d\n",nFrames);
    A->wpos += nFrames;
    return nFrames;
  } else {
    // printf("  write failed\n",nFrames);
    return 0;
  }
}

int SnackAudioReadable(ADesc *A) {
  int r = Pa_GetStreamReadAvailable(A->stream);

  return r;
}

int SnackAudioWriteable(ADesc *A) {  
  //printf("SnackAudioWriteable()\n");

  return Pa_GetStreamWriteAvailable(A->stream);
}

long
SnackAudioPlayed(ADesc *A)
{
  //printf("SnackAudioPlayed()\n");
  return A->wpos;
}

void
SnackAudioInit()
{
  PaError err;

  /* initialise portaudio subsytem */
  err = Pa_Initialize();
  if(err != paNoError) {
    fprintf(stderr,"PortAudio error #%d",err);
  }

  // requestMicAccess();
  
}

void
SnackAudioFree()
{
  int i, j;

  for (i = 0; i < SNACK_NUMBER_MIXERS; i++) {
    for (j = 0; j < 2; j++) {
      if (mixerLinks[i][j].mixer != NULL) {
	ckfree(mixerLinks[i][j].mixer);
      }
      if (mixerLinks[i][j].mixerVar != NULL) {
	ckfree(mixerLinks[i][j].mixerVar);
      }
    }
    if (mixerLinks[i][0].jack != NULL) {
      ckfree(mixerLinks[i][0].jack);
    }
    if (mixerLinks[i][0].jackVar != NULL) {
      ckfree((char *)mixerLinks[i][0].jackVar);
    }
  }
}

void
ASetRecGain(int gain)
{
  int g = min(max(gain, 0), 100);
}

void
ASetPlayGain(int gain)
{
  int g = min(max(gain, 0), 100);
}

int
AGetRecGain()
{
  int g = 0;

  return(g);
}

int
AGetPlayGain()
{
  int g = 0;

  return(g);
}

int
SnackAudioGetEncodings(char *device)
{
  return(LIN16);
}

void
SnackAudioGetRates(char *device, char *buf, int n)
{
  strncpy(buf, "8000 11025 16000 22050 32000 44100 48000", n);
  buf[n-1] = '\0';
}

int
SnackAudioMaxNumberChannels(char *device)
{
  for (int i = 0; i < Pa_GetDeviceCount(); i++) {
    PaDeviceInfo* dev =  Pa_GetDeviceInfo(i);
    if (strncmp(dev->name,device,strlen(device)) == 0) {
      return(max(dev->maxInputChannels,dev->maxOutputChannels));
    }
  }
  return 0;
}

int
SnackAudioMinNumberChannels(char *device)
{
  return(1);
}

void
SnackMixerGetInputJackLabels(char *buf, int n)
{
  buf[0] = '\0';
}

void
SnackMixerGetOutputJackLabels(char *buf, int n)
{
  buf[0] = '\0';
}

void
SnackMixerGetInputJack(char *buf, int n)
{
  buf[0] = '\0';
}

int
SnackMixerSetInputJack(Tcl_Interp *interp, char *jack, CONST84 char *status)
{
  return 1;
}

void
SnackMixerGetOutputJack(char *buf, int n)
{
  buf[0] = '\0';
}

void
SnackMixerSetOutputJack(char *jack, char *status)
{
}

void
SnackMixerGetChannelLabels(char *line, char *buf, int n)
{
  strncpy(buf, "Mono", n);
  buf[n-1] = '\0';
}

void
SnackMixerGetVolume(char *line, int channel, char *buf, int n)
{
  if (strncasecmp(line, "Play", strlen(line)) == 0) {
    sprintf(buf, "%d", AGetPlayGain());
  } 
}

void
SnackMixerSetVolume(char *line, int channel, int volume)
{
  if (strncasecmp(line, "Play", strlen(line)) == 0) {
    ASetPlayGain(volume);
  } 
}

void
SnackMixerLinkJacks(Tcl_Interp *interp, char *jack, Tcl_Obj *var)
{
}

static char *
VolumeVarProc(ClientData clientData, Tcl_Interp *interp, CONST84 char *name1,
	      CONST84 char *name2, int flags)
{
  MixerLink *mixLink = (MixerLink *) clientData;
  CONST84 char *stringValue;
  
  if (flags & TCL_TRACE_UNSETS) {
    if ((flags & TCL_TRACE_DESTROYED) && !(flags & TCL_INTERP_DESTROYED)) {
      Tcl_Obj *obj, *var;
      char tmp[VOLBUFSIZE];

      SnackMixerGetVolume(mixLink->mixer, mixLink->channel, tmp, VOLBUFSIZE);
      obj = Tcl_NewIntObj(atoi(tmp));
      var = Tcl_NewStringObj(mixLink->mixerVar, -1);
      Tcl_ObjSetVar2(interp, var, NULL, obj, TCL_GLOBAL_ONLY | TCL_PARSE_PART1);
      Tcl_TraceVar(interp, mixLink->mixerVar,
		   TCL_GLOBAL_ONLY|TCL_TRACE_WRITES|TCL_TRACE_UNSETS,
		   VolumeVarProc, (int *)mixLink);
    }
    return (char *) NULL;
  }
  stringValue = Tcl_GetVar(interp, mixLink->mixerVar, TCL_GLOBAL_ONLY);
  if (stringValue != NULL) {
    SnackMixerSetVolume(mixLink->mixer, mixLink->channel, atoi(stringValue));
  }

  return (char *) NULL;
}

void
SnackMixerLinkVolume(Tcl_Interp *interp, char *line, int n,
		     Tcl_Obj *CONST objv[])
{
  char *mixLabels[] = { "Play" };
  int i, j, channel;
  CONST84 char *value;
  char tmp[VOLBUFSIZE];

  for (i = 0; i < SNACK_NUMBER_MIXERS; i++) {
    if (strncasecmp(line, mixLabels[i], strlen(line)) == 0) {
      for (j = 0; j < n; j++) {
	if (n == 1) {
	  channel = -1;
	} else {
	  channel = j;
	}
	mixerLinks[i][j].mixer = (char *)SnackStrDup(line);
	mixerLinks[i][j].mixerVar = (char *)SnackStrDup(Tcl_GetStringFromObj(objv[j+3], NULL));
	mixerLinks[i][j].channel = j;
	value = Tcl_GetVar(interp, mixerLinks[i][j].mixerVar, TCL_GLOBAL_ONLY);
	if (value != NULL) {
	  SnackMixerSetVolume(line, channel, atoi(value));
	} else {
	  Tcl_Obj *obj;
	  SnackMixerGetVolume(line, channel, tmp, VOLBUFSIZE);
	  obj = Tcl_NewIntObj(atoi(tmp));
	  Tcl_ObjSetVar2(interp, objv[j+3], NULL, obj, 
			 TCL_GLOBAL_ONLY | TCL_PARSE_PART1);
	}
	Tcl_TraceVar(interp, mixerLinks[i][j].mixerVar,
		     TCL_GLOBAL_ONLY|TCL_TRACE_WRITES|TCL_TRACE_UNSETS,
		     VolumeVarProc, (ClientData) &mixerLinks[i][j]);
      }
    }
  }
}

void
SnackMixerUpdateVars(Tcl_Interp *interp)
{
  int i, j;
  char tmp[VOLBUFSIZE];
  Tcl_Obj *obj, *var;

  for (i = 0; i < SNACK_NUMBER_MIXERS; i++) {
    for (j = 0; j < 2; j++) {
      if (mixerLinks[i][j].mixerVar != NULL) {
	SnackMixerGetVolume(mixerLinks[i][j].mixer, mixerLinks[i][j].channel,
			    tmp, VOLBUFSIZE);
	obj = Tcl_NewIntObj(atoi(tmp));
	var = Tcl_NewStringObj(mixerLinks[i][j].mixerVar, -1);
	Tcl_ObjSetVar2(interp, var, NULL, obj, TCL_GLOBAL_ONLY|TCL_PARSE_PART1);
      }
    }
  }
}

void
SnackMixerGetLineLabels(char *buf, int n)
{
  strncpy(buf, "Play", n);
  buf[n-1] = '\0';
}




int
SnackGetOutputDevices(char **arr, int n)
{

  //arr[0] = (char *) SnackStrDup("default");
  int count = 0;
  for (int i = 0; i < Pa_GetDeviceCount(); i++) {
    PaDeviceInfo* dev =  Pa_GetDeviceInfo(i);
    if (dev->maxOutputChannels > 0) {
      arr[count++] = SnackStrDup(dev->name);
    }
    if (count >= MAX_NUM_DEVICES) return count;
  }
  
  return count;
}

int
SnackGetInputDevices(char **arr, int n)
{
  // arr[0] = (char *) SnackStrDup("default");
  int count = 0;
  for (int i = 0; i < Pa_GetDeviceCount(); i++) {
    PaDeviceInfo* dev =  Pa_GetDeviceInfo(i);
    if (dev->maxInputChannels > 0) {
      arr[count++] = SnackStrDup(dev->name);
    }
    if (count >= MAX_NUM_DEVICES) return count;
  }
  
  return count;
}

int
SnackGetMixerDevices(char **arr, int n)
{
  arr[0] = (char *) SnackStrDup("default");

  return 1;
}
