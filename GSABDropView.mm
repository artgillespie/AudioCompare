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


#import "GSABDropView.h"
#import "GSAudioFilePlayer.h"
#import "AudioCompareController.h"
#import <QuartzCore/QuartzCore.h>

//code for handling dragged tracks from iTunes found at 
//http://www.mail-archive.com/cocoa-dev@lists.apple.com/msg17452.html

NSString * const iTunesPboardType = @"CorePasteboardFlavorType 0x6974756E";

@implementation GSABDropView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		_bgImage = nil;
		displayFileName = YES;
		[self setWantsLayer:YES];
		[self layer].anchorPoint = CGPointMake(0.5f, 0.5f);
 		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, 
									   NSURLPboardType, 
									   iTunesPboardType, nil]];
		_unknownImage = [NSImage imageNamed:@"Unknown.png"];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	if (controller.blindCompare) {
		[_unknownImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		return;
	} else {
		if (_bgImage) {
			[_bgImage drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		}
	}

	if (channelId == controller.markedFile) {
		//visual indication that we're the 'marked' file
		
	}
	NSString * fileName = [[NSFileManager defaultManager] displayNameAtPath:[controller filePathForChannel:channelId]];
	if ([controller channelHasFile:channelId]) {
		NSImage * fileIcon = [[NSWorkspace sharedWorkspace] iconForFile:[controller filePathForChannel:channelId]];
		NSRect r = NSMakeRect([self bounds].size.width/2.0 - 64.0, [self bounds].size.height/2.0 - 64.0, 128.0, 128.0);
		[fileIcon drawInRect:r fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
	if (fileName) {
		NSFont * font = [NSFont userFontOfSize:[NSFont systemFontSize]];
		NSMutableParagraphStyle * style = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[style setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
		[style setAlignment:NSCenterTextAlignment];
		NSMutableDictionary * attsDictionary = 
		[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:font, style, nil] 
										   forKeys:[NSArray arrayWithObjects:NSFontAttributeName, 
													NSParagraphStyleAttributeName, nil]];
		
		[fileName drawInRect:NSMakeRect(12, 0, 165, 35) withAttributes:attsDictionary];
	}
}

//Utility method for grabbing a URL from a dragging info.
//This method returns nil if a) the pasteboard doesn't contain a filename
//and b) there isn't exactly one item in the pasteboard
+(NSURL*)_getURLFromPasteboard:(id <NSDraggingInfo>)sender
{
	NSPasteboard * pboard = [sender draggingPasteboard];
	
	if ([[pboard types] containsObject:iTunesPboardType]) {
		NSLog(@"_getURLFromPasteboard: iTunesPboardType");
		NSDictionary *iTunesDictionary = [pboard
										  propertyListForType:iTunesPboardType];
		NSArray	*tracks = [iTunesDictionary valueForKey:@"Tracks"];
		NSEnumerator *enumerator = [tracks objectEnumerator];
		NSDictionary *track = [enumerator nextObject];
		NSURL * url = [NSURL URLWithString:[track objectForKey:@"Location"]];
		NSLog(@"%@", [url absoluteString]);
		if ([url isFileURL]) {
			return [url retain];
		} else {
			return nil;
		}
	}
	
	//make sure the user's dragging files
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
		//make sure they're dragging *audio* files (this array has NSStrings)
		NSArray * files = [pboard propertyListForType:NSFilenamesPboardType];
		int fileCount = [files count];
		if (fileCount != 1) { //error:  we only handle single file drags {
			return nil;
		}
		//convert the file string to a url for the ExtAudioFile api
		return [[NSURL fileURLWithPath:[files objectAtIndex:0]] retain];;
	}
	if ([[pboard types] containsObject:NSURLPboardType]) {
		NSArray * files = [pboard propertyListForType:NSURLPboardType];
		if ([files count] != 1) {
			return nil;
		}
		return (NSURL*)[files objectAtIndex:0];
	}
	
	return nil;
}

-(NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSURL * url = [GSABDropView _getURLFromPasteboard:sender];
	NSLog(@"%@", [url absoluteString]);
	if (url) {
		[url autorelease];
		if ([GSAudioFilePlayer isFileSupported:url]) {
			NSLog(@"File is supported...");
			[[self layer] setValue:[NSNumber numberWithFloat:1.02f] forKeyPath:@"transform.scale.x"];
			[[self layer] setValue:[NSNumber numberWithFloat:1.02f] forKeyPath:@"transform.scale.y"];
			return NSDragOperationCopy;
		}
	}
	return NSDragOperationNone;
}

-(void)draggingExited:(id <NSDraggingInfo>)sender
{
	[[self layer] setValue:[NSNumber numberWithFloat:1.00f] forKeyPath:@"transform.scale.x"];
	[[self layer] setValue:[NSNumber numberWithFloat:1.00f] forKeyPath:@"transform.scale.y"];
}

-(BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	//TODO:  This can take awhile:  it should be done on a separate thread with 'loading'
	//or 'initializing' message (indeterminate progress indicator?)  Otherwise
	//we get 'hang' behavior—spinning beach ball of death.

	[[self layer] setValue:[NSNumber numberWithFloat:1.00f] forKeyPath:@"transform.scale.x"];
	[[self layer] setValue:[NSNumber numberWithFloat:1.00f] forKeyPath:@"transform.scale.y"];
	
	NSURL * url = [[GSABDropView _getURLFromPasteboard:sender] autorelease];
	if (url) {
		NSLog(@"Setting audio file url on controller...");
		[controller setFile:url forChannel:channelId];
		return YES;
	}
	NSPasteboard * pboard = [sender draggingPasteboard];
	if ([[pboard types] containsObject:NSFilesPromisePboardType]) {
		return YES;
	}
	return NO;
}

-(void)setChannelId:(int)chanId
{
	char alphabet[] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'}; 
	channelId = chanId;
	_bgImage = [NSImage imageNamed:[NSString stringWithFormat:@"%c.png", alphabet[channelId]]];
	[_bgImage retain];
}

-(int)channelId
{
	return channelId;
}

-(void)toggleFileNameDisplay:(id)sender
{
	displayFileName = !displayFileName;
	[self setNeedsDisplay:YES];
}

-(void)mouseDown:(NSEvent*)event
{
	if (controller.blindCompare)
		return;
	[controller setPlayingChannel:channelId];
}

-(void)dealloc
{
	[_bgImage release];
	[super dealloc];
}

@end
