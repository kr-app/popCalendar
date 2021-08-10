// PCalWindow.swift

import Cocoa

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalWindow : NSWindow {

	@objc var hasModalWindowDoNotClose = false
	@objc var isWinDetached = false

	override var canBecomeMain: Bool { return true }
	override var canBecomeKey: Bool { return true }

	override var description: String {
		th_description("frame:\(self.frame)")
	}

	@objc func setNewSize(_ newSize: NSSize, withAnimator animator: Bool) {
		var nwFrame = self.frame
		nwFrame.origin.y -= newSize.height - nwFrame.size.height
		nwFrame.size = newSize

		if animator == true {
			self.animator().setFrame(nwFrame, display: true)
		}
		else {
			self.setFrame(nwFrame, display: true)
		}
	}

	@objc func resize_withNewSize(_ newSize: NSSize, display: Bool) {
		var nwFrame = self.frame
		nwFrame.origin.y -= newSize.height - nwFrame.size.height
		nwFrame.size = newSize
		self.setFrame(nwFrame, display: display)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
