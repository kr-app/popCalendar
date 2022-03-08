// CalYearMonthView.m

#import "CalYearMonthView.h"
#import "TH_APP-Swift.h"

//---------------------------------------------------------------------------------------------------------------------------------------------
#define CYMV_HEADER_SZ_H 16.0

@implementation CalYearMonthView

- (NSDictionary*)dateStringAttributes:(NSInteger)mode
{
	static NSDictionary *attrs[16]={nil};
	if (attrs[0]==nil)
	{
		NSParagraphStyle *paragraphStyle=[NSParagraphStyle th_paragraphStyleWithAlignment:NSTextAlignmentCenter];
		NSFont *font11=[NSFont systemFontOfSize:11.0];
		NSFont *boldFont11=[NSFont boldSystemFontOfSize:11.0];
		
		attrs[0]=@{NSFontAttributeName:font11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[1]=@{NSFontAttributeName:font11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[2]=@{NSFontAttributeName:boldFont11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[3]=@{NSFontAttributeName:font11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[4]=@{NSFontAttributeName:boldFont11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[5]=@{NSFontAttributeName:boldFont11,NSForegroundColorAttributeName:TH_RGBACOLOR(255,0,0,0.5),NSParagraphStyleAttributeName:paragraphStyle};
		attrs[6]=@{NSFontAttributeName:boldFont11,NSForegroundColorAttributeName:TH_RGBCOLOR(255,0,0),NSParagraphStyleAttributeName:paragraphStyle};
		attrs[7]=@{NSFontAttributeName:font11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.4 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};

		attrs[8]=@{NSFontAttributeName:font11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[9]=@{NSFontAttributeName:font11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[10]=@{NSFontAttributeName:boldFont11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[11]=@{NSFontAttributeName:font11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[12]=@{NSFontAttributeName:boldFont11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[13]=@{NSFontAttributeName:boldFont11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.60 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
		attrs[14]=@{NSFontAttributeName:boldFont11,NSForegroundColorAttributeName:TH_RGBCOLOR(255,0,0),NSParagraphStyleAttributeName:paragraphStyle};
		attrs[15]=@{NSFontAttributeName:font11,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:0.86 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
	}
	
	BOOL isDark=NO;//[THOSAppearance isDarkMode];
	return attrs[mode+(isDark==YES?8:0)];
}

- (id)initWithFrame:(NSRect)frame month:(PCalMonth*)month delegate:(id)delegate
{
	if (self=[super initWithFrame:frame month:month delegate:delegate])
		self.autoresizingMask=NSViewMaxXMargin|NSViewMinYMargin;
	return self;
}

- (NSRect)headerFrameRect
{
	NSSize frameSz=self.frame.size;
	return NSMakeRect(2.0,frameSz.height-CYMV_HEADER_SZ_H-2.0,frameSz.width-4.0*2.0,CYMV_HEADER_SZ_H+4.0);
}

- (NSRect)datesFrameRect
{
	NSSize frameSz=self.frame.size;
	return NSMakeRect(2.0,4.0,frameSz.width-2.0*2.0,frameSz.height-CYMV_HEADER_SZ_H-6.0*2.0);
}

- (NSSize)datesCellSizeWithDatesFrame:(NSRect)datesFrame
{
	NSSize cellSz=NSMakeSize(datesFrame.size.width/7.0,datesFrame.size.height/6.0);
	cellSz.width=CGFloatFloor(cellSz.width);
	cellSz.height=CGFloatFloor(cellSz.height);
	// 20*17
	
	//	if (_isSwitchingMode==NO)
	//		THException(CGFloatFloor(cellSz.width)!=cellSz.width || CGFloatFloor(cellSz.height)!=cellSz.height,@"cellSz:%@",NSStringFromSize(cellSz));
	return cellSz;
}

#pragma mark -

- (void)setHeaderHighlighted:(BOOL)headerHighlighted
{
//	if (_headerHighlighted==headerHighlighted)
//		return;
	_headerHighlighted=headerHighlighted;
	[self setNeedsDisplay:YES];
}

- (void)updateForMouveMoved:(NSPoint)point
{
	if (NSMouseInRect(point,[self headerFrameRect],NO)==YES)
		[self setHeaderHighlighted:YES];
}

#pragma mark -

- (void)drawRect:(NSRect)dirtyRect
{
//	NSLog(@"%p dirtyRect:%@",self,NSStringFromRect(dirtyRect));
//	[[NSColor orangeColor] th_drawInRect:dirtyRect];

	NSSize frameSz=self.frame.size;
	BOOL isDark=NO;//[THOSAppearance isDarkMode];

//	[[NSColor colorWithCalibratedWhite:1.0-((CGFloat)_month.month/50.0) alpha:1.0] th_drawInRect:dirtyRect];

//	[[NSColor colorWithCalibratedWhite:_headerPressed==YES?0.5:0.7 alpha:0.2] set];
//	[NSBezierPath fillRect:NSMakeRect(2.0,frameSz.height-20.0,frameSz.width-4.0,20.0)];

//	if (_headerPressed==YES)
//		NSLog(@"_headerPressed==YES %@",self);
	
	if (_headerPressed==YES)
	{
//		[[NSColor colorWithCalibratedWhite:0.67 alpha:0.2] set];
//		NSBezierPath *bz=[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(0.0,2.0,frameSz.width,frameSz.height-2.0) xRadius:6.0 yRadius:6.0];
//		bz.lineWidth=1.0;
//		[bz stroke];
	}

	NSString *monthTitle=[_month displayMonthWithMode:@"Y"];
	if (monthTitle!=nil)
	{
		if (_monthAttrs[0]==nil)
		{
			NSFont *font=[NSFont boldSystemFontOfSize:14.0];
		
			_monthAttrs[0]=@{NSFontAttributeName:font,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:isDark==YES?1.0:0.0 alpha:1.0]};
			_monthAttrs[1]=@{NSFontAttributeName:font,NSForegroundColorAttributeName:TH_RGBCOLOR(200,0,0)};
		}

//		[[NSColor colorWithCalibratedWhite:0.5 alpha:0.5] set];
//		[NSBezierPath fillRect:NSMakeRect(6.0,frameSz.height-CYMV_HEADER_SZ_H-2.0,frameSz.width-6.0*2.0,CYMV_HEADER_SZ_H)];

		NSDictionary *attrs=_monthAttrs[_month.isCurrentMonth==YES?1:0];
		if (_headerHighlighted==YES)
		{
			NSMutableDictionary *mAttrs=[NSMutableDictionary dictionaryWithDictionary:attrs];
			mAttrs[NSUnderlineStyleAttributeName]=@(NSUnderlineStyleSingle);
			if (_headerPressed==YES)
				mAttrs[NSForegroundColorAttributeName]=[(NSColor*)attrs[NSForegroundColorAttributeName] colorWithAlphaComponent:0.66];
			attrs=mAttrs;
		}
		[monthTitle drawAtPoint:NSMakePoint(5.0,frameSz.height-CYMV_HEADER_SZ_H-2.0) withAttributes:attrs];
	}

	NSRect datesFrame=[self datesFrameRect];
	NSSize cellSz=[self datesCellSizeWithDatesFrame:datesFrame];

	// DATES
//	[[NSColor orangeColor] drawInRect:datesFrame];
	PCalDate *selectedDate=self.selectedDate;
	NSInteger eventsDisplayMode=[PCalUserContext shared].yearEventsDisplayMode;

	NSPoint pt=NSMakePoint(datesFrame.origin.x,datesFrame.origin.y+datesFrame.size.height-cellSz.height);
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
				{
					[CalEventColor drawEventColors:colors inRect:NSMakeRect(pt.x+1.0,pt.y-1.0,19.0,19.0) opacity:opacity];
//					[(NSColor*)colors.lastObject set];
//					[NSBezierPath fillRect:NSMakeRect(pt.x+0.0,pt.y-0.0,cellSz.width-0.0*2.0,cellSz.height-0.0*2.0)];
				}
			}

			NSAttributedString *as=[date attributedStringOfDay];
			if (as==nil)
			{
				NSInteger attrsMode=0;
				if (date==selectedDate)
					attrsMode=date.isToday==YES?6:3;
				else if (date.isToday==YES)
					attrsMode=date.month!=date.refMonth?5:4;
//				else if (hasEvents==YES)
//					attrsMode=2;
				else if (date.month!=date.refMonth)
					attrsMode=1;
				else if (date.isWeekEnd==YES)
					attrsMode=7;
				as=[date updateAttributedStringOfDayWithAttrs:[self dateStringAttributes:attrsMode]];
			}

			CGFloat asH=13.0;//CGFloatCeil(as.size.height);
			[as drawInRect:NSMakeRect(pt.x,pt.y+CGFloatFloor((cellSz.height-asH)/2.0)+0.0,cellSz.width,asH)];
//			[as drawAtPoint:NSMakePoint(pt.x,pt.y+CGFloatFloor((cellSz.height-asH)/2.0)+0.0)];
	
			pt.x+=cellSz.width;
		}
		
		pt.x=datesFrame.origin.x;
		pt.y-=cellSz.height;
	}
	
	if (_headerPressed==YES)
	{
//		[[NSColor colorWithWhite:0.95 alpha:0.2] set];
//		[[NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:8.0 yRadius:8.0] fill];
	}

}

//- (void)updateTrackingAreas
//{
//	//	THLogDebug(@"");
//	[super updateTrackingAreas];
//	[self generate_trackingArea];
//}
//
//- (void)generate_trackingArea
//{
//	if (_trackingArea!=nil)
//		[self removeTrackingArea:_trackingArea];
//	NSTrackingAreaOptions options=	NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp;
//	_trackingArea=[[NSTrackingArea alloc] initWithRect:self.bounds options:options owner:self userInfo:nil];
//	[self addTrackingArea:_trackingArea];
//}
//
//- (void)mouseEntered:(NSEvent*)event
//{
//	[self setHasOverView:YES];
//}
//
//- (void)mouseExited:(NSEvent*)event
//{
//	[self setHasOverView:NO];
//}
//
//- (void)setHasOverView:(BOOL)hasOverView
//{
//	if (hasOverView==YES)
//	{
//		if (_overView==nil)
//		{
//			_overView=[[THBgColorView alloc] initWithFrame:self.bounds bgColor:[NSColor colorWithCalibratedWhite:0.5 alpha:0.25]];
//			_overView.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
//			_overView.alphaValue=0.0;
//		}
//		if (_overView.superview!=self)
//			[self addSubview:_overView positioned:NSWindowBelow relativeTo:nil];
//	}
//
//	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
//	{
//		context.duration=0.25;
//		_overView.alphaValue=hasOverView==YES?1.0:0.0;
//	}
//	completionHandler:^
//	{
//		if (hasOverView==NO)
//			[_overView removeFromSuperview];
//	}];
//}

@end
//---------------------------------------------------------------------------------------------------------------------------------------------
