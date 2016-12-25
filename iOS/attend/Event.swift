import Foundation

class Event
{
    var ID: Int
    var courseID: Int
    var title: String
    var special: Bool
    var typicalStartTime: Date?
    
    init(withID ID: Int, courseID: Int, title: String, special: Bool, typicalStartTime: String? = nil)
    {
        self.ID = ID
        self.courseID = courseID
        self.title = title
        self.special = special
        
        
        if let startTime = typicalStartTime
        {
            
            let startTimeComponents = startTime.components(separatedBy: ":")
            
            let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
            let now = NSDate()
            var components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now as Date)
            
            components.hour = Int(startTimeComponents[0])
            components.minute = Int(startTimeComponents[1])
            components.second = Int(startTimeComponents[2])
            
            if let utcdate = gregorian.date(from: components)
            {
                self.typicalStartTime = utcdate.addingTimeInterval(TimeInterval(TimeZone.current.secondsFromGMT()))
            }
            
            
        }
    }
}

class EventInstance
{
    var ID: Int
    var title: String
    var unixStartTime: Int64
    var qrString: String
    var qrCodeActive: Bool
    var late: Bool
    
    init(ID: Int, title: String, unixStartTime: Int64, qrString: String, qrCodeActive: Bool, late: Bool)
    {
        self.ID = ID
        self.title = title
        self.unixStartTime = unixStartTime
        self.qrString = qrString
        self.qrCodeActive = qrCodeActive
        self.late = late
    }
}

class UpcomingEventInstance
{
    var title: String
    var courseID: Int
    var startTime: String
    var special: Bool
    var course: Course?
    {
        get
        {
            return Course.getCourse(withID: self.courseID);
        }
    }
    
    init(title: String, courseID: Int, startTime: String, special: Bool)
    {
        
        self.courseID = courseID
        self.title = title
        self.special = special
        self.startTime = startTime
    }
}
