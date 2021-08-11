// CalEventListRowView.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
protocol CalEventListRowViewDelegateProtocol: AnyObject {
	func calEventListRowViewCanChangeSelection(_ sender: CalEventListRowView) -> Bool
	func calEventListRowView(_ sender: CalEventListRowView, selectionDidChange infos: [String: Any]?)
	func calEventListRowViewRevealInCalApp(_ sender: CalEventListRowView)
	func calEventListRowViewWantsDelete(_ sender: CalEventListRowView)
}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
class CalEventListRowView : NSView, NSMenuDelegate {
	
	static let marginLR: CGFloat = 10.0
	static let selectionInset: CGFloat = 1.0
	static let badgeSize: CGFloat = 9.0

	weak var delegator: CalEventListRowViewDelegateProtocol!
	var isSelected = false { didSet { needsDisplay = true } }
	
	var event: PCalEvent!
	private var dateFormatter: DateFormatter!
	private var isRightSelected = false { didSet { needsDisplay = true } }
	private var badgeColor: NSColor?

	init(frameRect: NSRect, event: PCalEvent, dateFormatter: DateFormatter, delegator: CalEventListRowViewDelegateProtocol) {
		super.init(frame: frameRect)

		self.event = event
		self.dateFormatter = dateFormatter
		self.delegator = delegator
	
		self.menu = NSMenu(title: "RightMenu", delegate: self, autoenablesItems: false)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func createViews() {
		let isDark = THOSAppearance.isDarkMode()
		let frameSz = self.frame.size

		let ekCalendar = event.event.calendar
		
		badgeColor = ekCalendar?.color

		let titleLabel = NSTextField.th_label(	withFrame: NSRect(	Self.marginLR + Self.badgeSize + 6.0,
																										((frameSz.height - 16.0) / 2.0).rounded(.down), frameSz.width, 16.0),
																	controlSize: .regular)
		titleLabel.autoresizingMask = [.width]
		(titleLabel.cell as! NSTextFieldCell).lineBreakMode = .byTruncatingTail
		titleLabel.textColor = NSColor(calibratedWhite: isDark ? 1.0 : 0.0, alpha: 1.0)
		titleLabel.objectValue = event.title

		let dateLabel = NSTextField.th_label(withFrame: NSRect(		frameSz.width - 100.0 - (Self.marginLR - 2.0),
																										((frameSz.height - 16.0) / 2.0).rounded(.down),
																										100.0,
																										16.0),
																		controlSize: .regular)
		dateLabel.autoresizingMask = [.minXMargin]
		dateLabel.alignment = .right
		dateLabel.textColor = NSColor(calibratedWhite: isDark ? 0.75 : 0.5, alpha: 1.0)
		dateLabel.stringValue = event.isAllDay == true ? THLocalizedString("All-day") : dateFormatter.string(from: event.startDate)

		dateLabel.th_sizeToFitWidthOnly(alignment: .right)
		titleLabel.frame = NSRect(	titleLabel.frame.origin.x,
													titleLabel.frame.origin.y,
													dateLabel.frame.origin.x - titleLabel.frame.origin.x - 8.0,
													titleLabel.frame.size.height)

		addSubview(titleLabel)
		addSubview(dateLabel)
	}

	func isEvent(_ eventId: String) -> Bool {
		event.eventIdentifier == eventId
	}

	override func draw(_ dirtyRect: NSRect) {
	//	[[NSColor blueColor] set];
	//	[NSBezierPath fillRect:self.bounds];

		if self.subviews.count == 0 {
			createViews()
		}

		let frameSz = self.frame.size
		let isDark = THOSAppearance.isDarkMode()

		if isSelected == true {
			NSColor(calibratedWhite: isDark ? 0.5 : 0.9, alpha: isDark ? 0.5 : 0.67).set()
			NSBezierPath(roundedRect: NSRect(4.0, Self.selectionInset, frameSz.width - 4.0 * 2.0, frameSz.height - Self.selectionInset * 2.0), xRadius: 3.0, yRadius: 3.0).fill()
		}

		if isRightSelected == true {
			let bz = NSBezierPath(roundedRect: NSRect(4.0, Self.selectionInset, frameSz.width - 4.0 * 2.0, frameSz.height - Self.selectionInset * 2.0), xRadius: 3.0, yRadius: 3.0)
			bz.lineWidth=0.5;

			NSColor(calibratedWhite: isDark ? 0.75 : 0.5, alpha: isDark ? 0.75 : 1.0).set()
			bz.stroke()
		}

		if let badgeColor = badgeColor {
			badgeColor.set()
			NSBezierPath(ovalIn: NSRect(Self.marginLR, ((frameSz.height - Self.badgeSize) / 2.0).rounded(.down), Self.badgeSize, Self.badgeSize)).fill()
		}
	}

	// MARK: -

	override func mouseDown(with event: NSEvent) {
		if delegator.calEventListRowViewCanChangeSelection(self) == false {
			return
		}

		let doubleClick = event.clickCount > 1
		isSelected = doubleClick ? true : isSelected == true ? false : true

		let infos: [String: Any] = ["doubleAction": doubleClick, "NSEvent": event]
		delegator.calEventListRowView(self, selectionDidChange: infos)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension CalEventListRowView {

	func menuNeedsUpdate(_ menu: NSMenu) {
		menu.removeAllItems()

		menu.addItem(THMenuItem(title: THLocalizedString("Show in Calendar App"), block: { () in
			self.delegator.calEventListRowViewRevealInCalApp(self)
		}))

		menu.addItem(NSMenuItem.separator())

		menu.addItem(THMenuItem(title: THLocalizedString("Copy"), block: { () in
			if self.event.writeToPasteboard(NSPasteboard.general) == false {
				THLogError("writeToPasteboard == false")
			}
		}))

		menu.addItem(NSMenuItem.separator())
		let deletable = event.event.calendar.allowsContentModifications
		menu.addItem(THMenuItem(title: THLocalizedString("Delete \"\(event.title?.th_truncate(maxChars: 30, by: .byTruncatingTail))\""), enabled: deletable, block: { () in
			self.delegator.calEventListRowViewWantsDelete(self)
		}))
	}

	func menuWillOpen(_ menu: NSMenu) {
		isRightSelected = true
	}

	func menuDidClose(_ menu: NSMenu) {
		isRightSelected = false
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
