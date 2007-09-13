/*
 * $Id: XMBridge.cpp,v 1.50 2007/09/13 15:02:44 hfriederich Exp $
 *
 * Copyright (c) 2005-2007 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved
 * Copyright (c) 2005-2007 Hannes Friederich. All rights reserved.
 */

#include "XMBridge.h"

#include <ptlib.h>
#include "XMTypes.h"
#include "XMOpalManager.h"
#include "XMEndPoint.h"
#include "XMH323EndPoint.h"
#include "XMSIPEndPoint.h"
#include "XMSoundChannel.h"
#include "XMAudioTester.h"
#include "XMMediaFormats.h"
#include "XMMediaStream.h"

using namespace std;

void _XMInitSubsystem(const char *pTracePath)
{
  XMOpalManager::InitOpal(pTracePath);
}

void _XMCloseSubsystem()
{
  XMOpalManager::CloseOpal();
}

#pragma mark -
#pragma mark General Setup functions

void _XMSetUserName(const char *string)
{
  XMOpalManager::GetManager()->SetUserName(string);
}

const char *_XMGetUserName()
{
  return XMOpalManager::GetManager()->GetDefaultUserName();
}

#pragma mark -
#pragma mark Network Setup functions

void _XMSetBandwidthLimit(unsigned limit)
{
  XMOpalManager::GetManager()->SetBandwidthLimit(limit);
}

void _XMSetNATInformation(const char * const *stunServers,
						  unsigned stunServerCount,
						  const char *translationAddress)
{
  PStringArray servers = PStringArray(stunServerCount, stunServers, TRUE);
  PString externalAddress = translationAddress;
  XMOpalManager::GetManager()->SetNATInformation(servers, externalAddress);
}

void _XMSetPortRanges(unsigned int udpPortMin, 
					  unsigned int udpPortMax, 
					  unsigned int tcpPortMin, 
					  unsigned int tcpPortMax,
					  unsigned int rtpPortMin,
					  unsigned int rtpPortMax)
{
  XMOpalManager *theManager = XMOpalManager::GetManager();
  theManager->SetUDPPorts(udpPortMin, udpPortMax);
  theManager->SetTCPPorts(tcpPortMin, tcpPortMax);
  theManager->SetRtpIpPorts(rtpPortMin, rtpPortMax);
}

void _XMHandleNetworkStatusChange()
{
  XMOpalManager::GetH323EndPoint()->HandleNetworkStatusChange();
  XMOpalManager::GetSIPEndPoint()->HandleNetworkStatusChange();
}

#pragma mark -
#pragma mark Audio Functions

void _XMSetSelectedAudioInputDevice(unsigned int deviceID)
{
  XMSoundChannel::SetRecordDevice(deviceID);
}

void _XMSetMuteAudioInputDevice(bool muteFlag)
{
  XMSoundChannel::SetRecordDeviceMuted(muteFlag);
}

void _XMSetSelectedAudioOutputDevice(unsigned int deviceID)
{
  XMSoundChannel::SetPlayDevice(deviceID);
}

void _XMSetMuteAudioOutputDevice(bool muteFlag)
{
  XMSoundChannel::SetPlayDeviceMuted(muteFlag);
}

void _XMSetMeasureAudioSignalLevels(bool flag)
{
  XMSoundChannel::SetMeasureSignalLevels(flag);
}

void _XMSetRecordAudio(bool flag)
{
  XMSoundChannel::SetRecordAudio(flag);
}

void _XMSetAudioFunctionality(bool enableSilenceSuppression,
							  bool enableEchoCancellation,
							  unsigned packetTime)
{
  XMOpalManager::GetCallEndPoint()->SetEnableSilenceSuppression(enableSilenceSuppression);
  XMOpalManager::GetCallEndPoint()->SetEnableEchoCancellation(enableEchoCancellation);
  XMOpalManager::GetManager()->SetAudioPacketTime(packetTime);
}

void _XMStopAudio()
{
  XMSoundChannel::StopChannels();
}

void _XMStartAudioTest(unsigned delay)
{
  XMAudioTester::Start(delay);
}

void _XMStopAudioTest()
{
  XMAudioTester::Stop();
}

#pragma mark -
#pragma mark Video functions

void _XMSetEnableVideo(bool enableVideo)
{
  XMOpalManager::GetCallEndPoint()->SetEnableVideo(enableVideo);
}

void _XMSetEnableH264LimitedMode(bool enableH264LimitedMode)
{
  XMOpalManager::GetManager()->SetEnableH264LimitedMode(enableH264LimitedMode);
}

#pragma mark -
#pragma mark codec functions

void _XMSetCodecs(const char * const * orderedCodecs, unsigned orderedCodecCount,
				  const char * const * disabledCodecs, unsigned disabledCodecCount)
{
  PStringArray orderedCodecsArray = PStringArray(orderedCodecCount, orderedCodecs, TRUE);
  PStringArray disabledCodecsArray = PStringArray(disabledCodecCount, disabledCodecs, TRUE);
  
  XMOpalManager *theManager = XMOpalManager::GetManager();
  theManager->SetMediaFormatMask(disabledCodecsArray);
  theManager->SetMediaFormatOrder(orderedCodecsArray);
}

#pragma mark -
#pragma mark H.323 Functions

bool _XMEnableH323Listeners(bool flag)
{
  return XMOpalManager::GetH323EndPoint()->EnableListeners(flag);
}

bool _XMIsH323Enabled()
{
  return XMOpalManager::GetH323EndPoint()->IsListening();
}

void _XMSetH323Functionality(bool enableFastStart, bool enableH245Tunnel)
{
  XMH323EndPoint *h323EndPoint = XMOpalManager::GetH323EndPoint();
  h323EndPoint->DisableFastStart(!enableFastStart);
  h323EndPoint->DisableH245Tunneling(!enableH245Tunnel);
}

XMGatekeeperRegistrationFailReason _XMSetGatekeeper(const char *address, 
													const char *gkUsername, 
													const char *phoneNumber,
													const char *password)
{
  return XMOpalManager::GetH323EndPoint()->SetGatekeeper(address, gkUsername, phoneNumber, password);
}

bool _XMIsRegisteredAtGatekeeper()
{
  return XMOpalManager::GetH323EndPoint()->IsRegisteredWithGatekeeper();
}

void _XMCheckGatekeeperRegistration()
{
  XMOpalManager::GetH323EndPoint()->CheckGatekeeperRegistration();
}

#pragma mark -
#pragma mark SIP Setup Functions

bool _XMEnableSIPListeners(bool flag)
{
  return XMOpalManager::GetSIPEndPoint()->EnableListeners(flag);
}

bool _XMIsSIPEnabled()
{
  return XMOpalManager::GetSIPEndPoint()->IsListening();
}

bool _XMSetSIPProxy(const char *host,
					const char *username,
					const char *password)
{
  return XMOpalManager::GetSIPEndPoint()->UseProxy(host, username, password);
}

void _XMPrepareRegistrationSetup(bool proxyChanged)
{
  XMOpalManager::GetSIPEndPoint()->PrepareRegistrationSetup(proxyChanged);
}

void _XMUseRegistration(const char *domain,
					    const char *username,
					    const char *authorizationUsername,
					    const char *password,
                        bool proxyChanged)
{
  XMOpalManager::GetSIPEndPoint()->UseRegistration(domain, username, authorizationUsername, password, proxyChanged);
}

void _XMFinishRegistrationSetup(bool proxyChanged)
{
  XMOpalManager::GetSIPEndPoint()->FinishRegistrationSetup(proxyChanged);
}

bool _XMIsSIPRegistered()
{
  return (XMOpalManager::GetSIPEndPoint()->GetRegistrationsCount() != 0);
}

#pragma mark -
#pragma mark Call Management functions

unsigned _XMInitiateCall(XMCallProtocol protocol, const char *remoteParty, 
                         const char *origAddressString, XMCallEndReason *endReason)
{	
  return XMOpalManager::GetManager()->InitiateCall(protocol, remoteParty, origAddressString, endReason);
}

void _XMAcceptIncomingCall(unsigned callID)
{
  XMOpalManager::GetCallEndPoint()->AcceptIncomingCall();
}

void _XMRejectIncomingCall(unsigned callID)
{
  XMOpalManager::GetCallEndPoint()->RejectIncomingCall();
}

void _XMClearCall(unsigned callID)
{
  PString callToken = PString(callID);
  XMOpalManager::GetCallEndPoint()->ClearCall(callToken);
}

void _XMLockCallInformation()
{
  XMOpalManager::GetManager()->LockCallInformation();
}

void _XMUnlockCallInformation()
{
  XMOpalManager::GetManager()->UnlockCallInformation();
}

void _XMGetCallInformation(unsigned callID,
						   const char** remoteName, 
						   const char** remoteNumber,
						   const char** remoteAddress, 
						   const char** remoteApplication)
{
  PString nameStr;
  PString numberStr;
  PString addressStr;
  PString appStr;
  
  XMOpalManager::GetManager()->GetCallInformation(nameStr, numberStr, addressStr, appStr);
  
  *remoteName = nameStr;
  *remoteNumber = numberStr;
  *remoteAddress = addressStr;
  *remoteApplication = appStr;
}

void _XMGetCallStatistics(unsigned callID,
						  XMCallStatisticsRecord *callStatistics)
{
  XMOpalManager::GetManager()->GetCallStatistics(callStatistics);
}

#pragma mark -
#pragma mark InCall Functions

bool _XMSetUserInputMode(XMUserInputMode userInputMode)
{
  return XMOpalManager::GetManager()->SetUserInputMode(userInputMode);
}

bool _XMSendUserInputTone(unsigned callID, const char tone)
{
  PString callIDString = PString(callID);
  return XMOpalManager::GetCallEndPoint()->SendUserInputTone(callIDString, tone);
}

bool _XMSendUserInputString(unsigned callID, const char *string)
{
  PString callIDString = PString(callID);
  return XMOpalManager::GetCallEndPoint()->SendUserInputString(callIDString, string);
}

bool _XMStartCameraEvent(unsigned callID, XMCameraEvent cameraEvent)
{
  PString callIDString = PString(callID);
  return XMOpalManager::GetCallEndPoint()->StartCameraEvent(callIDString, cameraEvent);
}

void _XMStopCameraEvent(unsigned callID)
{
  PString callIDString = PString(callID);
  return XMOpalManager::GetCallEndPoint()->StopCameraEvent(callIDString);
}

#pragma mark -
#pragma mark MediaTransmitter Functions

void _XMSetTimeStamp(unsigned sessionID, unsigned timeStamp)
{
  XMMediaStream::SetTimeStamp(sessionID, timeStamp);
}

void _XMAppendData(unsigned sessionID, void *data, unsigned length)
{
  XMMediaStream::AppendData(sessionID, data, length);
}

void _XMSendPacket(unsigned sessionID, bool setMarkerBit)
{
  XMMediaStream::SendPacket(sessionID, setMarkerBit);
}

void _XMDidStopTransmitting(unsigned sessionID)
{
  XMMediaStream::HandleDidStopTransmitting(sessionID);
}

#pragma mark -
#pragma mark Message Logging

void _XMLogMessage(const char *message)
{
  XMOpalManager::LogMessage(message);
}
