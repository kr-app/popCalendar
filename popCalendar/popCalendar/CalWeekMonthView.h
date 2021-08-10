// CalWeekMonthView.h

#import <Cocoa/Cocoa.h>
#import "CalMonthViewClass.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@class PCalWeekNumberView;

@interface CalWeekMonthView : CalMonthViewClass
{
	PCalWeekNumberView *_weekNumberView;
}

@property (nonatomic) BOOL needRecalculateFramePosition;

- (void)reloadData;

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
