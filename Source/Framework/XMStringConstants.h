/*
 * $Id: XMStringConstants.h,v 1.39 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#ifndef __XM_STRING_CONSTANTS_H__
#define __XM_STRING_CONSTANTS_H__

#pragma mark XMeeting Framework Notifications

/**
 * Posted when the XMeeting Framework is initialized and ready to be used
 **/
extern NSString *XMNotification_FrameworkDidInitialize;

/**
 * Posted when the XMeeting Framework has been closed and can no longer be
 * used (unless initialized again)
 **/
extern NSString *XMNotification_FrameworkDidClose;

#pragma mark XMUtils Notifications

/**
 * Posted every time the network information does change.
 * (local addresses, external address, NAT Type). This happens
 * if the system configuration location changes or if a network
 * cable is plugged in and the host gets connected to a network.
 **/
extern NSString *XMNotification_UtilsDidUpdateNetworkInformation;

#pragma mark XMCallManager Notifications

/**
 * Posted when the CallManager starts setting up the subsystem.
 **/
extern NSString *XMNotification_CallManagerDidStartSubsystemSetup;

/**
 * Posted when the CallManager ends setting up the subsystem
 **/
extern NSString *XMNotification_CallManagerDidEndSubsystemSetup;

/**
 * Posted when the CallManager started to initiate a call
 * This indicates that the success or failure of the call 
 * initiation cannot be determined immediately.
 * After this notification has been posted, it is no longer
 * allowed to make modifications such as changing the preferences
 * or so until either the call start failed or the call is
 * cleared.
 **/
extern NSString *XMNotification_CallManagerDidStartCallInitiation;

/**
 * Posted when the framework started calling the remote party
 **/
extern NSString *XMNotification_CallManagerDidStartCalling;

/**
 * Posted when the attempt to start a call failed. This normally
 * indicates a serious problem such as no address specified or
 * that in the same time an incoming call appeared etc
 * the userInfo dictionary has the following keys set:
 * @"Address" : address one tried to call to
 **/
extern NSString *XMNotification_CallManagerDidNotStartCalling;

/**
 * Posted when the phone is ringing at the remote party.
 * This indicates that the remote party exists and is online,
 * but that the remote user has to accept the call first
 **/
extern NSString *XMNotification_CallManagerDidStartRingingAtRemoteParty;

/**
 * Posted when there is an incoming call, waiting for user response
 **/
extern NSString *XMNotification_CallManagerDidReceiveIncomingCall;

/**
 * Posted when the call is established
 **/
extern NSString *XMNotification_CallManagerDidEstablishCall;

/**
 * Posted when the call is cleared. It doesn't matter whether
 * the call was actually established or not and whether this
 * is an incoming or outgoing call
 **/
extern NSString *XMNotification_CallManagerDidClearCall;

/**
 * Posted when the Framework did enable the H.323 protocol.
 **/
extern NSString *XMNotification_CallManagerDidEnableH323;

/**
 * Posted when the Framework did disable the H.323 protocol
 **/
extern NSString *XMNotification_CallManagerDidDisableH323;

/**
 * Posted when the Framework couldn't enable the H323 subsystem. This
 * normally indicates problems like the H.323 listener ports not open
 * and so on
 **/
extern NSString *XMNotification_CallManagerDidNotEnableH323;

/**
 * Posted whenever the H323 protocol status changes
 **/
extern NSString *XMNotification_CallManagerDidChangeH323Status;

/**
 * Posted when the Framework sucessfully registered at a gatekeeper.
 * This notification is only posted when the Framework has a new registration
 **/
extern NSString *XMNotification_CallManagerDidRegisterAtGatekeeper;

/**
 * Posted when the Framework unregistered from a gatekeeper
 **/
extern NSString *XMNotification_CallManagerDidUnregisterFromGatekeeper;

/**
 * Posted when the Framework failed to register at a gatekeeper
 **/
extern NSString *XMNotification_CallManagerDidNotRegisterAtGatekeeper;

/**
 * Posted whenever the gatekeeper registration status changes
 **/
extern NSString *XMNotification_CallManagerDidChangeGatekeeperRegistrationStatus;

/**
 * Posted when the Framework did enable the SIP protocol
 **/
extern NSString *XMNotification_CallManagerDidEnableSIP;

/**
 * Posted when the Framework did disable the SIP protocol
 **/
extern NSString *XMNotification_CallManagerDidDisableSIP;

/**
 * Posted when the Framework couldn't enable the SIP subsystem. This normally
 * indicates problems like the SIP ports not open and so on
 **/
extern NSString *XMNotification_CallManagerDidNotEnableSIP;

/**
 * Posted whenever the SIP protocol status changes
 **/
extern NSString *XMNotification_CallManagerDidChangeSIPStatus;

/**
 * Posted when the Framwork succesfully registered at a SIP registrar.
 * This notification is only posted when the Framework has a new registration
 * made.
 **/
extern NSString *XMNotification_CallManagerDidSIPRegister;

/**
 * Posted when the Framework unregistered from a SIP registrar
 **/
extern NSString *XMNotification_CallManagerDidSIPUnregister;

/**
 * Posted when the Framework failed to register at the registrar
 **/
extern NSString *XMNotification_CallManagerDidNotSIPRegister;

/**
 * Posted when the SIP registration status changes
 **/
extern NSString *XMNotification_CallManagerDidChangeSIPRegistrationStatus;

/**
 * Posted when the appropriate media stream is opened
 **/
extern NSString *XMNotification_CallManagerDidOpenOutgoingAudioStream;
extern NSString *XMNotification_CallManagerDidOpenIncomingAudioStream;
extern NSString *XMNotification_CallManagerDidOpenOutgoingVideoStream;
extern NSString *XMNotification_CallManagerDidOpenIncomingVideoStream;

/**
 * Posted when the appropriate media stream is closed
 **/
extern NSString *XMNotification_CallManagerDidCloseOutgoingAudioStream;
extern NSString *XMNotification_CallManagerDidCloseIncomingAudioStream;
extern NSString *XMNotification_CallManagerDidCloseOutgoingVideoStream;
extern NSString *XMNotification_CallManagerDidCloseIncomingVideoStream;

/**
 * Posted when the call statistics are updated
 **/
extern NSString *XMNotification_CallManagerDidUpdateCallStatistics;

/**
 * Posted when the FECC channel was opened.
 **/
extern NSString *XMNotification_CallManagerDidOpenFECCChannel;

/**
 * Posted when the FECC channel was closed.
 **/
extern NSString *XMNotification_CallManagerDidCloseFECCChannel;

#pragma mark XMAudioManager Notifications

extern NSString *XMNotification_AudioManagerInputDeviceDidChange;
extern NSString *XMNotification_AudioManagerOutputDeviceDidChange;
extern NSString *XMNotification_AudioManagerInputVolumeDidChange;
extern NSString *XMNotification_AudioManagerOutputVolumeDidChange;
extern NSString *XMNotification_AudioManagerDidUpdateDeviceLists;
extern NSString *XMNotification_AudioManagerDidUpdateInputLevel;
extern NSString *XMNotification_AudioManagerDidUpdateOutputLevel;
extern NSString *XMNotification_AudioManagerDidStartAudioTest;
extern NSString *XMNotification_AudioManagerDidStopAudioTest;

#pragma mark XMVideoManager Notifications

/**
 * Posted when the VideoManager did start to update the video device list
 **/
extern NSString *XMNotification_VideoManagerDidStartInputDeviceListUpdate;

/**
 * Posted when the VideoManager did update the video device list
 * This also indicates that the input device list update process
 * has finished
 **/
extern NSString *XMNotification_VideoManagerDidUpdateInputDeviceList;

/**
 * Posted when the VideoManager did start changing the video input device.
 * Since this might be a lengthy task, the begin and end of this task
 * are posted through notifications.
 **/
extern NSString *XMNotification_VideoManagerDidStartSelectedInputDeviceChange;

/**
 * Posted when the video input device did change.
 **/
extern NSString *XMNotification_VideoManagerDidChangeSelectedInputDevice;

/**
 * Posted when the VideoManager did start transmitting video to the remote
 * party.
 * When this notification is posted, the size of the transmitted video
 * is also known
 **/
extern NSString *XMNotification_VideoManagerDidStartTransmittingVideo;

/**
 * Posted when the VideoManager no longer transmits video to the remote
 * party.
 **/
extern NSString *XMNotification_VideoManagerDidEndTransmittingVideo;

/**
 * Posted when the VideoManager did start receiving video from the remote
 * party.
 * When this notification is posted, the size of the remote video is also
 * known.
 **/
extern NSString *XMNotification_VideoManagerDidStartReceivingVideo;

/**
 * Posted when the VideoManager no longer receives video from the
 * remote party
 **/
extern NSString *XMNotification_VideoManagerDidEndReceivingVideo;

/**
 * Posted when the VideoManager encounters an error.
 **/
extern NSString *XMNotification_VideoManagerDidGetError;

#pragma mark XMCallRecorder Notifications

extern NSString *XMNotification_CallRecorderDidStartRecording;
extern NSString *XMNotification_CallRecorderDidEndRecording;
extern NSString *XMNotification_CallRecorderDidGetError;

#pragma mark Exceptions

extern NSString *XMException_InvalidAction;
extern NSString *XMException_InvalidParameter;
extern NSString *XMException_UnsupportedCoder;
extern NSString *XMException_InternalConsistencyFailure;

#pragma mark XMPreferences Keys

// General keys
extern NSString *XMKey_PreferencesUserName;
extern NSString *XMKey_PreferencesAutomaticallyAcceptIncomingCalls;

// Network-specific keys
extern NSString *XMKey_PreferencesBandwidthLimit;
extern NSString *XMKey_PreferencesExternalAddress;
extern NSString *XMKey_PreferencesTCPPortBase;
extern NSString *XMKey_PreferencesTCPPortMax;
extern NSString *XMKey_PreferencesUDPPortBase;
extern NSString *XMKey_PreferencesUDPPortMax;
extern NSString *XMKey_PreferencesSTUNServers;

// audio-specific keys
extern NSString *XMKey_PreferencesAudioCodecList;
extern NSString *XMKey_PreferencesEnableSilenceSuppression;
extern NSString *XMKey_PreferencesEnableEchoCancellation;
extern NSString *XMKey_PreferencesAudioPacketTime;

// video-specific keys
extern NSString *XMKey_PreferencesEnableVideo;
extern NSString *XMKey_PreferencesVideoFramesPerSecond;
extern NSString *XMKey_PreferencesPreferredVideoSize;
extern NSString *XMKey_PreferencesVideoCodecList;
extern NSString *XMKey_PreferencesEnableH264LimitedMode;

// H323-specific keys
extern NSString *XMKey_PreferencesEnableH323;
extern NSString *XMKey_PreferencesEnableH245Tunnel;
extern NSString *XMKey_PreferencesEnableFastStart;
extern NSString *XMKey_PreferencesGatekeeperAddress;
extern NSString *XMKey_PreferencesGatekeeperTerminalAlias1;
extern NSString *XMKey_PreferencesGatekeeperTerminalAlias2;
extern NSString *XMKey_PreferencesGatekeeperPassword;

// SIP-specific keys
extern NSString *XMKey_PreferencesEnableSIP;
extern NSString *XMKey_PreferencesSIPRegistrationRecords;
extern NSString *XMKey_PreferencesSIPProxyHost;
extern NSString *XMKey_PreferencesSIPProxyUsername;
extern NSString *XMKey_PreferencesSIPProxyPassword;

// Misc keys
extern NSString *XMKey_PreferencesInternationalDialingPrefix;

#pragma mark XMPreferencesCodecListRecord Keys

extern NSString *XMKey_PreferencesCodecListRecordIdentifier;
extern NSString *XMKey_PreferencesCodecListRecordIsEnabled;

#pragma mark XMPreferencesRegistarRecord Keys

extern NSString *XMKey_PreferencesRegistrationRecordDomain;
extern NSString *XMKey_PreferencesRegistrationRecordUsername;
extern NSString *XMKey_PreferencesRegistrationRecordAuthorizationUsername;
extern NSString *XMKey_PreferencesRegistrationRecordPassword;

#pragma mark XMCodecManager Keys

/**
 * List of keys for accessing the properties of a codec description
 **/
extern NSString *XMKey_CodecIdentifier;
extern NSString *XMKey_CodecName;
extern NSString *XMKey_CodecBandwidth;
extern NSString *XMKey_CodecQuality;
extern NSString *XMKey_CodecCanDisable;

#pragma mark XMAddressResource and subclasses keys

extern NSString *XMKey_AddressResourceCallProtocol;
extern NSString *XMKey_AddressResourceAddress;
extern NSString *XMKey_AddressResourceHumanReadableAddress;

#pragma mark Interface constants

extern NSString *XMPublicInterface;
extern NSString *XMUnknownInterface;

#endif // __XM_STRING_CONSTANTS_H__