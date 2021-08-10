// EventEditorViewController.h

#import <Cocoa/Cocoa.h>
#import "TH_APP-Swift.h"

//@interface EventEditorClickectTextField : NSTextField
//@property (nonatomic,weak) IBOutlet id clickDelegator;
//@end

//--------------------------------------------------------------------------------------------------------------------------------------------
@interface EventEditorViewController : NSViewController <	NSWindowDelegate,
																								NSMenuDelegate,
																								NSTextDelegate,
																								THOverViewDelegateProtocol>
{
	__weak id _delegator;

	PCalSource *_calSource;
	PCalDate *_calDate;
	PCalEvent *_calEvent;
	BOOL _isUserCancelling;
	
	BOOL _hasCalendars;
	BOOL _isEditable;

	BOOL _isDarkStyle;
	NSColor *_darkDefaultTextColor;
}

@property (nonatomic,strong) IBOutlet NSView *contentView;
//@property (nonatomic,strong) IBOutlet NSProgressIndicator *loadingIndicator;
@property (nonatomic,strong) IBOutlet THOverView *cancelOView;
@property (nonatomic,strong) IBOutlet THOverView *saveOView;

@property (nonatomic,strong) IBOutlet THOverView *calendarsOverView;
@property (nonatomic,strong) IBOutlet NSTextField *titleField;

@property (nonatomic,strong) IBOutlet NSButton *allDayButton;
@property (nonatomic,strong) IBOutlet NSDatePicker *fromDatePicker;
@property (nonatomic,strong) IBOutlet NSDatePicker *toDatePicker;
@property (nonatomic,strong) IBOutlet NSPopUpButton *inviteesPopUpMenu;
@property (nonatomic,strong) IBOutlet NSPopUpButton *alertMsgPopMenu;
@property (nonatomic,strong) IBOutlet NSTextField *locationField;
@property (nonatomic,strong) IBOutlet NSTextField *urlField;
@property (nonatomic,strong) IBOutlet NSTextView *notesTextView;

- (PCalDate*)calDate;
- (PCalEvent*)calEvent;

- (id)initWithDelegator:(id)delegator;
- (void)setDrawTopLine:(BOOL)drawTopLine;
//- (void)setAlwaysCancelButton:(BOOL)alwaysCancelButton;

- (BOOL)terminateEdition:(NSWindow*)mainWindow completion:(void (^)(BOOL isOk))bkCompletion;
- (void)updateUIWithCalDate:(PCalDate*)calDate calEvent:(PCalEvent*)calEvent calSource:(PCalSource*)calSource;
//- (void)updateUI;

- (IBAction)changeAction:(id)sender;
//- (IBAction)endEditionAction:(NSButton*)sender;

@end

@protocol EventEditorViewControllerDelegateProtocol <NSObject>
@required
- (BOOL)eventEditorViewController:(EventEditorViewController*)sender terminateEdition:(NSString*)action errorInfo:(NSDictionary**)pErrorInfo;
@end
//--------------------------------------------------------------------------------------------------------------------------------------------
