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

@interface GSAudioFilePlayer : NSObject {
	CAAudioUnit * converterAU;
	AudioFileID audioFileID;
	CAStreamBasicDescription  audioFileFormat;
	NSURL * audioFileURL;
	AUNode fileNode;
	AUNode converterNode;
	CAAudioUnit * filePlayerAU;
	UInt64 currentFrame;
	UInt64 totalFrames;
	BOOL fileSetFlag;
}

+(BOOL)isFileSupported:(NSURL*)fileURL;

-(id)initWithAudioUnit:(CAAudioUnit*)fileAU fileNode:(AUNode)fNode converterAU:(CAAudioUnit*)cAU converterNode:(AUNode)cNode ;
-(BOOL)setFile:(NSURL*)fileURL error:(NSError**)anError;
-(void)playFrom:(UInt64)samplePosition;
-(void)playFromCurrent;
-(BOOL)hasFile;
-(void)clear;

@property (readonly) AudioFileID audioFileID;
@property (readonly) CAStreamBasicDescription audioFileFormat;
@property (readonly) UInt64 numPackets;
@property (readwrite) AUNode fileNode;
@property (readwrite) CAAudioUnit * filePlayerAU;
@property (readwrite) AUNode converterNode;
@property (readwrite) CAAudioUnit * converterAU;
@property (readonly) NSString * filePath;
@end
