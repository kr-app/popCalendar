// CalYearMonthView.h

#import <Cocoa/Cocoa.h>
#import "CalMonthViewClass.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@interface CalYearMonthView : CalMonthViewClass
{
	NSDictionary *_monthAttrs[2];
//	NSTrackingArea *_trackingArea;
//	THBgColorView *_overView;
	BOOL _headerHighlighted;
}

- (void)setHeaderHighlighted:(BOOL)headerHighlighted;
- (void)updateForMouveMoved:(NSPoint)point;

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
