/*
 * $Id: XMBridge.cpp,v 1.3 2005/05/24 15:21:01 hfriederich Exp $
 *
 * Copyright (c) 2005 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005 Hannes Friederich. All rights reserved.
 */

#include <ptlib.h>

#include "XMBridge.h"

#include "XMOpalManager.h"
#include "XMVolumeControl.h"

using namespace std;

// reference to the active OPAL manager.
static XMOpalManager *theManager = NULL;

// required to implement the volume control
static XMSoundChannel *playerChannel = NULL;
static XMSoundChannel *recorderChannel = NULL;

void initOPAL()
{
	if(theManager == NULL)
	{
		XMOpalManager::InitOpal();
		
		theManager = new XMOpalManager;
		theManager->Initialise();
		
		/* workaround for the lack of useable volume control in OPAL's PCSSEndPoint */
		playerChannel = new XMSoundChannel(theManager->GetSoundChannelPlayDevice(), PSoundChannel::Player, 1, 8000, 16);
		recorderChannel = new XMSoundChannel(theManager->GetSoundChannelRecordDevice(), PSoundChannel::Recorder, 1, 8000, 16);
	}
}

#pragma mark Call Management functions

unsigned startCall(XMCallProtocol protocol, const char *remoteParty)
{	
	PString token;
	const char *protocolName;
	
	switch (protocol)
	{
		case XMCallProtocol_H323:
			protocolName = "h323";
			break;
		case XMCallProtocol_SIP:
			protocolName = "sip";
			break;
		default:
			return 0;
	}
	
	PString remoteName = psprintf("%s:%s", protocolName, remoteParty);
	
	BOOL returnValue = theManager->StartCall(remoteName, token);
	
	if(returnValue == TRUE)
	{
		return token.AsUnsigned();
	}
	else
	{
		return 0;
	}
}

void setAcceptIncomingCall(unsigned callID, bool acceptFlag)
{	
	theManager->SetAcceptIncomingCall(acceptFlag);
}

void clearCall(unsigned callID)
{
	PString callToken = PString(callID);
	theManager->ClearCall(callToken);
}

void getCallInformation(unsigned callID,
						const char** remoteName, 
						const char** remoteNumber,
						const char** remoteAddress, 
						const char** remoteApplication)
{
	PString nameStr;
	PString numberStr;
	PString addressStr;
	PString appStr;
	PString token = PString(callID);
	
	theManager->GetCallInformation(token, nameStr, numberStr, addressStr, appStr);
	
	*remoteName = nameStr;
	*remoteNumber = numberStr;
	*remoteAddress = addressStr;
	*remoteApplication = appStr;
}

#pragma mark General Setup functions

void setUserName(const char *string)
{
	theManager->SetDefaultUserName(string);
}

const char *getUserName()
{
	return theManager->GetDefaultUserName();
}

#pragma mark Network Setup functions

void setBandwidthLimit(unsigned limit)
{
	theManager->SetBandwidthLimit(limit);
}

void setPortRanges(unsigned int udpPortMin, 
				   unsigned int udpPortMax, 
				   unsigned int tcpPortMin, 
				   unsigned int tcpPortMax,
				   unsigned int rtpPortMin,
				   unsigned int rtpPortMax)
{
	theManager->SetUDPPorts(udpPortMin, udpPortMax);
	theManager->SetTCPPorts(tcpPortMin, tcpPortMax);
	theManager->SetRtpIpPorts(rtpPortMin, rtpPortMax);
}

void setTranslationAddress(const char *a)
{
	PString str = a;
	theManager->SetTranslationAddress(str);
}

#pragma mark Audio Functions

const char **getAudioInputDevices()
{
	PStringList devices = PSoundChannel::GetDeviceNames(PSoundChannel::Recorder);
	PINDEX count = devices.GetSize();
	PINDEX i;
	
	//allocating the correct memory
	const char **basePtr = new const char*[count + 1];
	
	for(i = 0; i < count; i++)
	{
		PString *str = (PString *)devices.GetAt(i);
		char *ptr = new char[str->GetLength()];
		strcpy(ptr, *str);
		
		basePtr[i] = ptr;
	}
	
	// terminating the array
	basePtr[count] = NULL;
	
	return basePtr;
}

void getDefaultAudioInputDevice(char *buffer)
{
	// Since the device is obtained as call-by-value, we have to do a copy
	// so that the buffer isn't destroyed at the end of the method
	// We explicitly assume that the buffer's length is 64 chars
	
	PString str = PSoundChannel::GetDefaultDevice(PSoundChannel::Recorder);
	strncpy(buffer, str, 64);
	buffer[63] = '\0';
}

const char **getAudioOutputDevices()
{
	PStringList devices = PSoundChannel::GetDeviceNames(PSoundChannel::Player);
	PINDEX count = devices.GetSize();
	PINDEX i;
	
	//allocating the correct memory
	const char **basePtr = new const char*[count + 1];
	
	for(i = 0; i < count; i++)
	{
		PString *str = (PString *)devices.GetAt(i);
		char *ptr = new char[str->GetLength()];
		strcpy(ptr, *str);
		
		basePtr[i] = ptr;
	}
	
	// terminating the array
	basePtr[count] = NULL;
	
	return basePtr;
}
 
void getDefaultAudioOutputDevice(char *buffer)
{
	// Since the device is obtained as call-by-value, we have to do a copy
	// so that the buffer isn't destroyed at the end of the method
	// We explicitly assume that the buffer's length is 64 chars
	PString str = PSoundChannel::GetDefaultDevice(PSoundChannel::Player);
	strncpy(buffer, str, 64);
	buffer[63] = '\0';
}

// The underlying system is call-by-reference
const char *getSelectedAudioInputDevice()
{
	return theManager->GetSoundChannelRecordDevice();
}

bool setSelectedAudioInputDevice(const char *device)
{
	bool result = theManager->SetSoundChannelRecordDevice(device);
	
	// deleting the old instance of recorderChannel and replacing with a new one.
	delete recorderChannel;
	recorderChannel = new XMSoundChannel(theManager->GetSoundChannelRecordDevice(), PSoundChannel::Recorder, 1, 8000, 16);
	
	return result;
}

// The underlying system is call-by-reference
const char *getSelectedAudioOutputDevice()
{
	return theManager->GetSoundChannelPlayDevice();
}

bool setSelectedAudioOutputDevice(const char *device)
{
	bool result = theManager->SetSoundChannelPlayDevice(device);
	
	delete playerChannel;
	playerChannel = new XMSoundChannel(theManager->GetSoundChannelPlayDevice(), PSoundChannel::Player, 1, 8000, 16);
	
	return result;
}

unsigned getAudioInputVolume()
{
	unsigned vol;
	recorderChannel->GetVolume(vol);
	
	return vol;
}

bool setAudioInputVolume(unsigned value)
{
	return recorderChannel->SetVolume(value);
}

unsigned getAudioOutputVolume()
{
	unsigned vol;
	playerChannel->GetVolume(vol);
	
	return vol;
}

bool setAudioOutputVolume(unsigned value)
{
	return playerChannel->SetVolume(value);
}

unsigned getAudioBufferSize()
{
	return theManager->GetSoundChannelBufferDepth();
}

void setAudioBufferSize(unsigned size)
{
	theManager->SetSoundChannelBufferDepth(size);
}

#pragma mark Video functions

void setVideoFunctionality(bool receiveVideo, bool transmitVideo)
{
	theManager->SetVideoFunctionality(receiveVideo, transmitVideo);
}

#pragma mark codec functions

void setDisabledCodecs(const char * const * codecs, unsigned codecCount)
{
	PStringArray codecsArray = PStringArray(codecCount, codecs);
	
	// since video currently is disabled but we are experiencing some troubles with that, we simply disable
	// the video codecs
	codecsArray.AppendString("261");
	theManager->SetMediaFormatMask(codecsArray);
}

void setCodecOrder(const char * const * codecs, unsigned codecCount)
{
	PStringArray codecsArray = PStringArray(codecCount, codecs);
	theManager->SetMediaFormatOrder(codecsArray);
}

#pragma mark H.323 Functions

bool enableH323Listeners(bool flag)
{
	return theManager->EnableH323Listeners(flag);
}

bool isH323Listening()
{
	return theManager->IsH323Listening();
}

void setH323Functionality(bool enableFastStart, bool enableH245Tunnel)
{
	theManager->SetH323Functionality(enableFastStart, enableH245Tunnel);
}

bool setGatekeeper(const char *address, const char *identifier, const char *gkUsername, const char *phoneNumber)
{
	return theManager->SetGatekeeper(address, identifier, gkUsername, phoneNumber);
}

