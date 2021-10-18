// CalWeekMonthView.m

#import "CalWeekMonthView.h"
#import "TH_APP-Swift.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation CalWeekMonthView

#define EVENT_BG_RECT_SZ_H 32.0
#define EVENT_BG_RECT_MARGIN_LR 8.0

- (id)initWithFrame:(NSRect)frame month:(PCalMonth*)month delegate:(id)delegate
{
	if (self=[super initWithFrame:frame month:month delegate:delegate])
	{
		_weekNumberView=[[PCalWeekNumberView alloc] initWithFrame:NSMakeRect(0.0,0.0,PCalWeekNumberView.weekNumberWnSzWidth,frame.size.height)];
		_weekNumberView.autoresizingMask=NSViewMaxXMargin|NSViewHeightSizable;
		_weekNumberView.margins=NSEdgeInsetsMake(0.0,0.0,4.0,0.0);
		[self addSubview:_weekNumberView];
	}
	return self;
}

- (void)reloadData
{
	if (self.isHidden==YES)
		return;

	[self setNeedsDisplay:YES];
	[self generateTooltips];
	[_weekNumberView updateUIWithWeeks:_month.weeks];
}

- (NSDictionary*)dateStringAttributes:(NSInteger)mode
{
	static NSDictionary *attrs[16]={nil};
	if (attrs[0]==nil)
	{
		NSColor *color=[NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
		NSParagraphStyle *paragraphStyle=[NSParagraphStyle th_paragraphStyleWithAlignment:NSTextAlignmentCenter];
		NSFont *font13=[NSFont systemFontOfSize:13.0];
		NSFont *boldFont13=[NSFont boldSystemFontOfSize:13.0];

		attrs[0]=@{NSFontAttributeName:font13,NSForegroundColorAttributeName:color,NSParagraphStyleAttributeName:paragraphStyle};
		attrs[1]=@{NSFontAttributeName:font13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[2]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:color,NSParagraphStyleAttributeName:paragraphStyle};
		attrs[3]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[4]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[5]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:TH_RGBACOLOR(255,0,0,0.5),NSParagraphStyleAttributeName:paragraphStyle};
		attrs[6]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:TH_RGBCOLOR(255,0,0),NSParagraphStyleAttributeName:paragraphStyle};
		attrs[7]=@{NSFontAttributeName:font13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};

		color=[NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
		attrs[8]=@{NSFontAttributeName:font13,NSForegroundColorAttributeName:color,NSParagraphStyleAttributeName:paragraphStyle};
		attrs[9]=@{NSFontAttributeName:font13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[10]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:color,NSParagraphStyleAttributeName:paragraphStyle};
		attrs[11]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[12]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[13]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.70 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[14]=@{NSFontAttributeName:boldFont13,NSForegroundColorAttributeName:TH_RGBCOLOR(255,0,0),NSParagraphStyleAttributeName:paragraphStyle};
		attrs[15]=@{NSFontAttributeName:font13,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
	}

	BOOL isDark=[THOSAppearance isDarkMode];
	return attrs[mode+(isDark==YES?8:0)];
}

- (NSRect)datesFrameRect
{
	NSSize frameSz=self.frame.size;

	CGFloat weekNumberWnSzWidth=PCalWeekNumberView.weekNumberWnSzWidth;
	CGFloat borderSpaceWn=PCalWeekNumberView.borderSpaceWn;
	
	CGFloat ptX=weekNumberWnSzWidth+borderSpaceWn;
	CGFloat w=frameSz.width-ptX;
	
	if (CGFloatFloor(w/7.0)!=w/7.0)
	{
		CGFloat offset=w/7.0-CGFloatFloor(w/7.0);
		ptX+=CGFloatFloor(offset/2.0);
		w=CGFloatFloor(w/7.0)*7.0;
	}

	return NSMakeRect(ptX,4.0,w,frameSz.height-4.0);
}

- (NSSize)datesCellSizeWithDatesFrame:(NSRect)datesFrame
{
	NSSize cellSz=NSMakeSize(datesFrame.size.width/7.0,datesFrame.size.height/(CGFloat)_month.weeks.count); // H variable selon nb semaines
	if (_isSwitchingMode==NO)
	{
		//THException(CGFloatFloor(cellSz.width)!=cellSz.width,@"datesFrame:%@ cellSz:%@",NSStringFromRect(datesFrame),NSStringFromSize(cellSz));
		if (CGFloatFloor(cellSz.width)!=cellSz.width)
			THLogError(@"window:%@ datesFrame:%@ cellSz:%@",self.window,NSStringFromRect(datesFrame),NSStringFromSize(cellSz));
	}
	return cellSz;
}

- (BOOL)point:(NSPoint)point isInCellWithRect:(NSRect)cellRect
{
	if (point.x<(cellRect.origin.x+EVENT_BG_RECT_MARGIN_LR) || point.x>(cellRect.origin.x+cellRect.size.width-EVENT_BG_RECT_MARGIN_LR))
		return NO;

	CGFloat mH=(cellRect.size.height-EVENT_BG_RECT_SZ_H)/2.0;
	if (point.y<(cellRect.origin.y+mH) || point.y>(cellRect.origin.y+cellRect.size.height-mH))
		return NO;

	return YES;
}

/*- (void)drawWeekEnd:(NSSize)frameSz datesFrame:(NSRect)datesFrame cellSz:(NSSize)cellSz
{
	PCalWeek *firstWeek=_month.weeks.count>0?_month.weeks[0]:nil;
	if (firstWeek==nil)
		return;

	NSInteger firstWeekday=firstWeek.firstWeekday;
	//NSColor *fillColor=[NSColor colorWithCalibratedWhite:_isDarkStyle==YES?0.50:0.90 alpha:_isDarkStyle==YES?0.25:0.5];
	//NSColor *bordColor=[NSColor colorWithCalibratedWhite:_isDarkStyle==YES?0.33:0.80 alpha:1.0];
	
	NSColor *fillColor=[NSColor colorWithCalibratedWhite:0.98 alpha:1.0];
//	NSColor *borderColor=[NSColor colorWithCalibratedWhite:0.8 alpha:0.2];

	CGFloat offSet=7.0-firstWeekday;

	if (firstWeekday==1)
	{
		CGFloat offSetL=4.0;
	
		[fillColor set];
		[NSBezierPath fillRect:NSMakeRect(datesFrame.origin.x+offSetL,0.0,cellSz.width-offSetL,frameSz.height-0.0)];

		CGFloat ptX=datesFrame.origin.x+cellSz.width*6.0;
		[NSBezierPath fillRect:NSMakeRect(ptX,0.0,frameSz.width-ptX,frameSz.height-0.0)];

//		[borderColor set];
//		[NSBezierPath fillRect:NSMakeRect(datesFrame.origin.x+offSetL,frameSz.height-1.0,cellSz.width-offSetL,1.0)]; // left top
//		[NSBezierPath fillRect:NSMakeRect(datesFrame.origin.x+cellSz.width,0.0,1.0,frameSz.height-0.0)]; // left right
//
//		[NSBezierPath fillRect:NSMakeRect(datesFrame.origin.x+cellSz.width*6.0,0.0,1.0,frameSz.height-0.0)]; // right left
//		ptX=datesFrame.origin.x+cellSz.width*6.0;
//		[NSBezierPath fillRect:NSMakeRect(ptX,frameSz.height-1.0,frameSz.width-ptX,1.0)]; // right top
	}
	else if (firstWeekday==2)
	{
		CGFloat ptX=datesFrame.origin.x+cellSz.width*offSet;
		CGFloat szW=frameSz.width-ptX;
	
		[fillColor set];
		[NSBezierPath fillRect:NSMakeRect(ptX,0.0,szW,frameSz.height-0.0)];

//		[borderColor set];
////			[NSBezierPath fillRect:NSMakeRect(ptX,frameSz.height-1.0,szW,1.0)]; // top
//		[NSBezierPath fillRect:NSMakeRect(ptX,0.0,1.0,frameSz.height-0.0)]; // left
	}
	else
	{
		CGFloat ptX=datesFrame.origin.x+cellSz.width*offSet;

		[fillColor set];
		[NSBezierPath fillRect:NSMakeRect(ptX,0.0,cellSz.width*2.0,frameSz.height-0.0)];

//		[borderColor set];
//		[NSBezierPath fillRect:NSMakeRect(ptX,frameSz.height-1.0,cellSz.width*2.0,1.0)]; // top
//		if (firstWeekday!=7)
//			[NSBezierPath fillRect:NSMakeRect(ptX,0.0,1.0,frameSz.height-0.0)]; // left
//		if (firstWeekday!=1)
//			[NSBezierPath fillRect:NSMakeRect(datesFrame.origin.x+cellSz.width*(offSet+2.0),0.0,1.0,frameSz.height-0.0)]; // right
	}

}*/

- (void)drawRect:(NSRect)dirtyRect
{
//	NSSize frameSz=self.frame.size;
	BOOL isDark=[THOSAppearance isDarkMode];

	NSRect datesFrame=[self datesFrameRect];
	NSSize cellSz=[self datesCellSizeWithDatesFrame:datesFrame];
	NSPoint pt=NSMakePoint(datesFrame.origin.x,datesFrame.origin.y+datesFrame.size.height-CGFloatFloor(cellSz.height));
	PCalDate *selectedDate=self.selectedDate;
	NSInteger eventsDisplayMode=[PCalUserContext shared].monthEventsDisplayMode;

//	[[NSColor greenColor] drawInRect:self.bounds];
//	[[NSColor orangeColor] drawInRect:datesFrame];

//	// DayNumber Line
//	if (_isDarkStyle==NO)
//	{
//		[[NSColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
//		[NSBezierPath fillRect:NSMakeRect(datesFrame.origin.x+5.0,0.0,1.0,frameSz.height)];
////		[NSBezierPath fillRect:NSMakeRect(datesFrame.origin.x+5.0,frameSz.height-1.0,frameSz.width,1.0)];
//	}

	NSArray *uniquesColors=CalEventColor.uniquesColors;

	for (PCalWeek *week in _month.weeks)
	{
		for (PCalDate *date in week.dates)
		{
//			[[NSColor colorWithCalibratedWhite:(date.day%2)==0?0.5:0.77 alpha:1.0] drawInRect:NSMakeRect(pt.x,pt.y,cellSz.width,cellSz.height)];

			BOOL hasEvents=date.hasEvents;

			if (_isSwitchingMode==NO)
			{
				id colors=nil;
				CGFloat opacity=isDark==YES?0.33:0.33;
				NSRect rect=NSMakeRect(pt.x+CGFloatFloor((cellSz.width-26.0)/2.0),pt.y+CGFloatFloor((cellSz.height-26.0)/2.0),26.0,26.0);

				if (date==selectedDate)
				{
					colors=[NSColor colorWithCalibratedWhite:isDark==YES?0.0:0.0 alpha:1.0];
					opacity=1.0;
				}
				else if (date.isToday==YES && date.month==date.refMonth)
				{
					colors=TH_RGBCOLOR(200,0,0);
					opacity=1.0;
				}
				else if (hasEvents==YES)
				{
					if (eventsDisplayMode==PCalEventsDisplayModeUniqueColor)
						colors=uniquesColors[(date.month!=date.refMonth?1:0)+(isDark==YES?2:0)];
					else if (eventsDisplayMode==PCalEventsDisplayModeShowColors)
						colors=date.eventsCalendarColors;
				}

				if (colors!=nil)
					[CalEventColor drawEventColors:colors inRect:rect opacity:opacity];
			}

			NSAttributedString *as=[date attributedStringOfDay];
			if (as==nil)
			{
				NSInteger attrsMode=0;
				if (date==selectedDate)
					attrsMode=date.isToday==YES?6:3;
				else if (date.isToday==YES)
					attrsMode=date.month!=date.refMonth?5:4;
				else if (hasEvents==YES)
					attrsMode=2;
				else if (date.month!=date.refMonth)
					attrsMode=1;
				else if (date.isWeekEnd==YES)
					attrsMode=7;
				as=[date updateAttributedStringOfDayWithAttrs:[self dateStringAttributes:attrsMode]];
			}

			CGFloat asH=CGFloatCeil(as.size.height);
			[as drawInRect:NSMakeRect(pt.x,CGFloatFloor(pt.y+(cellSz.height-asH)/2.0)+1.0,CGFloatFloor(cellSz.width),asH)];

			pt.x+=cellSz.width;
		}

		pt.x=datesFrame.origin.x;
		pt.y-=cellSz.height;
	}
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
