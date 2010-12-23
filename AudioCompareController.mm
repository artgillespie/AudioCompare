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

#import "AudioCompareController.h"
#import "CAComponentDescription.h"
#import <QuartzCore/QuartzCore.h>

NSString * GSGetAUGraphErrorDescription (OSStatus err)
{
	switch (err) {
		case noErr:
			return NSLocalizedString(@"No Error", @"");
		case kAUGraphErr_NodeNotFound:
			return NSLocalizedString(@"The specified node cannot be found", @"");
		case kAUGraphErr_InvalidConnection:
			return NSLocalizedString(@"The attempted connection between two nodes cannot be made", @"");
		case kAUGraphErr_OutputNodeErr:
			return NSLocalizedString(@"An AU Graph can have only one Output Audio Unit", @"");
		case kAUGraphErr_CannotDoInCurrentContext:
			return NSLocalizedString(@"Could not make the AU graph call in the current context.", @"");
		case kAUGraphErr_InvalidAudioUnit:
			return NSLocalizedString(@"Invalid Audio Unit", @"");
		default:
			return NSLocalizedString(@"Unrecognized AU Graph error", @"");
	}
}

NSString * GSGetAudioUnitErrorDescription (OSStatus err)
{
	switch (err) {
		case noErr:
			return NSLocalizedString(@"No Error", @"");
		case kAudioUnitErr_InvalidProperty:
			return NSLocalizedString(@"Invalid Property", @"Audio Unit Error: AUComponent.h kAudioUnitErr_InvalidProperty");
		case kAudioUnitErr_InvalidParameter:
			return NSLocalizedString(@"Invalid Parameter", @"Audio Unit Error: AUComponent.h kAudioUnitErr_InvalidParameter");
		case kAudioUnitErr_InvalidElement:
			return NSLocalizedString(@"Invalid Element", @"Audio Unit Error: AUComponent.h kAudioUnitErr_InvalidElement");
		case kAudioUnitErr_NoConnection:
			return NSLocalizedString(@"No Connection", @"Audio Unit Error: AUComponent.h kAudioUnitErr_NoConnection");
		case kAudioUnitErr_FailedInitialization:
			return NSLocalizedString(@"Failed Initialization", @"Audio Unit Error: AUComponent.h kAudioUnitErr_FailedInitialization");
		case kAudioUnitErr_TooManyFramesToProcess:
			return NSLocalizedString(@"Too Many Frames To Process", @"Audio Unit Error: AUComponent.h kAudioUnitErr_TooManyFramesToProcess");
		case kAudioUnitErr_IllegalInstrument:
			return NSLocalizedString(@"Illegal Instrument", @"Audio Unit Error: AUComponent.h kAudioUnitErr_IllegalInstrument");
		case kAudioUnitErr_InstrumentTypeNotFound:
			return NSLocalizedString(@"Instrument Type Not Found", @"Audio Unit Error: AUComponent.h kAudioUnitErr_InstrumentTypeNotFound");
		case kAudioUnitErr_InvalidFile:
			return NSLocalizedString(@"Invalid File", @"Audio Unit Error: AUComponent.h kAudioUnitErr_InvalidFile");
		case kAudioUnitErr_UnknownFileType:
			return NSLocalizedString(@"Unknown File Type", @"Audio Unit Error: AUComponent.h kAudioUnitErr_UnknownFileType");
		case kAudioUnitErr_FileNotSpecified:
			return NSLocalizedString(@"Unknown File Type", @"Audio Unit Error: AUComponent.h kAudioUnitErr_FileNotSpecified");
		case kAudioUnitErr_FormatNotSupported:
			return NSLocalizedString(@"Format Not Supported", @"Audio Unit Error: AUComponent.h kAudioUnitErr_FormatNotSupported");
		case kAudioUnitErr_Uninitialized:
			return NSLocalizedString(@"Unitialized", @"Audio Unit Error: AUComponent.h kAudioUnitErr_Uninitialized");
		case kAudioUnitErr_InvalidScope:
			return NSLocalizedString(@"Invalid Scope", @"Audio Unit Error: AUComponent.h kAudioUnitErr_InvalidScope");
		case kAudioUnitErr_PropertyNotWritable:
			return NSLocalizedString(@"Property Not Writable", @"Audio Unit Error: AUComponent.h kAudioUnitErr_PropertyNotWritable");
		case kAudioUnitErr_CannotDoInCurrentContext:
			return NSLocalizedString(@"Cannot Do In Current Context", @"Audio Unit Error: AUComponent.h kAudioUnitErr_CannotDoInCurrentContext");
		case kAudioUnitErr_InvalidPropertyValue:
			return NSLocalizedString(@"Invalid Property Value", @"Audio Unit Error: AUComponent.h kAudioUnitErr_InvalidPropertyValue");
		case kAudioUnitErr_PropertyNotInUse:
			return NSLocalizedString(@"Property Not In Use", @"Audio Unit Error: AUComponent.h kAudioUnitErr_PropertyNotInUse");
		case kAudioUnitErr_Initialized:
			return NSLocalizedString(@"Initialized", @"Audio Unit Error: AUComponent.h kAudioUnitErr_Initialized");
		case kAudioUnitErr_InvalidOfflineRender:
			return NSLocalizedString(@"Invalid Offline Render", @"Audio Unit Error: AUComponent.h kAudioUnitErr_InvalidOfflineRender");
		case kAudioUnitErr_Unauthorized:
			return NSLocalizedString(@"Unauthorized", @"Audio Unit Error: AUComponent.h kAudioUnitErr_Unauthorized");
		default:
			return NSLocalizedString(@"Unrecognized Audio Unit Error", @"");
	}
}

@implementation AudioCompareController

#define NUM_CHANNELS 4

@synthesize blindCompare;
@synthesize markedFile;

-(void)awakeFromNib
{
	[window setFrameAutosaveName:@"AudioCompareMainWindow"];
	auGraph = nil;
	mixerAU = nil;
	
	blindCompare = NO;
	
	[playButton setEnabled:NO];
	[toggleFileButton setEnabled:NO];
	
	filePlayers = [[NSMutableArray alloc] initWithCapacity:NUM_CHANNELS];
	dropViews = [[NSMutableArray alloc] initWithObjects:aView, bView, cView, dView, nil];
	
	aView.channelId = 0;
	bView.channelId = 1;
	cView.channelId = 2;
	dView.channelId = 3;
	
	NSError * err = NULL;
	if(![self _createAUGraph:&err]) {
		[[NSApplication sharedApplication] presentError:err];
		[[NSApplication sharedApplication] terminate:self]; 
	}
	
	[self soloChannel:0];
	
	[aView layer].opacity = 1.0f;
	[bView layer].opacity = .30f;
	[cView layer].opacity = .30f;
	[dView layer].opacity = .30f;
	
	currentChannel = 0;
	markedFile = -1;
	
}

-(void)applicationDidFinishLaunching:(NSNotification*)notification
{
	//register defaults, um, defaults
	NSString * defaultsPath = [[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"];
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:defaultsPath]];
	
}

-(BOOL)_handleAUGraphError:(OSStatus) errCode errorString:(NSString*) errString error:(NSError**) anError
{
	if (noErr != errCode) {
		NSString * errDesc = [NSString stringWithFormat:errString, GSGetAUGraphErrorDescription(errCode)];
		NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errDesc, NSLocalizedDescriptionKey, nil];
		*anError = [[[NSError alloc] initWithDomain:NSOSStatusErrorDomain
											 code:errCode
										 userInfo:userInfo] autorelease];
		return NO;
	}	
	return YES;
}

-(BOOL)_handleAudioUnitError:(OSStatus) errCode errorString:(NSString*) errString error:(NSError**) anError
{
	if (noErr != errCode) {
		NSString * errDesc = [NSString stringWithFormat:errString, GSGetAUGraphErrorDescription(errCode)];
		NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errDesc, NSLocalizedDescriptionKey, nil];
		*anError = [[[NSError alloc] initWithDomain:NSOSStatusErrorDomain
											   code:errCode
										   userInfo:userInfo] autorelease];
		return NO;
	}	
	return YES;
	
}

-(BOOL)_createAUGraph:(NSError**)error
{
	
	if(![self _handleAUGraphError:NewAUGraph(&auGraph) errorString:NSLocalizedString(@"Couldn't create AU Graph", @"") error:error])
		return NO;
	
	CAComponentDescription caDesc;
	caDesc.componentType = kAudioUnitType_Output;
	caDesc.componentSubType = kAudioUnitSubType_DefaultOutput;
	caDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	if(![self _handleAUGraphError:AUGraphAddNode (auGraph, &caDesc, &outputNode) 
					  errorString:NSLocalizedString(@"Couldn't add node to AU Graph", @"") 
							error:error])
		return NO;

	caDesc.componentType = kAudioUnitType_Mixer;
	caDesc.componentSubType = kAudioUnitSubType_StereoMixer;
	if(![self _handleAUGraphError:AUGraphAddNode (auGraph, &caDesc, &mixerNode) 
					  errorString:NSLocalizedString(@"Couldn't add node to AUGraph", @"")
							error:error])
		return NO;

	if(![self _handleAUGraphError:AUGraphConnectNodeInput(auGraph, mixerNode, 0, outputNode, 0) 
					  errorString:NSLocalizedString(@"Couldn't connect AU Graph node input", @"") 
							error:error])
		return NO;

	caDesc.componentType = kAudioUnitType_Generator;
	caDesc.componentSubType = kAudioUnitSubType_AudioFilePlayer;

	/*
	 * Create the File Player and Converter Audio Units
	 */
	
	AUNode fileNodes[NUM_CHANNELS];

	AUNode converterNodes[NUM_CHANNELS];
	CAComponentDescription converterDesc;
	converterDesc.componentType = kAudioUnitType_FormatConverter;
	converterDesc.componentSubType = kAudioUnitSubType_AUConverter;
	converterDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	for (int i = 0; i < NUM_CHANNELS; i++) {
		if(![self _handleAUGraphError:AUGraphAddNode (auGraph, &caDesc, &fileNodes[i]) 
						  errorString:NSLocalizedString(@"Couldn't add node to AU Graph", @"")
								error:error])
			return NO;
		if(![self _handleAUGraphError:AUGraphAddNode(auGraph, &converterDesc, &converterNodes[i]) 
						  errorString:NSLocalizedString(@"Couldn't add converter node to AU Graph", @"") 
								error:error])
			return NO;
	}
	
	if(![self _handleAUGraphError:AUGraphOpen (auGraph) 
					  errorString:NSLocalizedString(@"Couldn't open AU Graph", @"")
							error:error])
		return NO;
	
	AudioUnit mAU;
	if(![self _handleAUGraphError:AUGraphNodeInfo(auGraph, mixerNode, NULL, &mAU) 
					  errorString:NSLocalizedString(@"Couldn't get AU Graph node info", @"")
							error:error])
		return NO;
	
	mixerAU = new CAAudioUnit(mixerNode, mAU);
	
	//tell the mixer we need two busses
	UInt32 numBusses = NUM_CHANNELS;

	
	if(![self _handleAudioUnitError:AudioUnitSetProperty(mAU, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numBusses, sizeof(numBusses))
						errorString:NSLocalizedString(@"Couldn't set bus count on mixer AU", @"")
							  error:error])
		return NO;

	if(![self _handleAUGraphError:AUGraphInitialize(auGraph) 
					  errorString:NSLocalizedString(@"Couldn't initialize AU Graph", @"") 
							error:error])
		return NO;
	
	for (int i = 0; i < NUM_CHANNELS; i++) {
		AudioUnit aAU;
		AudioUnit cAU;
		if(![self _handleAUGraphError:AUGraphNodeInfo(auGraph, fileNodes[i], NULL, &aAU) 
						  errorString:NSLocalizedString(@"Couldn't get AU Graph Info", @"") 
								error:error])
			return NO;
		if(![self _handleAUGraphError:AUGraphNodeInfo(auGraph, converterNodes[i], NULL, &cAU) 
						  errorString:NSLocalizedString(@"Couldn't get AU Graph Info for converter unit", @"")
								error:error]) {
			return NO;
		}
		[filePlayers insertObject: [[GSAudioFilePlayer alloc] 
									initWithAudioUnit:new CAAudioUnit(fileNodes[i], aAU) 
											 fileNode:fileNodes[i] 
										  converterAU:new CAAudioUnit(converterNodes[i], cAU)
										converterNode:converterNodes[i]] atIndex:i]; 
		
	}
	
	for (int i = 0; i < NUM_CHANNELS; i++) {
		GSAudioFilePlayer * filePlayer = [filePlayers objectAtIndex:i];
		if(![self _handleAUGraphError:AUGraphConnectNodeInput(auGraph, filePlayer.fileNode, 0, filePlayer.converterNode, 0)
						  errorString:NSLocalizedString(@"Couldn't connect node input in AU Graph", @"")
								error:error]) {
			[[dropViews objectAtIndex:i] presentError:*error];
		}
		
		//connect the converter au to the mixer au
		if(![self _handleAUGraphError:AUGraphConnectNodeInput(auGraph, filePlayer.converterNode, 0, mixerNode, i)	
						  errorString:NSLocalizedString(@"Couldn't connect converter AU to mixer AU", @"")
								error:error]) {
			[[dropViews objectAtIndex:i] presentError:*error];
		}
	}
	
	return YES;
}

-(void)setFile:(NSURL*)fileURL forChannel:(int)channel
{
	NSLog(@"%s:%s:%@:%d", __FILE__, __FUNCTION__, fileURL, channel);
	NSError * error;
	GSAudioFilePlayer * filePlayer = [filePlayers objectAtIndex:channel];
	
	if (![filePlayer setFile:fileURL error:&error]) {
		[[dropViews objectAtIndex:channel] presentError:error]; //need to generalize the views
		return;
	}
	[filePlayer playFrom:0];
	
	if(![self _handleAUGraphError:AUGraphStop(auGraph) 
					  errorString:NSLocalizedString(@"Couldn't stop AU Graph", @"") 
							error:&error]) {
		[[dropViews objectAtIndex:channel] presentError:error];
	}
	
	[playButton setEnabled:YES];
	[toggleFileButton setEnabled:YES];	
	[[dropViews objectAtIndex:channel] setNeedsDisplay:YES];	
	
	//now that we have a file, ensure that the current file corresponds with a pad with a channel.
	if ([self channelHasFile:currentChannel])
		return;
	else {
		currentChannel = channel;
		[self soloChannel:currentChannel];
		[self _updateViews];
	}
}

-(BOOL)validateMenuItem:(NSMenuItem*)item
{
	[playMenu setKeyEquivalent:@" "];
	[playMenu setKeyEquivalentModifierMask:0];
	
	if (item == playMenu) {
		if ([self isPlaying])
			[item setTitle:NSLocalizedString(@"Pause", @"")];
		else
			[item setTitle:NSLocalizedString(@"Play", @"")];
	}
	
	if (item == blindMenu) {
		if (blindCompare)
			[item setTitle:NSLocalizedString(@"Show", @"")];
		else
			[item setTitle:NSLocalizedString(@"Hide", @"")];
	}
	
	if (item == playMenu || item == switchMenu || item == returnToZeroMenu) {
		if ([self _countLoadedChannels] == 0)
			return NO;
		else
			return YES;
	}
	
	if (item == clearPadMenu) {
		if ([[filePlayers objectAtIndex:currentChannel] hasFile]) {
			return YES;
		} else {
			return NO;
		}
	}
	return YES;
}

-(void)masterVolumeChanged:(id)sender
{
	Float32 value = [masterVolumeSlider floatValue];
	mixerAU->SetParameter(kStereoMixerParam_Volume, kAudioUnitScope_Output, 0, value, 0);
}

-(void)setGain:(float)gain forChannel:(int)channel
{
	mixerAU->SetParameter(kStereoMixerParam_Volume, kAudioUnitScope_Input, channel, gain, 0);
}
		
-(void)muteAllChannels
{
	for (int i = 0; i < NUM_CHANNELS; i++) {
		[self setGain:0.0f forChannel:i];
	}
}

-(void)soloChannel:(int)channel
{
	for(int i = 0; i < NUM_CHANNELS; i++) {
		if (channel == i) {
			[self setGain:1.0f forChannel:i];
		} else {
			[self setGain:0.0f forChannel:i];
		}
	}
}

-(BOOL)isPlaying
{
	Boolean graphIsRunning = false;
	NSError * error;
	if(![self _handleAUGraphError:AUGraphIsRunning(auGraph, &graphIsRunning)
					  errorString:NSLocalizedString(@"Couldn't determine AU Graph's running state", @"")
							error:&error]) {
		[[NSApplication sharedApplication] presentError:error];
		return NO;
	}
	return graphIsRunning;
}

-(void)togglePlay:(id)sender
{
	NSError * error;
	if ([self isPlaying]) {
		if(![self _handleAUGraphError:AUGraphStop(auGraph)
						  errorString:NSLocalizedString(@"Couldn't stop AU graph", @"")
								error:&error]) {
			[[NSApplication sharedApplication] presentError:error];
		}
		[playButton setTitle:NSLocalizedString(@"Play", @"")];
	} else {
		for (int i = 0; i < NUM_CHANNELS; i++) {
			GSAudioFilePlayer * filePlayer = [filePlayers objectAtIndex:i];
			[filePlayer playFromCurrent];
		}
		if(![self _handleAUGraphError:AUGraphStart(auGraph)
						  errorString:NSLocalizedString(@"Couldn't start AU graph", @"")
								error:&error]) {
			[[NSApplication sharedApplication] presentError:error];
		}
		[playButton setTitle:NSLocalizedString(@"Pause", @"")];
	}
}

-(void)_updateViews
{
	if (blindCompare)
		return;
	for (int i = 0; i < NUM_CHANNELS; i++) {
		GSABDropView * dropView = [dropViews objectAtIndex:i];
		if (currentChannel == i) {
			[dropView layer].opacity = 1.0f;
		} else {
			[dropView layer].opacity = 0.30f;
		}
	}
}

-(void)toggleFilePlayback:(id)sender
{
	int oFile = currentChannel;
	currentChannel++;
	while (currentChannel != oFile) {
		currentChannel %= NUM_CHANNELS;
		//does currentChannel actually have a file loaded?
		if ([[filePlayers objectAtIndex:currentChannel] hasFile])
			break;
		currentChannel++;
	}
	[self soloChannel:currentChannel];
	[self _updateViews];
	
}

-(void)setPlayingChannel:(int)channel
{
	currentChannel = channel;
	[self soloChannel:currentChannel];
	[self _updateViews];
}

-(NSString*)filePathForChannel:(int)channelId
{
	GSAudioFilePlayer * filePlayer = [filePlayers objectAtIndex:channelId];
	return filePlayer.filePath;
}

-(int)selectedChannel
{
	return currentChannel;
}

-(void)returnToZero:(id)sender
{
	for (int i = 0; i < NUM_CHANNELS; i++) {
		GSAudioFilePlayer * filePlayer = [filePlayers objectAtIndex:i];
		[filePlayer playFrom:0];
	}
}

-(void)toggleBlindCompare:(id)sender
{
	blindCompare = !blindCompare;
	if (blindCompare) {
		[blindButton setTitle:NSLocalizedString(@"Show", @"")];
		for (int i = 0; i < NUM_CHANNELS; i++) {
			GSABDropView * view = [dropViews objectAtIndex:i];
			[view layer].opacity = 1.0;
			[view setNeedsDisplay:YES];
		}
		//randomly select a channel
		srandom(time(NULL));
		int n = (random() % NUM_CHANNELS);
		for (; n < NUM_CHANNELS; ++n) {
			if([self channelHasFile:n]) {
				[self setPlayingChannel:n];
				break;
			}
		}
		return;
	}
	else
		[blindButton setTitle:NSLocalizedString(@"Hide", @"")];
	
	[self _updateViews];
	
	for (int i = 0; i < NUM_CHANNELS; i++) {
		GSABDropView * view = [dropViews objectAtIndex:i];
		[view setNeedsDisplay:YES];
	}
	
}

-(void)markCurrentFile
{
	markedFile = currentChannel;
}

-(BOOL)channelHasFile:(int)channelId
{
	return [[filePlayers objectAtIndex:channelId] hasFile];
}

-(void)clearChannel:(int)channelId
{
	[[filePlayers objectAtIndex:channelId] clear];
}

-(void)clearCurrentChannel:(id)sender
{
	[self clearChannel:currentChannel];
	[[dropViews objectAtIndex:currentChannel] setNeedsDisplay:YES];
	
	//try to find a channel with something loaded
	for (int i = 0; i < NUM_CHANNELS; i++) {
		int idx = (currentChannel + i) % NUM_CHANNELS;
		if ([[filePlayers objectAtIndex:idx] hasFile]) {
			currentChannel = idx;
			[self soloChannel:currentChannel];
			break;
		}
	}
	if ([self _countLoadedChannels] == 0) {
		[playButton setEnabled:NO];
		[toggleFileButton setEnabled:NO];
	}
	[self _updateViews];
}

-(int)_countLoadedChannels
{
	int ret = 0;
	for (int i = 0; i < NUM_CHANNELS; i++) {
		if ([[filePlayers objectAtIndex:i] hasFile]) {
			ret++;
		}
	}
	return ret;
}

-(void)dealloc
{
	[filePlayers release];
	
	if (auGraph) {
		DisposeAUGraph(auGraph);
		auGraph = nil;
	}
	[super dealloc];
}

@end
