// CalYearView.h

#import <Cocoa/Cocoa.h>
#import "TH_APP-Swift.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@class PCalYear;

@interface CalYearView : NSView <	NSPopoverDelegate,
															PCalYearDelegateProtocol>
{
	__weak id _delegate;
	__weak PCalSource *_calSource;

	PCalYear *_year;
	NSArray *_monthViews;

	NSTrackingArea *_trackingArea;
	BOOL _isSwitchingMode;
	NSPopover *_myPopover;
}

+ (NSSize)contentSize;

- (id)initWithFrame:(NSRect)frameRect delegate:(id)delegate;

- (void)reloadData;
- (BOOL)terminateEdition;
- (void)willTerminateUI;
- (void)setIsSwitchingMode:(BOOL)isSwitchingMode;

- (void)switchToYear:(NSInteger)year;
- (void)performUserRequest:(NSString*)request infos:(NSDictionary*)infos;

@end

@protocol CalYearViewDelegateProtocol <NSObject>
- (void)calYearView:(CalYearView*)sender doAction:(NSDictionary*)action;
@end
//--------------------------------------------------------------------------------------------------------------------------------------------
