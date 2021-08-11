// StatusIcon.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
extension NSStatusBarButton {

	public override func mouseDown(with event: NSEvent) {

		if event.modifierFlags.contains(.control) {
			self.rightMouseDown(with: event)
			return
		}

		self.highlight(true)
		let _ = self.target?.perform(self.action, with: self)
	}

//	public override func rightMouseDown(with event: NSEvent) {
//		self.highlight(true)
//	}
	
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@objc protocol StatusIconDelegateProtocol: AnyObject {
	@objc func statusIcon(_ sender: StatusIcon, pressed info: [String: Any]?)
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class StatusIcon : NSObject {

	private var statusItem: NSStatusItem!
	weak var delegator: StatusIconDelegateProtocol!
	private var calendar = Calendar.current

	private var timer: Timer?
	private var dcMin: Int = 0

	private var iconStyle: PCalIconStyle!
	private var clockDateFormatter: DateFormatter!
	private var hasSecond = false

	@objc var statusItemWindow: NSWindow? { get { statusItem.button!.window } }

	override init() {
		super.init()

		statusItem = NSStatusBar.system.statusItem(withLength: -1)
		statusItem.button!.target = self
		statusItem.button!.action = #selector(statusItemAction)
//		statusItem.button.contentTintColor=NSColor.orangeColor;
		statusItem.button!.sendAction(on: [.leftMouseUp, .rightMouseUp])
	
		delegator = NSApplication.shared.delegate as? StatusIconDelegateProtocol
	}

	// MARK: -

	@objc func updatorTimerAction(_ sender: Timer) {

		if iconStyle.contains(.clock) == true {

			if hasSecond == false {
				let min = calendar.component(.minute, from: Date())
				if dcMin != min {
					dcMin = min
					updateIconAsClock()
				}
			}
			else {
				updateIconAsClock()
			}
		}
		else {
//			NSDateComponents *comps=[_calendar components:NSCalendarUnitDay fromDate:[NSDate date]];
//			if (_dcDay!=comps.day)
//			{
//				_dcDay=comps.day;
//				[self updateIcon];
//			}
		}

	}

	// MARK: -

	private func updateFromIconStyle() {
		if iconStyle.contains(.clock) == true {
			var format: String? = nil

			if let udDateFormat = PCalUserContext.shared.customClockDateFormat {
 				let df = DateFormatter(dateFormat: udDateFormat)
				if df.string(from: Date()).count > 0 {
					format = udDateFormat
				}
			}

			if format == nil {
				format = PCalUserContext.shared.clockDateFormat(fromIconStyle: iconStyle)
			}

			hasSecond = format!.range(of: "s") != nil

			clockDateFormatter = DateFormatter(dateFormat: format!)
		}
		else {
//			statusItem.length=30.0;
//			_clockDateFormatter=nil;
		}
	}

	@objc func setIconStyle() {
		iconStyle = PCalUserContext.shared.iconStyle

		updateFromIconStyle()

		dcMin = 0

		if timer == nil {
			timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updatorTimerAction), userInfo: nil, repeats: true)
		}

		updatorTimerAction(timer!)
		updateIcon()
	}

	// MARK: -

	private func updateIcon() {
		if iconStyle.contains(.clock) {
			updateIconAsClock()
		}
		else {
//			[self updateDisplayAsIcon];
		}
	}

	private func updateDisplayAsIcon() {
	/*	NSSize frameSz=self.frame.size;

		if (_isPressed==YES)
		{
			[_isDarkMode==YES?[NSColor colorWithCalibratedWhite:0.33 alpha:0.5]:[NSColor selectedMenuItemColor] set];
			[NSBezierPath fillRect:NSMakeRect(0.0,0.0,frameSz.width,frameSz.height)];
		}
		else
			[self updateIsDarkModeAndGetChanged];

		NSSize cSize=NSMakeSize(20.0,14.0);
		NSRect cRect=NSMakeRect(CGFloatFloor((frameSz.width-cSize.width)/2.0),CGFloatFloor((frameSz.height-cSize.height)/2.0),cSize.width,cSize.height);

		NSColor *borderColor=nil;
		if (_isDarkMode==YES)
			borderColor=[NSColor colorWithCalibratedWhite:_isPressed==YES?1.0:1.0 alpha:1.0];
		else
			borderColor=[NSColor colorWithCalibratedWhite:_isPressed==YES?1.0:0.0 alpha:1.0];

	#ifdef DEBUG
		borderColor=[NSColor redColor];
	#endif

		[borderColor set];
	//	NSBezierPath *cadre=[self bezierPathWithRoundedRect:cRect xRadius:2.0 yRadius:2.0];
	//	cadre.lineWidth=0.5;
		NSBezierPath *cadre=[self bezierPathWithRoundedRect:cRect borderLineWidth:1.0 cornerRadius:2.0];
		[cadre stroke];

		if (_isPressed==NO)
		{
	//		[[NSColor colorWithCalibratedWhite:0.9 alpha:0.9] set];
	//		[cadre fill];
		}

		[borderColor set];
		[NSBezierPath fillRect:NSMakeRect(cRect.origin.x,cRect.origin.y+12.0,cRect.size.width,2.0)];

		if (_dcDay>0)
		{
			if (_titleAttrs[0]==nil)
			{
				NSFont *font=[NSFont systemFontOfSize:10.0];
				NSParagraphStyle *paragraphStyle=[NSParagraphStyle th_paragraphStyleWithAlignment:NSTextAlignmentCenter];

				_titleAttrs[0]=@{NSFontAttributeName:font,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:_isDarkMode==YES?1.0:0.25 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
				_titleAttrs[1]=@{NSFontAttributeName:font,NSForegroundColorAttributeName:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0],NSParagraphStyleAttributeName:paragraphStyle};
			}

			NSAttributedString *as=[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld",_dcDay] attributes:_titleAttrs[_isPressed==YES?1:0]];
			CGFloat asSzH=CGFloatCeil(as.size.height);
			[as drawInRect:NSMakeRect(0.0,CGFloatFloor((frameSz.height-asSzH)/2.0)-1.0,frameSz.width,asSzH)];
		}*/
	}

	private func updateIconAsClock() {
		statusItem.button!.title = clockDateFormatter.string(from: Date())
	}

	@objc func statusItemAction(_ sender: NSButton) {
		
		var isRight = false

		if let event = NSApp.currentEvent {
			if event.type == .rightMouseUp {
				let location = NSPoint(0.0, -5.0)// event.locationInWindow// NSEvent.mouseLocation//  NSPoint(		(ml.x - mouseUpPoint.x).rounded(),
														//(ml.y - mouseUpPoint.y - (isPull == true ? 8.0 : 0.0)).rounded())

				let event = NSEvent.mouseEvent(with: .leftMouseDown,
											   location: location,
											   modifierFlags: [],
											   timestamp: 0,
											   windowNumber: sender.window!.windowNumber,
											   context: nil,
											   eventNumber: 0,
											   clickCount: 1,
											   pressure: 0.0)

				NSMenu.popUpContextMenu(MoreMenu.shared.menu, with: event!, for: sender)
				isRight = true
			}
		}

		delegator.statusIcon(self, pressed: ["isRight": isRight])
	}

	// MARK: -

	@objc func setIsPressed(_ pressed: Bool) {
		statusItem.button!.highlight(pressed)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------





//+ (NSBezierPath*)bezierPathWithRoundedRect:(NSRect)frameRect borderLineWidth:(CGFloat)borderLineWidth cornerRadius:(CGFloat)cornerRadius
//{
//	frameRect.origin.x-=0.5;
//	frameRect.origin.y-=0.5;
//	frameRect.size.width+=1.0;
//	frameRect.size.height+=1.0;
//
//	CGFloat margin=0.0;
//	NSRect rect=NSMakeRect(frameRect.origin.x+margin,frameRect.origin.y+margin,frameRect.size.width-margin*2.0,frameRect.size.height-margin*2.0);
//
//	CGFloat moitPtX=rect.origin.x+CGFloatFloor(rect.size.width/2.0);
//	CGFloat moitPtY=rect.origin.y+CGFloatFloor(rect.size.height/2.0);
//
//	NSBezierPath *bezierPath=[NSBezierPath bezierPath];
//	if (borderLineWidth>0.0)
//		bezierPath.lineWidth=borderLineWidth;
//
//	/* | */
//	[bezierPath moveToPoint:NSMakePoint(rect.origin.x,moitPtY)];
//
//	/* / */
//	NSPoint pt1=NSMakePoint(rect.origin.x,rect.origin.y+rect.size.height);
//	NSPoint pt2=NSMakePoint(moitPtX,rect.origin.y+rect.size.height);
//	[bezierPath appendBezierPathWithArcFromPoint:pt1 toPoint:pt2 radius:cornerRadius];
//
//	/* ^ */
//	[bezierPath lineToPoint:NSMakePoint(moitPtX,rect.origin.y+rect.size.height)];
//	[bezierPath lineToPoint:NSMakePoint(moitPtX,rect.origin.y+rect.size.height)];
//	[bezierPath lineToPoint:NSMakePoint(moitPtX,rect.origin.y+rect.size.height)];
//
//	/* \ */
//	pt1=NSMakePoint(rect.origin.x+rect.size.width,rect.origin.y+rect.size.height);
//	pt2=NSMakePoint(rect.origin.x+rect.size.width,moitPtY);
//	[bezierPath appendBezierPathWithArcFromPoint:pt1 toPoint:pt2 radius:cornerRadius];
//
//	/* | */
//	[bezierPath lineToPoint:NSMakePoint(rect.origin.x+rect.size.width,moitPtY)];
//
//	/* / */
//	pt1=NSMakePoint(rect.origin.x+rect.size.width,rect.origin.y);
//	pt2=NSMakePoint(moitPtX,rect.origin.y);
//	[bezierPath appendBezierPathWithArcFromPoint:pt1 toPoint:pt2 radius:cornerRadius];
//
//	/* \ */
//	pt1=NSMakePoint(rect.origin.x,rect.origin.y);
//	pt2=NSMakePoint(rect.origin.x,moitPtY);
//	[bezierPath appendBezierPathWithArcFromPoint:pt1 toPoint:pt2 radius:cornerRadius];
//
//	[bezierPath closePath];
//
//	return bezierPath;
//}
