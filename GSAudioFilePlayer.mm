/*
 * The MIT License
 * 
 * Copyright (c) 2009 Art Gillespie 
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */ 

#import "GSAudioFilePlayer.h"

NSString * GSGetAudioFileErrorDescription (OSStatus err)
{
	switch (err) {
		case noErr:
			return NSLocalizedString(@"No Error", @"");
		case kAudioFileUnspecifiedError:
			return NSLocalizedString(@"Unspecified", @"");
		case kAudioFileUnsupportedFileTypeError:
			return NSLocalizedString(@"Unsupported File Type", @"");
		case kAudioFileUnsupportedDataFormatError:
			return NSLocalizedString(@"Unsupported Data Format", @"");
		case kAudioFileUnsupportedPropertyError:
			return NSLocalizedString(@"Unsupported Property", @"");
		case kAudioFileBadPropertySizeError:
			return NSLocalizedString(@"Bad Property Size", @"");
		case kAudioFilePermissionsError:
			return NSLocalizedString(@"The operation violated the file permissions", @"");
		case kAudioFileNotOptimizedError:
			return NSLocalizedString(@"To write more data, you must optimize the file", @"");
		case kAudioFileInvalidChunkError:
			return NSLocalizedString(@"Either the chunk does not exist in the file or it is not supported by the file.", @"");
		case kAudioFileDoesNotAllow64BitDataSizeError:
			return NSLocalizedString(@"The file offset is too large for the file type", @"");
		case kAudioFileInvalidPacketOffsetError:
			return NSLocalizedString(@"A packet offset was past the end of the file", @"");
		case kAudioFileInvalidFileError:
			return NSLocalizedString(@"The file is malformed", @"");
		case kAudioFileOperationNotSupportedError:
			return NSLocalizedString(@"The operation cannot be perfomed", @"");
		default:
			return NSLocalizedString(@"Unrecognized Audio File Error", @"");
	}
}

@implementation GSAudioFilePlayer

@synthesize audioFileID;
@synthesize audioFileFormat;
@synthesize fileNode;
@synthesize filePlayerAU;
@synthesize converterNode;
@synthesize converterAU;

+(BOOL)isFileSupported:(NSURL*)fileURL
{
	OSStatus err = noErr;
	AudioFileID outAudioFile;
	err = AudioFileOpenURL((CFURLRef)fileURL, fsRdPerm, 0, &outAudioFile);
	if (noErr != err) {
		return NO;
	}
	AudioFileClose(outAudioFile);
	return YES;
}

-(id)initWithAudioUnit:(CAAudioUnit*)fileAU fileNode:(AUNode)fNode converterAU:(CAAudioUnit*)cAU converterNode:(AUNode)cNode
{
	self = [super init];
	if (self) {
		memset (&audioFileFormat, 0, sizeof(AudioStreamBasicDescription));
		audioFileID = nil;
		fileNode = fNode;
		filePlayerAU = fileAU;
		converterNode = cNode;
		converterAU = cAU;
		fileSetFlag = NO;
	}
	return self;
}


-(BOOL)setFile:(NSURL*)fileURL error:(NSError **)anError
{
	NSLog(@"%s:%s:%@", __FILE__, __FUNCTION__, fileURL);
	OSStatus err = noErr;
	if (audioFileURL) [audioFileURL release];
	audioFileURL = fileURL;
	[audioFileURL retain];
	err = AudioFileOpenURL((CFURLRef)audioFileURL, fsRdPerm, 0, &audioFileID);
	if (noErr != err) {
		NSLog(@"AudioFileOpenURL Failed: %d", err);
		NSString * errDesc = [NSString stringWithFormat:NSLocalizedString(@"The file could not be opened: %@.", @""), 
							  GSGetAudioFileErrorDescription(err)];
		NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errDesc, NSLocalizedDescriptionKey, nil];
		*anError = [[[NSError alloc] initWithDomain:NSOSStatusErrorDomain
													 code:err
												 userInfo:userInfo] autorelease];
		return NO;
	}
	UInt32 propSize = sizeof(CAStreamBasicDescription);
	err = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &propSize, &audioFileFormat);
	if (noErr != err) {
		NSLog(@"AudioFileGetProperty Failed: %d", err);
		NSString * errDesc = [NSString stringWithFormat:NSLocalizedString(@"Couldn't get file's audio format: %@.", @""),
							  GSGetAudioFileErrorDescription(err)];
		NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errDesc, NSLocalizedDescriptionKey, nil];
		*anError = [[[NSError alloc] initWithDomain:NSOSStatusErrorDomain
											  code:err
										  userInfo:userInfo] autorelease];
		return NO;
	}
	fileSetFlag = YES;
	return YES;
}

-(UInt64)numPackets
{
	UInt64 packets;
	UInt32 propSize = sizeof(packets);
	AudioFileGetProperty(audioFileID, kAudioFilePropertyAudioDataPacketCount, &propSize, &packets);	
	return packets;
}

-(void)playFrom:(UInt64)samplePosition
{
	OSStatus err = noErr;
	
	NSAssert(filePlayerAU, @"File Player Audio Unit Not Initialized");
	
	if (audioFileID == 0)
		return;
	
	err = filePlayerAU->SetNumberChannels(kAudioUnitScope_Output, 0, audioFileFormat.NumberChannels());
	err = filePlayerAU->SetSampleRate(kAudioUnitScope_Output, 0, audioFileFormat.mSampleRate);
	err = filePlayerAU->SetProperty(kAudioUnitProperty_ScheduledFileIDs, 
											   kAudioUnitScope_Global, 0, &audioFileID, sizeof(audioFileID));
	currentFrame = samplePosition;

	UInt64 nPackets = self.numPackets;
	
	//Float64 fileDuration = (nPackets * fileFormat.mFramesPerPacket) / fileFormat.mSampleRate;
	
	ScheduledAudioFileRegion rgn;
	
	memset (&rgn.mTimeStamp, 0, sizeof(rgn.mTimeStamp));
	rgn.mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	rgn.mTimeStamp.mSampleTime = 0;
	rgn.mCompletionProc = nil;
	rgn.mCompletionProcUserData = nil;
	rgn.mAudioFile = audioFileID;
	rgn.mLoopCount = 1;
	rgn.mStartFrame = currentFrame;
	
	totalFrames = nPackets * audioFileFormat.mFramesPerPacket;
	
	rgn.mFramesToPlay = (UInt32)totalFrames;
	err = filePlayerAU->Initialize();
	err = filePlayerAU->SetProperty (kAudioUnitProperty_ScheduledFileRegion, 
												kAudioUnitScope_Global, 0,&rgn, sizeof(rgn));
	
	// prime the fp AU with default values
	UInt32 defaultVal = 0;
	err = filePlayerAU->SetProperty (kAudioUnitProperty_ScheduledFilePrime, 
												kAudioUnitScope_Global, 0, &defaultVal, sizeof(defaultVal));
	// tell the fp AU when to start playing (this ts is in the AU's render time stamps; -1 means next render cycle)
	AudioTimeStamp startTime;
	memset (&startTime, 0, sizeof(startTime));
	startTime.mFlags = kAudioTimeStampSampleTimeValid;
	startTime.mSampleTime = -1;
	err = filePlayerAU->SetProperty(kAudioUnitProperty_ScheduleStartTimeStamp, 
											   kAudioUnitScope_Global, 0, &startTime, sizeof(startTime));
}

-(void)playFromCurrent
{
	OSStatus err = noErr;
	AudioTimeStamp startTime;
	UInt32 propSize = sizeof(startTime);
	err = filePlayerAU->GetProperty(kAudioUnitProperty_CurrentPlayTime, 
									kAudioUnitScope_Global, 0, &startTime, &propSize);
	NSAssert(startTime.mFlags & kAudioTimeStampSampleTimeValid, @"AudioTimeStamp SampleTime Invalid");
	Float64 currentTime = (startTime.mSampleTime == -1.0)?0.0:startTime.mSampleTime;
	UInt64 tmpFrame = currentFrame + currentTime;
	if (tmpFrame > 0 && totalFrames > 0)
		tmpFrame %= totalFrames;
	[self playFrom:tmpFrame];
}

-(NSString*)filePath
{
	return [audioFileURL path];
}

-(BOOL)hasFile
{
	return fileSetFlag;
}

-(void)clear 
{
	fileSetFlag = NO;
	OSStatus err = filePlayerAU->Reset(kAudioUnitScope_Global, 0);
	NSAssert(err == noErr, @"In GSAudioFilePlayer clear:  AudioUnitReset failed");
	NSURL * tmp = audioFileURL;
	audioFileURL = nil;
	audioFileID = nil;
	[tmp release];
}

-(void)dealloc
{
	if (filePlayerAU) {
		delete filePlayerAU;
		filePlayerAU = nil;
	}
	if (converterAU) {
		delete converterAU;
		converterAU = nil;
	}
	[super dealloc];
}

@end
