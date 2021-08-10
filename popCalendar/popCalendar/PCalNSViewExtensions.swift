//  PCalNSViewExtensions.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
extension NSView {

	@objc func setAlphaValue(_ alphaValue: CGFloat, withAnimator animator: Bool) {
		if animator == true {
			self.animator().alphaValue = alphaValue
		}
		else {
			self.alphaValue = alphaValue
		}
	}

	@objc func setFrame(_ frameRect: NSRect, withAnimator animator: Bool) {
		if animator == true {
			self.animator().frame = frameRect
		}
		else {
			self.frame = frameRect
		}
	}

	@objc func setFrameOrigin(_ frameOrigin: NSPoint, withAnimator animator: Bool) {
		if animator == true {
			self.animator().setFrameOrigin(frameOrigin)
		}
		else {
			self.setFrameOrigin(frameOrigin)
		}
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
