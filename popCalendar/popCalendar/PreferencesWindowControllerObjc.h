// PreferencesWindowControllerObjc.h

#import <Cocoa/Cocoa.h>

//--------------------------------------------------------------------------------------------------------------------------------------------
@class THHotKeyFieldView;

@interface PreferencesWindowControllerObjc : NSWindowController

// Year View
@property (nonatomic,strong) IBOutlet NSPopUpButton *yearEventsDisplayModePopMenu;

// Month View
@property (nonatomic,strong) IBOutlet NSPopUpButton *firstWeekDayMenu;
@property (nonatomic,strong) IBOutlet NSSegmentedControl *weekDayDisplayModeSeg;
@property (nonatomic,strong) IBOutlet NSPopUpButton *monthEventsDisplayModePopMenu;

@end
//--------------------------------------------------------------------------------------------------------------------------------------------
