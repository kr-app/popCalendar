// CalMonthViewClass.m

#import "CalMonthViewClass.h"
#import "TH_APP-Swift.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation CalMonthViewClass

- (BOOL)wantsDefaultClipping { return NO; }

- (PCalMonth*)month { return _month; }

//- (PCalDate*)clickedDate { return _clickedDate; }
//- (NSRect)clickedDateRect { return _clickedDateRect; }

- (id)initWithFrame:(NSRect)frame month:(PCalMonth*)month delegate:(id)delegate
{
	if (self=[super initWithFrame:frame])
	{
		self.autoresizingMask=NSViewWidthSizable|NSViewHeightSizable;
		self.menu=[[NSMenu alloc] initWithTitle:@"RightMenu" delegate:self autoenablesItems:NO];

		_month=month;
		_delegate=delegate;
	}
	return self;
}

- (NSRect)headerFrameRect { return NSZeroRect; }

- (NSRect)datesFrameRect { return NSZeroRect; }

- (NSSize)datesCellSizeWithDatesFrame:(NSRect)datesFrame { return NSZeroSize ; }

- (BOOL)point:(NSPoint)point isInCellWithRect:(NSRect)cellRect { return YES; }

- (PCalDate*)dateAtPoint:(NSPoint)point rect:(NSRect*)pRect
{
	if (_month.weeks.count==0)
		return nil;

	NSRect datesFrame=[self datesFrameRect];

	if (point.x<datesFrame.origin.x || point.x>datesFrame.origin.x+datesFrame.size.width)
		return nil;
	if (point.y<datesFrame.origin.y || point.y>datesFrame.origin.y+datesFrame.size.height)
		return nil;

	NSSize cellSz=[self datesCellSizeWithDatesFrame:datesFrame];

	NSInteger hIndex=(NSInteger)CGFloatFloor((datesFrame.size.height-point.y)/cellSz.height);
	if (hIndex<0 || hIndex>=_month.weeks.count)
		return nil;

	PCalWeek *week=_month.weeks[hIndex];
	NSInteger wIndex=(NSInteger)CGFloatFloor((point.x-datesFrame.origin.x)/cellSz.width);
	if (wIndex<0 || wIndex>=week.dates.count)
		return nil;

	NSRect cRect=NSZeroRect;
	cRect.origin.x=datesFrame.origin.x+CGFloatFloor((CGFloat)wIndex*cellSz.width);
	cRect.origin.y=datesFrame.origin.y+datesFrame.size.height-CGFloatFloor((CGFloat)(hIndex+1)*cellSz.height);
	cRect.size=NSMakeSize(CGFloatFloor(cellSz.width),CGFloatFloor(cellSz.height));

	if ([self point:point isInCellWithRect:cRect]==NO)
		return nil;

	if (pRect!=NULL)
		*pRect=cRect;

	return week.dates[wIndex];
}

- (BOOL)getDateRect:(NSRect*)pRect ofCalDate:(PCalDate*)date
{
	if (date==nil || _month.weeks.count==0)
		return NO;

	PCalMonthDatePosition *position=[_month getPositionOfDateWithYear:date.year month:date.month day:date.day];
	if (position.hPosition==-1 && position.wPosition==-1)
		return NO;

	NSRect datesFrame=[self datesFrameRect];
	NSSize cellSz=[self datesCellSizeWithDatesFrame:datesFrame];

	NSRect cRect=NSZeroRect;
	cRect.origin.x=datesFrame.origin.x+CGFloatFloor((CGFloat)position.wPosition*cellSz.width);
	cRect.origin.y=datesFrame.origin.y+datesFrame.size.height-CGFloatFloor((CGFloat)(position.hPosition+1)*cellSz.height);
	cRect.size=NSMakeSize(CGFloatFloor(cellSz.width),CGFloatFloor(cellSz.height));

	if (pRect!=NULL)
		*pRect=cRect;

	return YES;
}

- (void)setHeaderPressed:(BOOL)headerPressed
{
	_headerPressed=headerPressed;
	[self setNeedsDisplay:YES];
}

- (void)setIsSwitchingMode:(BOOL)isSwitchingMode
{
	if (isSwitchingMode==_isSwitchingMode)
		return;
	_isSwitchingMode=isSwitchingMode;
	[self setNeedsDisplay:YES];

	int aPlacerAilleur;
	if (isSwitchingMode==NO && self.window!=nil)
		[self generateTooltips];
}

#pragma mark -

- (void)mouseDown:(NSEvent*)event
{
	if ([_delegate monthViewCanPerformAction:self]==NO)
		return;

	NSPoint point=_downPoint=[self convertPoint:event.locationInWindow fromView:nil];
	NSRect headerFrameRect=[self headerFrameRect];

	if (headerFrameRect.size.height>0.0 && NSMouseInRect(point,headerFrameRect,NO)==YES)
	{
		[_delegate monthViewDidHighlightMonth:self];
		[self setHeaderPressed:YES];
		return;
	}

	NSRect dateRect=NSZeroRect;
	PCalDate *date=[self dateAtPoint:point rect:&dateRect];

//	if (theEvent.clickCount>1)
//	{
//		NSLog(@"DOUBLE");
//	}

	NSMutableDictionary *actionInfo=[NSMutableDictionary dictionaryWithObjectsAndKeys:@(2),@"kind",nil];
	[actionInfo setValue:date forKey:@"date"];
	[actionInfo setValue:NSStringFromRect(dateRect) forKey:@"dateRect"];
	[actionInfo setValue:event forKey:@"event"];
	[_delegate monthView:self performAction:actionInfo];

	[super mouseDown:event];
}

- (void)mouseUp:(NSEvent*)event
{
	if (_headerPressed==YES)
	{
		[_delegate monthViewDidUnhighlightMonth:self];
		[self setHeaderPressed:NO];
	}

	NSPoint point=[self convertPoint:event.locationInWindow fromView:nil];
	if (TH_IsEqualNSPoint(point,_downPoint,5.0)==YES)
	{
		NSRect headerFrameRect=[self headerFrameRect];
		if (headerFrameRect.size.height>0.0 && NSMouseInRect(point,headerFrameRect,NO)==YES)
		{
			BOOL slow=(event.modifierFlags&NSEventModifierFlagShift)!=0?YES:NO;
			[_delegate monthViewDidSelectMonth:self infos:@{@"slow":@(slow)}];
			return;
		}
	}

	[super mouseUp:event];
}

- (void)mouseDragged:(NSEvent*)event
{
	if (_headerPressed==YES)
	{
		NSPoint point=[self convertPoint:event.locationInWindow fromView:nil];
		if (TH_IsEqualNSPoint(point,_downPoint,5.0)==NO)
		{
			[_delegate monthViewDidUnhighlightMonth:self];
			[self setHeaderPressed:NO];
		}
	}
	[super mouseDragged:event];
}

- (void)rightMouseDown:(NSEvent*)event
{
	if ([_delegate monthViewCanPerformAction:self]==NO)
		return;

	NSPoint downPoint=[self convertPoint:event.locationInWindow fromView:nil];
	NSRect headerFrameRect=[self headerFrameRect];

	if (headerFrameRect.size.height>0.0 && NSMouseInRect(downPoint,headerFrameRect,self.isFlipped)==YES)
	{
		BOOL slow=(event.modifierFlags&NSEventModifierFlagShift)!=0?YES:NO;
		[_delegate monthViewDidSelectMonth:self infos:@{@"slow":@(slow)}];
		return;
	}

	_clickedDate=[self dateAtPoint:downPoint rect:NULL];
	[_delegate monthView:self performAction:@{@"kind":@(2)}];

	[super rightMouseDown:event];
}

- (PCalDate*)selectedDate { return _selectedDate; }

- (void)setSelectDate:(PCalDate*)date
{
	if (date==_selectedDate)
		return;

	[_selectedDate attributedStringOfDayNeedsUpdate];
	_selectedDate=date==nil?nil:[_month calDateWithYear:date.year month:date.month day:date.day];
	[_selectedDate attributedStringOfDayNeedsUpdate];

	[self setNeedsDisplay:YES];
}

//- (void)selectDate:(PCalDate*)date distribute:(BOOL)distribute
//{
//	if (date!=nil)
//		date=[_month calDateWithYear:date.year month:date.month day:date.day];
//
//	NSRect dateRect=NSZeroRect;
//	if ([self getDateRect:&dateRect ofCalDate:date]==NO)
//		return;
//
//	NSDictionary *actionInfo=[NSDictionary dictionaryWithObjectsAndKeys:@(2),@"kind",date,@"date",NSStringFromRect(dateRect),@"dateRect",nil];
//	[_delegate monthView:self performAction:actionInfo];
//}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation CalMonthViewClass(ContextualMenu)

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if (menu==self.menu)
	{
		[menu removeAllItems];

		[menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"Show Date in Calendar App") target:self action:@selector(mi_menu:) representedObject:_clickedDate tag:1 isEnabled:_clickedDate!=nil?YES:NO]];
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"New Event") target:self action:@selector(mi_menu:) representedObject:nil tag:2 isEnabled:_clickedDate!=nil?YES:NO]];

		NSArray *events=[_clickedDate.events sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]]];
		for (PCalEvent *event in events)
		{
			if (event==events[0])
				[menu addItem:[NSMenuItem separatorItem]];
			[menu addItem:[NSMenuItem th_menuItemWithTitle:event.title!=nil?event.title:event.description target:self action:@selector(mi_menu:) representedObject:event tag:3 isEnabled:YES]];
		}
	}
}

- (void)mi_menu:(NSMenuItem*)sender
{
	if (sender.tag==1)
		[_delegate monthView:self performAction:@{@"kind":@(1),@"date":sender.representedObject}];
	else if (sender.tag==2)
	{
	}
	else if (sender.tag==3)
	{
		[_delegate monthView:self performAction:@{@"kind":@(3),@"calEvent":sender.representedObject}];
	}
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation CalMonthViewClass(ToolTips)

- (void)generateTooltips
{
	[self removeAllToolTips];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MonthView-NoTooltips"]==YES)
		return;

	NSRect datesFrame=[self datesFrameRect];
	NSSize cellSz=[self datesCellSizeWithDatesFrame:datesFrame];
	NSPoint pt=NSMakePoint(datesFrame.origin.x,datesFrame.origin.y+datesFrame.size.height-cellSz.height);
	
	for (PCalWeek *week in _month.weeks)
	{
		for (NSInteger i=0;i<week.dates.count;i++)
		{
			[self addToolTipRect:NSMakeRect(pt.x+1.0,pt.y+1.0,cellSz.width-2.0,cellSz.height-2.0) owner:self userData:NULL];
			pt.x+=cellSz.width;
		}
		pt.x=datesFrame.origin.x;
		pt.y-=cellSz.height;
	}
}

- (NSString*)view:(NSView*)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void*)data
{
	if (_selectedDate!=nil)
		return nil;
	
	PCalDate *date=[self dateAtPoint:point rect:NULL];
	if (date==nil)
		return nil;
	
	PCalWeek *week=[_month calDateWeekWithYear:date.year month:date.month day:date.day];
	if (week.weekOfYear==0)
		[week updateWeekOfYearWithCalendar:_month.source.calendar];

	NSMutableString *string=[NSMutableString string];

	static NSDateFormatter *dateFormatter=nil;
	if (dateFormatter==nil)
		dateFormatter=[[NSDateFormatter alloc] initWithDateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterNoStyle];

	//[string appendFormat:@"%@\t%@ %ld",[dateFormatter stringFromDate:date.date],THLocalizedString(@"Week"),week.weekOfYear];
	[string appendFormat:@"%@",[dateFormatter stringFromDate:date.date]];

	if (date.hasEvents==YES)
	{
		NSString *pointLine=@"---------------";

		static NSDictionary *attrs=nil;
		if (attrs==nil)
			attrs=@{NSFontAttributeName:[NSFont systemFontOfSize:11.0]};

		while ([pointLine sizeWithAttributes:attrs].width+3.0<[string sizeWithAttributes:attrs].width)
			pointLine=[pointLine stringByAppendingString:@"-"];

		[string appendFormat:@"\n%@",pointLine];
		for (PCalEvent *event in date.events)
			[string appendFormat:@"\n• %@",event.event.title];
	}
//	else
//		[string appendFormat:@"%@",THLocalizedString(@"(No Event)")];

	return [NSString stringWithString:string];
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
