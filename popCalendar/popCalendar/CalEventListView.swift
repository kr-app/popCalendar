// CalEventListView.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc protocol CalEventListViewDelegateProtocol: AnyObject {
	@objc func calEventListViewShouldChangeSelection(_ sender: CalEventListView) -> Bool
	@objc func calEventListView(_ sender: CalEventListView, didSelectCalEvent calEvent: PCalEvent?)
	@objc func calEventListView(_ sender: CalEventListView, wantsNewCalEvent infos: [String: Any]?)
	@objc func calEventListView(_ sender: CalEventListView, revealCalEventInCalApp calEvent: PCalEvent)
	@objc func calEventListView(_ sender: CalEventListView, deleteCalEvent calEvent: PCalEvent)
}

@objc class CalEventListView : NSView, NSMenuDelegate, THOverViewDelegateProtocol {

	static let marginTB: CGFloat = 2.0
	static let headerHeight: CGFloat = 27.0
	static let rowHeight: CGFloat = 22.0

	@objc weak var delegator: CalEventListViewDelegateProtocol!
	@objc var calSource: PCalSource!
	@objc var drawTopLine = false
	@objc var showNoSelection = false
	@objc var isDoubleClick = false

	@objc var calDate: PCalDate?

	private var containerView: CalEventListContView!
	private var dateLabel: NSTextField!
	private var plusEvent: THOverLabel!

	@objc class func frameSizeForEventCount(_ eventCount: Int) -> NSSize {
		NSSize(0.0, Self.headerHeight + Self.marginTB * 2.0 + Self.rowHeight * CGFloat(eventCount))
	}
	
	// MARK:-

	private func createViews() {
		let frameSz = self.frame.size

//		let isDark = THOSAppearance.isDarkMode()
		
		dateLabel = NSTextField.th_label(withFrame: NSRect(		8.0,
																									frameSz.height - Self.headerHeight + CGFloatFloor((Self.headerHeight - 16.0) / 2.0) - 2.0,
																									frameSz.width - 40.0 - 8.0 * 2.0,
																									16.0), controlSize: .regular)
		dateLabel.autoresizingMask = [.width, .minYMargin]
		dateLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize(for: .regular))
		addSubview(dateLabel)

		plusEvent = THOverLabel(frame: NSRect(		frameSz.width - 4.0 - 20.0,
																				frameSz.height - Self.headerHeight + CGFloatFloor((Self.headerHeight - 20.0)) / 2.0 - 2.0,
																				20.0, 20.0))
		plusEvent.autoresizingMask = [.minXMargin, .minYMargin]
		plusEvent.toolTip = THLocalizedString("New Event")
		plusEvent.delegator = self
		plusEvent.textAlignment = .center
		plusEvent.font = NSFont.systemFont(ofSize: 15.0)
//		plusEvent.backgroundColor=[NSColor orangeColor];
//		plusEvent.drawsBackground=YES;
		addSubview(plusEvent)
		
		let scrollView = NSScrollView(frame: NSRect(0.0, Self.marginTB, frameSz.width, frameSz.height - Self.marginTB * 2.0 - Self.headerHeight))
		scrollView.autoresizingMask = [.width, .height]
//		scrollView.backgroundColor=[NSColor yellowColor];
		scrollView.drawsBackground = false
		scrollView.borderType = .noBorder
		scrollView.scrollerStyle = .overlay
		scrollView.scrollerKnobStyle = .light
		scrollView.hasHorizontalScroller = false
		scrollView.hasVerticalScroller = true
		scrollView.autohidesScrollers = true
		scrollView.verticalScroller!.controlSize = .small
		scrollView.verticalScrollElasticity = .automatic

		containerView = CalEventListContView(frame: NSRect(0.0, 0.0, frameSz.width, 0.0))
		containerView.parentListView = self
		containerView.delegator = self.delegator

		scrollView.documentView = containerView
		addSubview(scrollView)
	}
	
	// MARK:-

	override func draw(_ dirtyRect: NSRect) {
//		NSColor.orange.th_draw(inRect: self.bounds)

		let isDark = THOSAppearance.isDarkMode()

		let frameSz = self.frame.size

		if drawTopLine {
			NSColor(calibratedWhite: 0.9, alpha: isDark ? 0.25 : 1.0).set()
			NSBezierPath.fill(NSRect(0.0, frameSz.height - 1.0, frameSz.width, 1.0))
		}

	//	if (_calDate!=nil)
	//	{
	//		[[NSColor colorWithCalibratedWhite:self.isDarkStyle==YES?0.75:0.80 alpha:self.isDarkStyle==YES?0.75:1.0] set];
	//		[NSBezierPath fillRect:NSMakeRect(0.0,frameSz.height-CalEventList_headerHeight-1.0,frameSz.width,1.0)];
	//	}

		if showNoSelection {
		//	if (_calDate==nil)
		//		[THLocalizedString(@"No Selected Date") drawInRect:NSMakeRect(0.0,CGFloatFloor((frameSz.height-15.0)/2.0),frameSz.width,15.0) withAttributes:attrs];
			let attrs: [NSAttributedString.Key: Any] = [	.font: NSFont.systemFont(ofSize: 13.0),
																				.foregroundColor: NSColor(calibratedWhite: isDark ? 0.75 : 0.5, alpha: 1.0),
																				.paragraphStyle: NSParagraphStyle.th_paragraphStyle(withAlignment: .center)]

			if calDate != nil && containerView.hasEvents() == false {
				let msg = THLocalizedString("No Event")
				msg.draw(in: NSRect(0.0,((frameSz.height - Self.headerHeight - 15.0) / 2.0).rounded(.down), frameSz.width, 16.0), withAttributes: attrs)
			}
		}
	}
	
	@objc func updateWithCalDate(_ calDate: PCalDate?, events: [PCalEvent]?, selectedEvent: String?) {
		
		if dateLabel == nil {
			createViews()
			self.menu = NSMenu(withTitle: "RightMenu", delegate: self, autoenablesItems: false)
		}
	
		self.calDate = calDate
		isDoubleClick = false

		//let frameSz = self.frame.size
		let isDark = THOSAppearance.isDarkMode()
		
		plusEvent.setTextNormal("+", font: nil, color: NSColor(calibratedWhite: isDark ? 0.75 : 0.5, alpha: 1.0))
		plusEvent.setTextOver("+", font: nil, color: NSColor(calibratedWhite: isDark ? 1.0 : 0.33, alpha: 1.0), underlineStyle: 0)
		plusEvent.setTextPressed("+", font: nil, color: NSColor(calibratedWhite: isDark ? 0.75 : 0.1, alpha: 1.0), underlineStyle: 0)
		plusEvent.isHidden = calDate == nil

		dateLabel.stringValue = calDate == nil ? "" : DateFormatter(withDateFormat: "EEEE d MMMM").string(from: calDate!.date)
		//_dateLabel.textColor = isDark ? NSColor.white : NSColor.black
		//_newEventOverText setHidden:calDate!=nil?NO:YES];

		containerView.reloadData(withEvents: events, selectedEvent: selectedEvent)
		needsDisplay = true
	}

	@objc func selectEvent(_ eventId: String?) {
		containerView.selectEvent(eventId)
	}

	@objc func contentSize(withOptions options: Int) -> NSSize {
		var cSize = containerView.frame.size
		
		if (options&1) != 0 && cSize.height == 0.0 {
			cSize.height += 24.0
		}
		cSize.height += Self.marginTB * 2.0 + Self.headerHeight

		return NSSize(cSize.width, cSize.height)
	}

	// MARK: -
	
	func overView(_ sender: THOverView, drawRect rect: NSRect, withState state: THOverViewState) {
	}
	
	func overView(_ sender: THOverView, didPressed withInfo: [String : Any]?) {
		delegator.calEventListView(self, wantsNewCalEvent: nil)
	}

	// MARK:-

	override func mouseDown(with event: NSEvent) {
		if delegator.calEventListViewShouldChangeSelection(self) == false {
			return
		}
		
		containerView.selectEvent(nil)
		delegator.calEventListView(self, didSelectCalEvent: nil)
	}

	override func rightMouseDown(with event: NSEvent) {
		containerView.selectEvent(nil)
		delegator.calEventListView(self, didSelectCalEvent: nil)
		super.rightMouseDown(with: event)
	}

	// MARK:-

	func menuNeedsUpdate(_ menu: NSMenu) {
		menu.removeAllItems()
	
		menu.addItem(THMenuItem(withTitle: THLocalizedString("New Event"), block: {() in
			if self.delegator.calEventListViewShouldChangeSelection(self) == false {
				return
			}
			self.containerView.selectEvent(nil)
			self.delegator.calEventListView(self, wantsNewCalEvent: nil)
		}))
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
