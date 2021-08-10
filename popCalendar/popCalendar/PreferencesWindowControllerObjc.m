// PreferencesWindowControllerObjc.m

#import "PreferencesWindowControllerObjc.h"
#import "TH_APP-Swift.h"

//--------------------------------------------------------------------------------------------------------------------------------------------
@implementation PreferencesWindowControllerObjc

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	// Month View
	[self.weekDayDisplayModeSeg setLabel:THLocalizedString(@"WeekDayDisplayMode_MON") forSegment:0];
	[self.weekDayDisplayModeSeg setLabel:THLocalizedString(@"WeekDayDisplayMode_M") forSegment:1];
	[self.weekDayDisplayModeSeg setSelectedSegment:[PCalUserContext shared].weekDayDisplayMode];
	NSRect frame=self.weekDayDisplayModeSeg.frame;
	[self.weekDayDisplayModeSeg sizeToFit];
	self.weekDayDisplayModeSeg.frame=NSMakeRect(frame.origin.x,frame.origin.y,CGFloatFloor(self.weekDayDisplayModeSeg.frame.size.width),frame.size.height);

	[self.yearEventsDisplayModePopMenu removeAllItems];
	[self.yearEventsDisplayModePopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"PCalEventsDisplayModeUniqueColor") tag:PCalEventsDisplayModeUniqueColor]];
	[self.yearEventsDisplayModePopMenu.menu addItem:[NSMenuItem separatorItem]];
	[self.yearEventsDisplayModePopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"PCalEventsDisplayModeNotDisplay") tag:PCalEventsDisplayModeNotDisplay]];
	[self.yearEventsDisplayModePopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"PCalEventsDisplayModeShowColors") tag:PCalEventsDisplayModeShowColors]];

	[self.monthEventsDisplayModePopMenu removeAllItems];
	[self.monthEventsDisplayModePopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"PCalEventsDisplayModeUniqueColor") tag:PCalEventsDisplayModeUniqueColor]];
	[self.monthEventsDisplayModePopMenu.menu addItem:[NSMenuItem separatorItem]];
	[self.monthEventsDisplayModePopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"PCalEventsDisplayModeNotDisplay") tag:PCalEventsDisplayModeNotDisplay]];
	[self.monthEventsDisplayModePopMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedString(@"PCalEventsDisplayModeShowColors") tag:PCalEventsDisplayModeShowColors]];

	[self updateUI];
}

- (void)updateUI
{
	// Year View
	[self.yearEventsDisplayModePopMenu selectItemWithTag:[PCalUserContext shared].yearEventsDisplayMode];

	// Month View
	[self.firstWeekDayMenu removeAllItems];

	NSUInteger firstWeekday=[NSCalendar currentCalendar].firstWeekday;
	NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
	NSArray *weekdaySymbols=dateFormatter.weekdaySymbols;
	NSString *dFirstWeekday=firstWeekday-1<weekdaySymbols.count?weekdaySymbols[firstWeekday-1]:@"--";

	[self.firstWeekDayMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:THLocalizedStringFormat(@"Default (%@)",dFirstWeekday) representedObject:nil]];
	if (weekdaySymbols.count==7)
	{
		[self.firstWeekDayMenu.menu addItem:[NSMenuItem separatorItem]];
		for (NSUInteger i=0;i<7;i++)
			[self.firstWeekDayMenu.menu addItem:[NSMenuItem th_menuItemWithTitle:weekdaySymbols[i] representedObject:@(i+1)]];
	}

	NSNumber *pFirstWeekDay=[PCalUserContext shared].firstWeekDay;
	for (NSInteger i=0;i<self.firstWeekDayMenu.numberOfItems;i++)
	{
		if (pFirstWeekDay==nil || [(NSNumber*)[self.firstWeekDayMenu itemAtIndex:i].representedObject isEqualToNumber:pFirstWeekDay]==YES)
		{
			[self.firstWeekDayMenu selectItemAtIndex:i];
			break;
		}
	}

	[self.monthEventsDisplayModePopMenu selectItemWithTag:[PCalUserContext shared].monthEventsDisplayMode];
}

#pragma mark -

- (IBAction)changeAction:(id)sender
{
//	if (sender==self.iconAsClockButton)
//	{
//		if (self.iconAsClockButton.state==NSControlStateValueOn && ([PCalUserContext shared].iconStyle&PCalIconStyleClock)==0)
//		{
//			if ([PCalUserContext shared].iconStyle==0)
//				[PCalUserContext shared].iconStyle=		PCalIconStyleClock|
//																				PCalIconStyleClockUse24Hour|
//																				//PCalIconStyleClockShowAmPm|
//																				PCalIconStyleClockShowDay|
//																				PCalIconStyleClockShowDate;
//			else
//				[PCalUserContext shared].iconStyle+=PCalIconStyleClock;
//		}
//		else if (self.iconAsClockButton.state==NSControlStateValueOff && ([PCalUserContext shared].iconStyle&PCalIconStyleClock)!=0)
//			[PCalUserContext shared].iconStyle-=PCalIconStyleClock;
//
//		[_observator preferencesWindowController:self didChange:@{@"kind":@(2)}];
//		[self updateUI];
//	}

	// Year View
	if (sender==self.yearEventsDisplayModePopMenu)
	{
		[PCalUserContext shared].yearEventsDisplayMode=self.yearEventsDisplayModePopMenu.selectedTag;
	}
	// Month View
	else if (sender==self.firstWeekDayMenu)
	{
		[PCalUserContext shared].firstWeekDay=self.firstWeekDayMenu.selectedItem.representedObject;
	}
	else if (sender==self.weekDayDisplayModeSeg)
	{
		[PCalUserContext shared].weekDayDisplayMode=self.weekDayDisplayModeSeg.selectedSegment;
	}
	else if (sender==self.monthEventsDisplayModePopMenu)
	{
		[PCalUserContext shared].monthEventsDisplayMode=self.monthEventsDisplayModePopMenu.selectedTag;
	}
}

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
