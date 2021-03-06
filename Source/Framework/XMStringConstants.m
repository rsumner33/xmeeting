/*
 * $Id: XMStringConstants.m,v 1.37 2008/10/24 12:22:02 hfriederich Exp $
 *
 * Copyright (c) 2005-2008 XMeeting Project ("http://xmeeting.sf.net").
 * All rights reserved.
 * Copyright (c) 2005-2008 Hannes Friederich. All rights reserved.
 */

#import "XMStringConstants.h"
#import "XMTypes.h"
#import "XMPrivate.h"

#pragma mark Notifications

NSString *XMNotification_FrameworkDidInitialize = @"XMeetingFrameworkDidInitializeNotificaiton";
NSString *XMNotification_FrameworkDidClose = @"XMeetingFrameworkDidCloseNotification";

NSString *XMNotification_UtilsDidUpdateNetworkInformation = @"XMeetingUtilsDidUpdateNetworkInformationNotification";

NSString *XMNotification_CallManagerDidStartSubsystemSetup = @"XMeetingCallManagerDidStartSubsystemSetupNotification";
NSString *XMNotification_CallManagerDidEndSubsystemSetup = @"XMeetingCallManagerDidEndSubsystemSetupNotification";

NSString *XMNotification_CallManagerDidStartCallInitiation = @"XMeetingCallManagerDidStartCallInitiationNotification";
NSString *XMNotification_CallManagerDidStartCalling = @"XMeetingCallManagerDidStartCallingNotification";
NSString *XMNotification_CallManagerDidNotStartCalling = @"XMeetingCallManagerCallDidNotStartCallingNotification";
NSString *XMNotification_CallManagerDidStartRingingAtRemoteParty = @"XMeetingCallManagerDidStartRingingAtRemotePartyNotification";
NSString *XMNotification_CallManagerDidReceiveIncomingCall = @"XMeetingCallManagerDidReceiveIncomingCallNotification";
NSString *XMNotification_CallManagerDidEstablishCall = @"XMeetingCallManagerDidEstablishCallNotification";
NSString *XMNotification_CallManagerDidClearCall = @"XMeetingCallManagerDidClearCallNotification";

NSString *XMNotification_CallManagerDidEnableH323 = @"XMeetingCallManagerDidEnableH323Notification";
NSString *XMNotification_CallManagerDidDisableH323 = @"XMeetingCallManagerDidDisableH323Notification";
NSString *XMNotification_CallManagerDidNotEnableH323 = @"XMeetingCallManagerDidNotEnableH323Notification";
NSString *XMNotification_CallManagerDidChangeH323Status = @"XMeetingCallManagerDidChangeH323StatusNotification";
NSString *XMNotification_CallManagerDidRegisterAtGatekeeper = @"XMeetingCallManagerDidRegisterAtGatekeeperNotification";
NSString *XMNotification_CallManagerDidUnregisterFromGatekeeper = @"XMeetingCallManagerDidUnregisterFromGatekeeperNotification";
NSString *XMNotification_CallManagerDidNotRegisterAtGatekeeper = @"XMeetingCallManagerDidNotRegisterAtGatekeeperNotification";
NSString *XMNotification_CallManagerDidChangeGatekeeperRegistrationStatus = @"XMeetingCallManagerDidChangeGatekeeperRegistrationStatusNotification";
NSString *XMNotification_CallManagerDidEnableSIP = @"XMeetingCallManagerDidEnableSIPNotification";
NSString *XMNotification_CallManagerDidDisableSIP = @"XMeetingCallMangagerDidDisableSIPNotification";
NSString *XMNotification_CallManagerDidNotEnableSIP = @"XMeetingCallManagerDidNotEnableSIPNotification";
NSString *XMNotification_CallManagerDidChangeSIPStatus = @"XMeetingCallManagerDidChangeSIPStatusNotification";
NSString *XMNotification_CallManagerDidSIPRegister = @"XMeetingCallManagerDidSIPRegisterNotification";
NSString *XMNotification_CallManagerDidSIPUnregister = @"XMeetingCallManagerDidSIPUnregister";
NSString *XMNotification_CallManagerDidNotSIPRegister = @"XMeetingCallManagerDidNotSIPRegister";
NSString *XMNotification_CallManagerDidChangeSIPRegistrationStatus = @"XMeetingCallManagerDidChangeSIPRegistrationStatusNotification";

NSString *XMNotification_CallManagerDidOpenOutgoingAudioStream = @"XMeetingCallManagerDidOpenOutgoingAudioStreamNotification";
NSString *XMNotification_CallManagerDidOpenIncomingAudioStream = @"XMeetingCallManagerDidOpenIncomingAudioStreamNotification";
NSString *XMNotification_CallManagerDidOpenOutgoingVideoStream = @"XMeetingCallManagerDidOpenOutgoingVideoStreamNotification";
NSString *XMNotification_CallManagerDidOpenIncomingVideoStream = @"XMeetingCallManagerDidOpenIncomingVideoStreamNotification";

NSString *XMNotification_CallManagerDidCloseOutgoingAudioStream = @"XMeetingCallManagerDidCloseOutgoingAudioStreamNotification";
NSString *XMNotification_CallManagerDidCloseIncomingAudioStream = @"XMeetingCallManagerDidCloseIncomingAudioStreamNotification";
NSString *XMNotification_CallManagerDidCloseOutgoingVideoStream = @"XMeetingCallManagerDidCloseOutgoingVideoStreamNotification";
NSString *XMNotification_CallManagerDidCloseIncomingVideoStream = @"XMeetingCallManagerDidCloseIncomingVideoStreamNotification";

NSString *XMNotification_CallManagerDidUpdateCallStatistics = @"XMeetingCallManagerDidUpdateCallStatisticsNotification";

NSString *XMNotification_CallManagerDidOpenFECCChannel = @"XMeetingCallManagerDidOpenFECCChannel";
NSString *XMNotification_CallManagerDidCloseFECCChannel = @"XMeetingCallManagerDidCloseFECCChannel";

NSString *XMNotification_AudioManagerInputDeviceDidChange = @"XMeetingAudioManagerInputDeviceDidChangeNotification";
NSString *XMNotification_AudioManagerOutputDeviceDidChange = @"XMeetingAudioManagerOutputDeviceDidChangeNotification";
NSString *XMNotification_AudioManagerInputVolumeDidChange = @"XMeetingAudioManagerInputVolumeDidChangeNotification";
NSString *XMNotification_AudioManagerOutputVolumeDidChange = @"XMeetingAudioManagerOutputVolumeDidChangeNotification";
NSString *XMNotification_AudioManagerDidUpdateDeviceLists = @"XMeetingAudioManagerDidUpdateDeviceListsNotification";
NSString *XMNotification_AudioManagerDidUpdateInputLevel = @"XMeetingAudioManagerDidUpdateInputLevelNotification";
NSString *XMNotification_AudioManagerDidUpdateOutputLevel = @"XMeetingAudioManagerDidUpdateOutputLevelNotification";
NSString *XMNotification_AudioManagerDidStartAudioTest = @"XMeetingAudioManagerDidStartAudioTest";
NSString *XMNotification_AudioManagerDidStopAudioTest = @"XMeetingAudioManagerDidStopAudioTest";

NSString *XMNotification_VideoManagerDidStartInputDeviceListUpdate = @"XMeetingVideoManagerDidStartInputDeviceListUpdateNotification";
NSString *XMNotification_VideoManagerDidUpdateInputDeviceList = @"XMeetingVideoManagerDidUpdateInputDeviceListNotification";
NSString *XMNotification_VideoManagerDidStartSelectedInputDeviceChange = @"XMeetingVideoManagerDidStartSelectedInputDeviceChange";
NSString *XMNotification_VideoManagerDidChangeSelectedInputDevice = @"XMeetingVideoManagerDidChangeSelectedInputDevice";
NSString *XMNotification_VideoManagerDidStartTransmittingVideo = @"XMeetingVideoManagerDidStartTransmittingVideo";
NSString *XMNotification_VideoManagerDidEndTransmittingVideo = @"XMeetingVideoManagerDidStartTransmittingVideo";
NSString *XMNotification_VideoManagerDidStartReceivingVideo = @"XMeetingVideoManagerDidStartReceivingVideoNotification";
NSString *XMNotification_VideoManagerDidEndReceivingVideo = @"XMeetingVideoManagerDidEndReceivingVideoNotification";
NSString *XMNotification_VideoManagerDidGetError = @"XMeetingVideoManagerDidGetErrorNotification";

NSString *XMNotification_CallRecorderDidStartRecording = @"XMeetingCallRecorderDidStartRecordingNotification";
NSString *XMNotification_CallRecorderDidEndRecording = @"XMeetingCallRecorderDidEndRecordingNotification";
NSString *XMNotification_CallRecorderDidGetError = @"XMeetingCallRecorderDidGetErrorNotification";

#pragma mark Exceptions

NSString *XMException_InvalidAction = @"XMeetingInvalidActionException";
NSString *XMException_InvalidParameter = @"XmeetngInvalidParameterException";
NSString *XMException_UnsupportedCoder = @"XMeetingUnsupportedCoderException";
NSString *XMException_InternalConsistencyFailure = @"XMeetingInternalConsistencFailureException";

NSString *XMExceptionReason_InvalidParameterMustNotBeNil = @"Parameter must not be nil";
NSString *XMExceptionReason_InvalidParameterMustBeOfCorrectType = @"Parameter must be of correct type";
NSString *XMExceptionReason_InvalidParameterMustBeValidKey = @"Key must be valid for this object";
NSString *XMExceptionReason_UnsupportedCoder = @"Only NSCoder sublasses which allow keyed coding are supported";
NSString *XMExceptionReason_CallManagerInvalidActionIfInSubsystemSetupOrInCall = @"Not allowed during subsystem setup or while in a call";
NSString *XMExceptionReason_CallManagerInvalidActionIfNotInCall = @"Not allowed unless in a call";
NSString *XMExceptionReason_CallManagerInvalidActionIfCallStatusNotIncoming = @"Not allowed if not an incoming call";
NSString *XMExceptionReason_CallManagerInvalidActionIfH323Listening = @"Not allowed if H.323 is already succesfully setup";
NSString *XMExceptionReason_CallManagerInvalidActionIfH323Disabled = @"Not allowed if H.323 is disabled in preferences";
NSString *XMExceptionReason_CallManagerInvalidActionIfGatekeeperRegistered = @"Not allowed if succesfully registered at gatekeeper";
NSString *XMExceptionReason_CallManagerInvalidActionIfGatekeeperDisabled = @"Not allowed if gatekeeper usage is disabled in preferences";
NSString *XMExceptionReason_CallManagerInvalidActionIfSIPListening = @"Not allowed if SIP is already succesfully setup";
NSString *XMExceptionReason_CallManagerInvalidActionIfSIPDisabled = @"Not allowed if SIP is disabled in preferences";
NSString *XMExceptionReason_CallManagerInvalidActionIfCompletelySIPRegistered = @"Not allowed if all SIP registrations were successful";
NSString *XMexceptionReason_CallManagerInvalidActionIfRegistrationsDisabled = @"Not allowed if SIP registrations are disabled in preferences";

NSString *XMExceptionReason_CodecManagerInternalConsistencyFailure = @"Parsing the infos for available codecs failed (%@)";

#pragma mark Keys

NSString *XMKey_PreferencesUserName = @"XMeeting_UserName";
NSString *XMKey_PreferencesAutomaticallyAcceptIncomingCalls = @"XMeeting_AutomaticallyAcceptIncomingCalls";

NSString *XMKey_PreferencesBandwidthLimit = @"XMeeting_BandwidthLimit";
NSString *XMKey_PreferencesExternalAddress = @"XMeeting_ExternalAddress";
NSString *XMKey_PreferencesTCPPortBase = @"XMeeting_TCPPortBase";
NSString *XMKey_PreferencesTCPPortMax = @"XMeeting_TCPPortMax";
NSString *XMKey_PreferencesUDPPortBase = @"XMeeting_UDPPortBase";
NSString *XMKey_PreferencesUDPPortMax = @"XMeeting_UDPPortMax";
NSString *XMKey_PreferencesSTUNServers = @"XMeeting_STUNServers";

NSString *XMKey_PreferencesAudioCodecList = @"XMeeting_AudioCodecList";
NSString *XMKey_PreferencesEnableSilenceSuppression = @"XMeeting_EnableSilenceSuppression";
NSString *XMKey_PreferencesEnableEchoCancellation = @"XMeeting_EnableEchoCancellation";
NSString *XMKey_PreferencesAudioPacketTime = @"XMeeting_AudioPacketTime";

NSString *XMKey_PreferencesEnableVideo = @"XMeeting_EnableVideo";
NSString *XMKey_PreferencesVideoFramesPerSecond = @"XMeeting_VideoFramesPerSecond";
NSString *XMKey_PreferencesPreferredVideoSize = @"XMeeting_PreferredVideoSize";
NSString *XMKey_PreferencesVideoCodecList = @"XMeeting_VideoCodecList";
NSString *XMKey_PreferencesEnableH264LimitedMode = @"XMeeting_EnableH264LimitedMode";

NSString *XMKey_PreferencesEnableH323 = @"XMeeting_EnableH323";
NSString *XMKey_PreferencesEnableH245Tunnel = @"XMeeting_EnableH245Tunnel";
NSString *XMKey_PreferencesEnableFastStart = @"XMeeting_EnableFastStart";
NSString *XMKey_PreferencesGatekeeperAddress = @"XMeeting_GatekeeperAddress";
NSString *XMKey_PreferencesGatekeeperTerminalAlias1 = @"XMeeting_GatekeeperTerminalAlias1";
NSString *XMKey_PreferencesGatekeeperTerminalAlias2 = @"XMeeting_GatekeeperTerminalAlias2";
NSString *XMKey_PreferencesGatekeeperPassword = @"XMeeting_GatekeeperPassword";

NSString *XMKey_PreferencesEnableSIP = @"XMeeting_EnableSIP";
NSString *XMKey_PreferencesSIPRegistrationRecords = @"XMeeting_RegistrarRecords";
NSString *XMKey_PreferencesSIPProxyHost = @"XMeeting_SIPProxyHost";
NSString *XMKey_PreferencesSIPProxyUsername = @"XMeeting_SIPProxyUsername";
NSString *XMKey_PreferencesSIPProxyPassword = @"XMeeting_SIPProxyPassword";

NSString *XMKey_PreferencesInternationalDialingPrefix = @"XMeeting_InternationalDialingPrefix";

NSString *XMKey_PreferencesCodecListRecordIdentifier = @"XMeeting_Identifier";
NSString *XMKey_PreferencesCodecListRecordIsEnabled = @"XMeeting_IsEnabled";

NSString *XMKey_PreferencesRegistrationRecordDomain = @"XMeeting_Host";
NSString *XMKey_PreferencesRegistrationRecordUsername = @"XMeeting_Username";
NSString *XMKey_PreferencesRegistrationRecordAuthorizationUsername = @"XMeeting_AuthorizationUsername";
NSString *XMKey_PreferencesRegistrationRecordPassword = @"XMeeting_Password";

NSString *XMKey_CodecManagerCodecDescriptionsFilename = @"XMCodecDescriptions";
NSString *XMKey_CodecManagerCodecDescriptionsFiletype = @"plist";
NSString *XMKey_CodecManagerAudioCodecs = @"XMeeting_AudioCodecs";
NSString *XMKey_CodecManagerVideoCodecs = @"XMeeting_VideoCodecs";

NSString *XMKey_CodecIdentifier = @"XMeeting_Identifier";
NSString *XMKey_CodecName = @"XMeeting_Name";
NSString *XMKey_CodecBandwidth = @"XMeeting_Bandwidth";
NSString *XMKey_CodecQuality = @"XMeeting_Quality";
NSString *XMKey_CodecCanDisable = @"XMeeting_CanDisable";

NSString *XMKey_AddressResourceCallProtocol = @"XMeeting_CallProtocol";
NSString *XMKey_AddressResourceAddress = @"XMeeting_Address";
NSString *XMKey_AddressResourceHumanReadableAddress = @"XMeeting_HumanReadableAddress";

NSString *XMKey_GeneralPurposeAddressResource = @"XMeeting_GeneralPurposeAddressResource";

NSString *XMPublicInterface = @"<PUBLIC>";
NSString *XMUnknownInterface = @"<UNKNOWN>";
