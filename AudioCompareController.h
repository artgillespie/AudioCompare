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

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>
#import "CAAudioUnit.h"

#import "GSAudioFilePlayer.h"
#import "GSABDropView.h"

@interface AudioCompareController : NSObject {
	IBOutlet NSWindow * window;
	IBOutlet NSSlider * masterVolumeSlider;
	IBOutlet NSButton * playButton;
	IBOutlet NSButton * toggleFileButton;
	IBOutlet NSButton * blindButton;

	IBOutlet NSMenuItem * playMenu;
	IBOutlet NSMenuItem * switchMenu;
	IBOutlet NSMenuItem * blindMenu;
	IBOutlet NSMenuItem * returnToZeroMenu;
	IBOutlet NSMenuItem * clearPadMenu;
	
	IBOutlet GSABDropView * aView;
	IBOutlet GSABDropView * bView;
	IBOutlet GSABDropView * cView;
	IBOutlet GSABDropView * dView;
	
	NSArray * dropViews;
	
	BOOL blindCompare;
	
	AUGraph auGraph;
	AUNode outputNode;
	AUNode mixerNode;
	CAAudioUnit * mixerAU;	
	
	NSMutableArray * filePlayers;
	
	int currentChannel;
	
	int markedFile;
}

-(void)setFile:(NSURL*)fileURL forChannel:(int)channel;
-(void)setPlayingChannel:(int)channel;
-(void)muteAllChannels;
-(void)soloChannel:(int)channel;
-(void)setGain:(float)gain forChannel:(int)channel;
-(IBAction)masterVolumeChanged:(id)sender;
-(IBAction)togglePlay:(id)sender;
-(IBAction)toggleFilePlayback:(id)sender;
-(IBAction)toggleBlindCompare:(id)sender;
-(IBAction)returnToZero:(id)sender;
-(BOOL)_createAUGraph:(NSError**)error;
-(NSString*)filePathForChannel:(int)channelId;
-(int)selectedChannel;
-(BOOL) isPlaying;
-(BOOL)channelHasFile:(int)channelId;
-(void)clearChannel:(int)channelId;
-(IBAction)clearCurrentChannel:(id)sender;
-(int)_countLoadedChannels;
-(void)_updateViews;

@property (readonly) int selectedChannel;
@property (readonly) BOOL blindCompare;
@property (readonly) int markedFile;
@end
