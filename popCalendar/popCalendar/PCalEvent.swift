// PCalEvent.swift

import Cocoa
import EventKit

//--------------------------------------------------------------------------------------------------------------------------------------------
@objc class PCalEvent : NSObject {
	@objc var isOnCreation = false
	@objc var hasChanges = false

	@objc private(set) var event: EKEvent!
	@objc private(set) var refDate: Date!

	@objc var title: String? { get { event.title } }
	@objc var isAllDay: Bool { get { event.isAllDay } }
	@objc var startDate: Date { get { event.startDate } }
	@objc var eventIdentifier: String { get { event.eventIdentifier } }

	@objc init(event: EKEvent, refDate: Date) {
		super.init()
		self.event = event
		self.refDate = refDate
	}

	override var description: String {
		let sd = event.startDate
		let ed = event.endDate
		return th_description("title:\(title) startDate:\(sd) endDate:\(ed)")
	}

	@objc func canSaveEvent() -> String? {
		let r = p_canSaveEvent()
		return r.canSave == true ? nil : (r.reason ?? "?")
	}
	
	private func p_canSaveEvent() -> (canSave: Bool, reason: String?) {
		if event.calendar == nil {
			return (false, THLocalizedString("No selected calendar."))
		}
		
		if event.calendar.allowsContentModifications == false {
			return (false, THLocalizedString("The calendar \"%@\" is not editable.")) //event.calendar.title
		}

		if event.title == nil || event.title!.isEmpty || event!.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			return (false, THLocalizedString("The title of event is empty."))
		}

		if event.startDate == nil || event.endDate == nil {
			return (false, THLocalizedString("The Start/End date of event is incorrect."))
		}

		if event.endDate! == event.startDate! {
			return (false, THLocalizedString("The Start/End date of event is incorrect."))
		}

		return (true, nil)
	}

	@objc func cancelChanges() {
		if self.hasChanges == false {
			return
		}
		self.hasChanges = false
		event.reset()
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension PCalEvent {

	private func stringRep() -> String {
		var rep = [String]()
	
		rep.append(self.title ?? "")

		if let sd = event.startDate, let ed = event.endDate {
			let allDay = event.isAllDay
			let cal = Calendar.current

			let sdC = cal.dateComponents([.year, .month, .day], from: sd)
			let edC = cal.dateComponents([.year, .month, .day], from: ed)
			
			let d_df = DateFormatter(withDateStyle: .short, timeStyle: .none)
			let dt_df = DateFormatter(withDateStyle: .short, timeStyle: .short)
			let t_df = DateFormatter(withDateStyle: .none, timeStyle: .short)

			let scheduled: String!
			if sdC.year == edC.year && sdC.month == edC.month && sdC.day == edC.day {
				if allDay == true {
					scheduled = d_df.string(from: sd) + " (all-day)"
				}
				else {
					scheduled = dt_df.string(from: sd) + " to " + t_df.string(from: ed)
				}
			}
			else {
				if allDay == true {
					scheduled = d_df.string(from: sd) + " to " + d_df.string(from: ed)
				}
				else {
					scheduled = dt_df.string(from: sd) + " to " + dt_df.string(from: ed)
				}
			}
			rep.append(THLocalizedString("Scheduled:") + " " + scheduled)
		}
		
		if let participants = event.attendees {

			var attendues = ""
			var partIdx = 1
			for participant in participants {

				//let pr = participant.participantRole;
				var name = participant.name
		
				if name == nil || name!.isEmpty == true {
					name = THLocalizedString("Participant") + " " + String(partIdx)
					partIdx += 1
				}
	
				let url = participant.url.absoluteString
				var email: String?
				if url.hasPrefix("mailto:") {
					email = (url as NSString).substring(from: "mailto:".count)
				}
				
				attendues += "\n\t" + name! + " <\(email ?? url)>"
			}

			rep.append(THLocalizedString("Attendues:") + " " + attendues)
		}

		if let location = event.location, location.isEmpty == false {
			rep.append(THLocalizedString("Location:") + " " + location)
		}
	
		if let notes = event.notes, notes.isEmpty == false {
			rep.append(THLocalizedString("Notes:") + " " + notes)
		}

		return rep.joined(separator: "\n")
	}

	@objc func writeToPasteboard(_ pasteboard: NSPasteboard) -> Bool {
		let pbItem = NSPasteboardItem()
		pbItem.setString(stringRep(), forType: NSPasteboard.PasteboardType.string)

		pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
		return pasteboard.writeObjects([pbItem])
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension PCalEvent {

	//+ (void)drawDateEventsBackgroundWithRect:(NSRect)rect calColors:(NSArray*)calColors isHightlighted:(BOOL)isHightlighted corner:(CGFloat)corner
	//{
	//	if (calColors.count==0)
	//		return;
	//
	//	CGFloat opacity=isHightlighted==YES?0.33:0.15;
	//
	//	if (calColors.count==1)
	//	{
	//		[[(NSColor*)calColors.lastObject colorWithAlphaComponent:opacity] set];
	//		if (corner>0.0)
	//			[[NSBezierPath bezierPathWithRoundedRect:rect xRadius:corner yRadius:corner] fill];
	//		else
	//			[[NSBezierPath bezierPathWithRect:rect] fill];
	//		return;
	//	}
	//
	//	[NSGraphicsContext saveGraphicsState];
	//	{
	//		NSBezierPath *cadre=[NSBezierPath bezierPathWithRoundedRect:rect xRadius:corner yRadius:corner];
	//		[cadre addClip];
	//
	//		CGFloat circleSz=rect.size.width>rect.size.height?rect.size.width:rect.size.height;
	//		circleSz*=1.5;
	//
	//		NSRect circleRect=NSMakeRect(rect.origin.x+CGFloatFloor((rect.size.width-circleSz)/2.0),rect.origin.y+CGFloatFloor((rect.size.height-circleSz)/2.0),circleSz,circleSz);
	//		[NSColor drawColors:calColors inCircleRect:circleRect opacity:opacity];
	//
	//		if (isHightlighted==YES && corner>0.0)
	//		{
	//			[[NSColor colorWithCalibratedWhite:0.67 alpha:0.33] set];
	//			[cadre stroke];
	//		}
	//	}
	//	[NSGraphicsContext restoreGraphicsState];
	//}

	//+ (void)drawEventsBackgroundWithCircleRect:(NSRect)circleRect calColors:(NSArray*)calColors isHightlighted:(BOOL)isHightlighted
	//{
	//	if (calColors==nil || calColors.count==0)
	//		return;
	//
	//	[NSColor drawColors:calColors inCircleRect:circleRect opacity:isHightlighted==YES?0.33:0.15];
	//	if (isHightlighted==YES)
	//	{
	//		[[NSColor colorWithCalibratedWhite:0.67 alpha:0.33] set];
	//		[[NSBezierPath bezierPathWithOvalInRect:circleRect] fill];
	//	}
	//}

}
//--------------------------------------------------------------------------------------------------------------------------------------------


//--------------------------------------------------------------------------------------------------------------------------------------------
extension PCalEvent {

	@objc class func relativeDelayOffSet(ofAlarm alarm: EKAlarm) -> String? {
		let ros = alarm.relativeOffset
		if ros == 0.0 {
			return THLocalizedString("Time of Event")
		}

		if ros > 0 {
			if ros < 1.0.th_min {
				return String(format: THLocalizedString("%f seconds after"), ros)
			}
			if ros == 1.0.th_min {
				return THLocalizedString("1 minute after")
			}
			if ros <  1.0.th_hour {
				return String(format: THLocalizedString("%.0f minutes after"), ros / 1.0.th_min)
			}
			if ros == 1.0.th_hour {
				return THLocalizedString("1 hour after")
			}
			if ros < 1.0.th_day {
				return String(format: THLocalizedString("%.0f hours after"), ros / 1.0.th_hour)
			}
			return String(format: THLocalizedString("%.0f days after"), ros / 1.0.th_day)
		}

		if ros > -1.0.th_min {
			return String(format: THLocalizedString("%f seconds before"), ros * -1.0)
		}
		if ros == -1.0.th_min {
			return THLocalizedString("1 minute before")
		}
		if ros > -1.0.th_hour {
			return String(format: THLocalizedString("%.0f minutes before"), ros / -1.0.th_min)
		}
		if ros == -1.0.th_hour {
			return THLocalizedString("1 hour before")
		}
		if ros > -1.0.th_day {
			return String(format: THLocalizedString("%.0f hours before"), ros / -1.0.th_hour)
		}
	
		return String(format: THLocalizedString("%.0f days before"), ros / -1.0_.th_day)
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
