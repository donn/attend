import Foundation

class PersonOfInterest
{
    var doiCode: String
    var firstName: String
    var lastName: String
    var email: String
    
    init(doiCode: String, firstName: String, lastName: String, email: String)
    {
        self.doiCode = doiCode
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}

class Course
{
    var ID: Int
    var name: String
    var code: String?
    var section: String?   
    var doiCode: String
    var privilege: Int
    //All events here nonspecial.
    var attendedEvents: Int
    var totalEvents: Int
    var missableEvents: Int?
    var excusedAbsences: Int
    
    var peopleOfInterest: [PersonOfInterest]?
    
    init(ID: Int, name: String, code: String?=nil, section: String?=nil, doiCode: String, privilege: Int, attendedEvents: Int, totalEvents: Int, missableEvents: Int?, excusedAbsences: Int)
    {
        self.ID = ID
        self.name = name
        self.code = code
        self.section = section
        self.doiCode = doiCode
        self.privilege = privilege
        self.attendedEvents = attendedEvents
        self.totalEvents = totalEvents
        self.missableEvents = missableEvents
        self.excusedAbsences = excusedAbsences
    }
    
    static var courses: [Course]?
    
    static func getCourse(withID cID: Int!) -> Course?
    {
        if let coursesUnwrapped = courses
            {
                for course in coursesUnwrapped
                {
                    if (course.ID == cID)
                    {
                        return course;
                    }
            }
        }
        return nil;
    }
}


