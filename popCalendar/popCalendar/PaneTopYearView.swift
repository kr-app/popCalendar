// PaneTopYearView.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PaneTopBarBgView : NSView {

//- (void)drawRect:(NSRect)dirtyRect
//{
//	[[NSColor orangeColor] set];
//	[NSBezierPath fillRect:self.bounds];
//}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@objc protocol PaneTopYearViewDelegateProtocol: AnyObject {
	@objc func paneTopYearView(_ sender: PaneTopYearView, doAction action: [String: Any]?)
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PaneTopYearView : NSView, THOverViewDelegateProtocol {

	weak var delegator: PaneTopYearViewDelegateProtocol!
	var mode: String!

	private var titleLabel: THOverLabel!
	private var previousOver: THOverView!
	private var todayLabel: THOverLabel!
	private var nextOver: THOverView!
	private var moreActionsOver: THOverView?

	private let todayMarginLR: CGFloat = 2.0

	private var downPoint: NSPoint?
	private var draggedPoint: NSPoint?

	@objc init(withFrame frameRect: NSRect, mode: String, delegator: PaneTopYearViewDelegateProtocol) {
		super.init(frame: frameRect)

		self.autoresizingMask = [.minYMargin, .width]
		self.mode = mode
		self.delegator = delegator

		buildWithMode(mode)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: -
	
	override func draw(_ dirtyRect: NSRect) {
		if downPoint != nil {
			let dark = THOSAppearance.isDarkMode()
			NSColor(calibratedWhite: dark ? 0.0 : 0.92, alpha: 1.0).set()
			NSBezierPath.fill(self.bounds)
		}
	}

	// MARK: -
	
	private func buildWithMode(_ mode: String) {

		let frameSz = self.frame.size
		let marginLR: CGFloat = 10.0
		let titleSzW: CGFloat = 100.0

		if mode == "y" {
			titleLabel = THOverLabel(frame: NSRect(((frameSz.width - titleSzW) / 2.0).rounded(.down), ((frameSz.height - 27.0) / 2.0).rounded(.down) - 2.0, titleSzW, 27.0))
			titleLabel.autoresizingMask = []

			moreActionsOver = THOverView(frame: NSRect(frameSz.width - 16.0 - marginLR, ((frameSz.height - 16.0) / 2.0).rounded(.down), 16.0, 16.0))
			moreActionsOver!.delegator = self
			moreActionsOver!.autoresizingMask = [.minXMargin]
			moreActionsOver!.repImage = NSImage(named: "Settings")!.copy() as? NSImage
//			if (isDarkStyle==YES)
//				_moreActionsOver.appearance=[NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
			addSubview(moreActionsOver!)
		}
		else if mode == "m" {
			titleLabel = THOverLabel(frame: NSRect(marginLR, ((frameSz.height - 27.0) / 2.0).rounded(.down) - 2.0, titleSzW, 27.0))
			titleLabel.autoresizingMask = [.maxXMargin]
		}

		titleLabel.font = NSFont.boldSystemFont(ofSize: 20.0)
		//_titleLabel.drawsBackground=YES;_titleLabel.backgroundColor=[NSColor orangeColor];
		titleLabel.delegator = self

		buildToday(mode: mode)

		addSubview(titleLabel)
	}

	private func buildToday(mode: String) {

		let frameSz = self.frame.size
		let dark = THOSAppearance.isDarkMode()

		// <
		previousOver = THOverView(frame: NSRect(0.0, 0.0, 16.0, 16.0))
		previousOver.delegator = self
		previousOver.repImage = NSImage(named: "ChevronRight")!.th_rotated(by: 180.0).th_tinted(withColor: NSColor(calibratedWhite: dark ? 1.0 : 0.0, alpha:1.0))

		// today
		todayLabel = THOverLabel(frame: NSRect(previousOver.frame.origin.x + previousOver.frame.size.width + todayMarginLR, 0.0, 80.0, 17.0))
		todayLabel.textAlignment = .center
		todayLabel.delegator = self
		todayLabel.setTextNormal(THLocalizedString("Today"), font: NSFont.systemFont(ofSize: 13.0), color: NSColor(calibratedWhite: dark ? 1.0 : 0.0, alpha:1.0))
		todayLabel.setTextOver(THLocalizedString("Today"), font: NSFont.systemFont(ofSize: 13.0), color: NSColor(calibratedWhite: dark ? 1.0 : 0.0, alpha: 1.0), underlineStyle: NSUnderlineStyle.single.rawValue)
		todayLabel.setTextPressed(THLocalizedString("Today"), font: NSFont.systemFont(ofSize: 13.0), color: NSColor(calibratedWhite: dark ? 1.0 : 0.0, alpha: 0.66), underlineStyle: NSUnderlineStyle.single.rawValue)
		todayLabel.sizeToFitWidthOnly(alignment: .left)

		// >
		nextOver = THOverView(frame: NSRect(	todayLabel.frame.origin.x + todayLabel.frame.size.width + todayMarginLR, previousOver.frame.origin.y,
																			previousOver.frame.size.width, previousOver.frame.size.height))
		nextOver.delegator = self
		nextOver.repImage = NSImage(named: "ChevronRight")!.th_tinted(withColor: NSColor(calibratedWhite: dark ? 1.0 : 0.0, alpha:1.0))

		let padding: CGFloat = 10.0
		let todayViewSz = NSSize(nextOver.frame.origin.x + nextOver.frame.size.width, todayLabel.frame.size.height)
		let todayView = THBgColorView(frame: NSMakeRect(	mode == "m" ? (frameSz.width - todayViewSz.width - padding) : padding,
																								((frameSz.height - todayViewSz.height) / 2.0).rounded(.down),
																								todayViewSz.width, todayViewSz.height))
		//todayView.bgColor = .red
		todayView.autoresizingMask = mode == "m" ? [.minXMargin] : [.maxXMargin]
		todayView.addSubview(previousOver)
		todayView.addSubview(todayLabel)
		todayView.addSubview(nextOver)

		addSubview(todayView)
	}

	@objc func setTitle(_ title: String, animated: Bool) {
		let dark = THOSAppearance.isDarkMode()

		titleLabel.setTextNormal(title, font: nil, color: NSColor(calibratedWhite: dark ? 1.0 : 0.0, alpha:1.0))
		titleLabel.setTextOver(title, font: nil, color: NSColor(calibratedWhite: dark ? 1.0 : 0.0, alpha: 1.0), underlineStyle: NSUnderlineStyle.single.rawValue)
		titleLabel.setTextPressed(title, font: nil, color: NSColor(calibratedWhite: dark ? 1.0 : 0.0, alpha: 0.66), underlineStyle: NSUnderlineStyle.single.rawValue)
		titleLabel.sizeToFitWidthOnly(alignment: mode == "m" ? .left : .center)
	}

	// MARK: -

	func overView(_ sender: THOverView, drawRect rect: NSRect, withState state: THOverViewState) {
		if sender == previousOver || sender == nextOver || sender == moreActionsOver {
			let op: CGFloat = state == .pressed ? 0.66 : 1.0
			sender.drawRepImage(opacity: op, rect: rect)
		}
	}

	@objc func overView(_ sender: THOverView, didPressed withInfo: [String: Any]?) {
		if sender == titleLabel {
			let slow = false//([infos["event"] modifierFlags]&NSEventModifierFlagShift)!=0?YES:NO;
			delegator.paneTopYearView(self, doAction: ["action": "SWITCH_MODE", "slow": slow])
		}
		else if sender == todayLabel {
			delegator.paneTopYearView(self, doAction: ["action": "GO_TODAY"])
		}

		if sender == previousOver {
			delegator.paneTopYearView(self, doAction: ["action": "PREV"])
		}
		else if sender == nextOver {
			delegator.paneTopYearView(self, doAction: ["action": "NEXT"])
		}
		else if sender == moreActionsOver {
			delegator.paneTopYearView(self, doAction: ["action": "MORE_MENU", "sender": sender])
		}
	}

	@objc func todayButtonAction(_ sender: NSButton) {
		delegator.paneTopYearView(self, doAction: ["action": "GO_TODAY"])
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension PaneTopYearView {

	override func mouseDown(with event: NSEvent) {
		downPoint = self.convert(event.locationInWindow, from: nil)
		needsDisplay = true
		super.mouseDown(with: event)
	}

	override func mouseUp(with event: NSEvent) {
		let win = self.window as! PCalWindow

		if win.isWinDetached == true {
			let wFrame = win.frame
			let sRect = win.screen!.visibleFrame

			if (wFrame.origin.y + wFrame.size.height) >= (sRect.origin.y + sRect.size.height) {
				win.isWinDetached = false
				delegator.paneTopYearView(self, doAction: ["action": "ATTACH"])
			}
		}

		downPoint = nil
		needsDisplay = true
		super.mouseUp(with: event)
	}

	override func mouseDragged(with event: NSEvent) {

		if let downPoint = downPoint {
			let win = self.window as! PCalWindow
			let point = self.convert(event.locationInWindow, from: nil)

			if win.isWinDetached == false {
				if point.y < downPoint.y && point.th_isEqual(to: downPoint, tolerance: 30.0) == false {
					win.isWinDetached = true

					var wFrame = win.frame
					wFrame.origin.x -= CGFloatFloor(downPoint.x - point.x)
					wFrame.origin.y -= CGFloatFloor(downPoint.y - point.y)
					win.setFrame(wFrame, display: true, animate: true)

					delegator.paneTopYearView(self, doAction: ["action": "DETACH"])

	//			_downPoint=NSZeroPoint;
	//			[self setNeedsDisplay:YES];
				}
			}
			else {
				let sRect = win.screen!.visibleFrame

				var wFrame = win.frame
				wFrame.origin.x -= CGFloatFloor(downPoint.x - point.x)
				wFrame.origin.y -= CGFloatFloor(downPoint.y - point.y)

				if (wFrame.origin.x + wFrame.size.width) < (sRect.origin.x + 200.0) {
					wFrame.origin.x = sRect.origin.x - wFrame.size.width + 200.0
				}
				if (wFrame.origin.y + wFrame.size.height) < (sRect.origin.y + 200.0) {
					wFrame.origin.y = sRect.origin.y - wFrame.size.height + 200.0
				}

				if wFrame.origin.x > (sRect.origin.x + sRect.size.width-200.0) {
					wFrame.origin.x = sRect.origin.x + sRect.size.width - 200.0
				}
				if (wFrame.origin.y + wFrame.size.height) >= (sRect.origin.y + sRect.size.height) {
					wFrame.origin.y=sRect.origin.y + sRect.size.height - wFrame.size.height
				}

				win.setFrameOrigin(wFrame.origin)
			}

			draggedPoint = point
		}

		super.mouseDragged(with: event)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
