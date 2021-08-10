// CalEventColor.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class CalEventColor: NSObject {

	@objc static let uniquesColors = [	NSColor(calibratedWhite: 0.92, alpha: 1.0), // mois courrant
															NSColor(calibratedWhite: 0.96, alpha: 1.0), // mois différent
															NSColor(calibratedWhite: 0.5, alpha: 1.0), // mois courrant
															NSColor(calibratedWhite: 0.33, alpha: 1.0)] // mois différent

	@objc class func drawColors(_ objects: Any?, inRect rect: NSRect, opacity: CGFloat) {

		if let color = objects as? NSColor {
			color.set()
			NSBezierPath(ovalIn: rect).fill()
			return
		}
		
		guard let colors = objects as? [NSColor]
		else {
			return
		}

		if colors.count == 0 {
			return
		}
		
		let point = NSPoint((rect.origin.x + rect.size.width / 2.0)/*.rounded(.down)*/, (rect.origin.y + rect.size.height / 2.0)/*.rounded(.down)*/)
		let increm: CGFloat = 360.0 / CGFloat(colors.count)
		var anglePos: CGFloat = -90.0

		for color in colors {
			let cercle = NSBezierPath()
			cercle.move(to: point)
			cercle.appendArc(	withCenter: point,
											radius: (rect.size.width / 2.0)/*.rounded(.down)*/,
											startAngle: anglePos,
											endAngle: anglePos + increm,
											clockwise: false)
			cercle.close()
		
			(opacity < 1.0 ? color.withAlphaComponent(opacity) : color).set()
			cercle.fill()

			anglePos += increm
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
