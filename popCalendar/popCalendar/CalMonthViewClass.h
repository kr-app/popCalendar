// CalMonthViewClass.h

#import <Cocoa/Cocoa.h>

//--------------------------------------------------------------------------------------------------------------------------------------------
@class PCalMonth;
@class PCalDate;

@interface CalMonthViewClass : NSView <NSMenuDelegate>
{
	PCalMonth *_month;
	__weak id _delegate;

	BOOL _isSwitchingMode;

	NSPoint _downPoint;
	PCalDate *_clickedDate;
	PCalDate *_selectedDate;
	BOOL _headerPressed;
}

- (PCalMonth*)month;

- (id)initWithFrame:(NSRect)frame month:(PCalMonth*)month delegate:(id)delegate;

//- (NSRect)headerFrameRect;
//- (NSRect)datesFrameRect;
//- (NSSize)datesCellSizeWithDatesFrame:(NSRect)datesFrame;
- (PCalDate*)dateAtPoint:(NSPoint)point rect:(NSRect*)pRect;

- (void)setHeaderPressed:(BOOL)headerPressed;
- (void)setIsSwitchingMode:(BOOL)isSwitchingMode;

- (PCalDate*)selectedDate;
- (void)setSelectDate:(PCalDate*)date;
//- (void)performHighlightCalDate:(PCalDate*)date;

@end

@protocol CalMonthViewClassDelegateProtocol <NSObject>
- (void)monthViewDidHighlightMonth:(CalMonthViewClass*)sender;
- (void)monthViewDidUnhighlightMonth:(CalMonthViewClass*)sender;
- (void)monthViewDidSelectMonth:(CalMonthViewClass*)sender infos:(NSDictionary*)infos;
@required
- (BOOL)monthViewCanPerformAction:(CalMonthViewClass*)sender;
- (void)monthView:(CalMonthViewClass*)sender performAction:(NSDictionary*)actionInfo;
@end
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@interface CalMonthViewClass(ContextualMenu)
@end
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@interface CalMonthViewClass(ToolTips)
- (void)generateTooltips;
@end
//--------------------------------------------------------------------------------------------------------------------------------------------
