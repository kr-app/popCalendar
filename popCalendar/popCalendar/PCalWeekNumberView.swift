// PCalWeekNumberView.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalWeekNumberView : NSView {

	@objc static let weekNumberWnSzWidth: CGFloat = 28.0
	@objc static let borderSpaceWn: CGFloat = 3.0

	@objc var margins: NSEdgeInsets = NSEdgeInsetsZero

	private var strings: [NSAttributedString]? { didSet { needsDisplay = true } }

	@objc func updateUIWithWeeks(_ weeks: [PCalWeek]) {
		let isDark = THOSAppearance.isDarkMode()
		
		let attrs: [NSAttributedString.Key: Any] = [ 	.paragraphStyle: NSParagraphStyle.th_paragraphStyle(withAlignment: .center),
																			.font: NSFont.boldSystemFont(ofSize: 8.0),
																			.foregroundColor: NSColor(calibratedWhite: isDark ? 0.75 : 0.5, alpha: 1.0)]

		var strings = [NSAttributedString]()
		for week in weeks {
			strings.append(NSAttributedString(string: String(week.weekOfYear), attributes: attrs))
		}
		
		self.strings = strings
	}

	override func draw(_ dirtyRect: NSRect) {
		guard let strings = strings
		else {
			return
		}

		//[NSColor orangeColor] drawInRect:self.bounds];

		let frameSz = self.frame.size
//		if (_isDarkStyle==NO)
//		{
//			[[self colorWhiteZone] th_drawInRect:NSMakeRect(0.0,0.0,frameSz.width-1.0,frameSz.height)];
//			[[self colorSepLine] th_drawInRect:NSMakeRect(frameSz.width-1.0,0.0,1.0,frameSz.height)];
//		}

		let cellSizeH = (frameSz.height - self.margins.top - self.margins.bottom) / CGFloat(strings.count)
		var pt = NSPoint(0.0, frameSz.height - self.margins.top)

		for string in strings {
			let asH = string.size().height.rounded(.up)
			string.draw(in: NSRect(pt.x + 0.0, (pt.y - (cellSizeH + asH) / 2.0).rounded(.down) + 1.0, frameSz.width, asH))
			pt.y -= cellSizeH
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
