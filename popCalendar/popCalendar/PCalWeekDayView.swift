// PCalWeekDayView.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalWeekDayView : NSView {
	private var strings: [NSAttributedString]? { didSet { needsDisplay = true } }
	private var displayMode: PCalWeekDayDisplayMode?

	override var acceptsFirstResponder: Bool { get { return false } }
	override var canBecomeKeyView: Bool { get { return false } }

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.autoresizingMask = [.width, .minYMargin]
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	@objc func updateWithDays(_ days: [String], displayMode: PCalWeekDayDisplayMode) {
		let isDark = THOSAppearance.isDarkMode()

		let attrs: [NSAttributedString.Key: Any] = [ 	.paragraphStyle: NSParagraphStyle.th_paragraphStyle(withAlignment: .center),
																			.font: NSFont.boldSystemFont(ofSize: 10.0),
																			.foregroundColor: NSColor(calibratedWhite: isDark ? 0.75 : 0.0, alpha: 1.0)]

		var strings = [NSAttributedString]()
		for day in days {
			strings.append(NSAttributedString(string: day, attributes: attrs))
		}

		self.strings = strings
		self.displayMode = displayMode
	}
	
	override func draw(_ dirtyRect: NSRect) {
		guard let strings = self.strings
		else {
			return
		}

	//	[[NSColor greenColor] th_drawInRect:self.bounds];
		let frameSz = self.frame.size

		let isDark = THOSAppearance.isDarkMode()

		if isDark == false {
//			[[self colorWhiteZone] th_drawInRect:NSMakeRect(0.0,1.0,frameSz.width,frameSz.height-1.0)];
//			[[self colorSepLine] th_drawInRect:NSMakeRect(0.0,0.0,frameSz.width,1.0)];
		}
		
		let weekNumberWnSzWidth = PCalWeekNumberView.weekNumberWnSzWidth
		let borderSpaceWn = PCalWeekNumberView.borderSpaceWn

		let cellW: CGFloat = (frameSz.width - weekNumberWnSzWidth - borderSpaceWn * 2.0) / 7.0
		var ptX: CGFloat = weekNumberWnSzWidth + borderSpaceWn

		for string in strings {
			let asH = string.size().height.rounded(.up)
			string.draw(in: NSRect(ptX.rounded(.down), ((frameSz.height - asH) / 2.0).rounded(.down) + 0.0, cellW, asH))
			ptX += cellW
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
