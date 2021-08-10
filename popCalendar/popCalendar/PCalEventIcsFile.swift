// PCalEventIcsFile.swift

import Foundation

//--------------------------------------------------------------------------------------------------------------------------------------------
class PCalEventIcsFile: NSObject {

	private(set) var startDate: Date!
	private(set) var endDate: Date!
	private(set) var allDay = false

	static let df_yyyy_hms = DateFormatter(withDateFormat: "yyyyMMdd HHmmss")
	static let df_yyyy = DateFormatter(withDateFormat: "yyyyMMdd")

	private var filePath: String!
	private var lines: [String]!

	init?(withFile file: String) {
		super.init()
	
		if let sz = FileManager.th_fileSize(atPath: file), sz > 10.th_Mio {
			THLogError("unexpected file size at:\(file)")
			return nil
		}
	
		var string: String!
		do {
			string = try String(contentsOfFile: file)
		}
		catch {
			THLogError("file:\(file) error:\(error)")
			return nil
		}

		var lines = [String]()
		string.enumerateLines( invoking: { (line: String, stop: inout Bool) in
			let l = line.trimmingCharacters(in: .whitespaces)
			if l.isEmpty == true {
				return
			}
			lines.append(l)
		})

		self.filePath = file
		self.lines = lines
		
		guard 	let startDate = date(fromValue: contentValue(forKey: "DTSTART")),
					let endDate = date(fromValue: contentValue(forKey: "DTEND"))
		else {
			THLogError("can not get start/end date")
			return nil
		}

		self.startDate = startDate.date
		self.endDate = endDate.date
		self.allDay = startDate.allDay || endDate.allDay
	}

	override var description: String {
		return th_description("filePath:\(filePath) startDate:\(startDate) endDate:\(endDate)")
	}
	
	// MARK: -

	private func contentValue(forKey key: String) -> String? {
		for line in lines {
			if line.hasPrefix(key) == false {
				continue
			}

			let r = (line as NSString).range(of: ":")
			if r.location != NSNotFound {
				return (line as NSString).substring(from: r.location + r.length)
			}

			return nil
		}

		return nil
	}

	private func date(fromValue value: String?) -> (date: Date, allDay: Bool)? {
		guard let value = value
		else {
			return nil
		}

		var dateString = value.replacingOccurrences(of: "T", with: " ")
		dateString = dateString.replacingOccurrences(of: "Z", with: "")

		if let date = Self.df_yyyy_hms.date(from: dateString) {
			return (date, false)
		}
		
		if let date = Self.df_yyyy.date(from: dateString) {
			return (date, true)
		}

		return nil
	}

}
//--------------------------------------------------------------------------------------------------------------------------------------------
