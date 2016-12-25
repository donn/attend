import UIKit
import Alamofire

class Screen3: UITabBarController
{
    func logout()
    {
        let defaults = UserDefaults.standard
        let token = ""
        defaults.set(token, forKey: "token")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let viewcontroller = storyboard.instantiateInitialViewController()
        
        let window = UIApplication.shared.delegate!.window!!
        
        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromBottom, animations: {
            window.rootViewController = viewcontroller
            }, completion: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        Alamofire.request(GlobalUtils.getURL(forAPI: "refresh.php"), method: .post, parameters: GlobalUtils.getPostParameters(), encoding: JSONEncoding.default)
        .responseJSON
        {
            response in
            
            switch response.result
            {
            case .success:
                if let value = response.result.value
                {
                    let json = JSON(value)
                    
                    if (json["status"]["code"] == 999)
                    {
                        GlobalUtils.createAlertDialog(message: "Your session has expired. You will be logged out." .localized, delegate: self, completion:
                            {
                                self.logout()
                        })
                        return
                    }
                    else if (json["status"]["code"] != 200)
                    {
                        GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                        GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                        return
                    }
                    
                    let defaults = UserDefaults.standard
                    
                    let newtoken = json["jwt"].stringValue
                    
                    defaults.set(newtoken, forKey: "token")

                    
                    GlobalUtils.log("Updated token.")
                    
                }
            case .failure(let error):
                GlobalUtils.log("Alamofire Error: \(error)")
                GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self)
            }
        
        }
    
        updateCourses()
    }

    func updateCourses()
    {
        if let parameters = GlobalUtils.getPostParameters()
        {
            Course.courses = nil
            
            Alamofire.request(GlobalUtils.getURL(forAPI: "get.php?type=course"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .responseJSON
                {
                    response in
                    
                    var coursesDeserialized = [Course]()
                    
                    switch response.result
                    {
                    case .success:
                        if let value = response.result.value
                        {
                            let json = JSON(value)
                            
                            if (json["status"]["code"] == 999)
                            {
                                GlobalUtils.createAlertDialog(message: "Your session has expired. You will be logged out." .localized, delegate: self, completion:
                                    {
                                        self.logout()
                                    })
                                return
                            }
                            else if (json["status"]["code"] != 200)
                            {
                                GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                                return
                            }
                            
                            let courseArray = json["response"]
                            if let courses = courseArray.array
                            {
                                for courseObject in courses
                                {
                                    let ID = Int(courseObject["ID"].stringValue)!
                                    let Name = courseObject["Title"].stringValue
                                    let Code = courseObject["Code"].string
                                    let Section = courseObject["Section"].string
                                    let DoI = courseObject["DoI"].stringValue
                                    let Privilege = Int(courseObject["Privilege"].stringValue)!
                                    
                                    let MissableEvents: Int?
                                    if let MissableEventsStr = courseObject["MissableEvents"].string
                                    {
                                        MissableEvents = Int(MissableEventsStr)!
                                    }
                                    else
                                    {
                                        MissableEvents = nil
                                    }
                                    
                                    let TotalEvents = Int(courseObject["TotalEvents"].stringValue)!
                                    let AttendedEvents = Int(courseObject["AttendedEvents"].stringValue)!
                                    let ExcusedAbsences = Int(courseObject["ExcusedAbsences"].stringValue)!
                                    
                                    let course = Course(ID: ID, name: Name, code: Code, section: Section, doiCode: DoI, privilege: Privilege, attendedEvents: AttendedEvents, totalEvents: TotalEvents, missableEvents: MissableEvents, excusedAbsences: ExcusedAbsences)
                                    
                                    if let PeopleOfInterest = courseObject["PeopleOfInterest"].array
                                    {
                                        
                                        course.peopleOfInterest = [PersonOfInterest]()
                                        
                                        
                                        
                                        for personObject in PeopleOfInterest
                                        {
                                            let FirstName = personObject["FirstName"].stringValue
                                            let LastName = personObject["LastName"].stringValue
                                            let DoICode = personObject["DoICode"].stringValue
                                            let Email = personObject["Email"].stringValue
                                            
                                            let person = PersonOfInterest(doiCode: DoICode, firstName: FirstName, lastName: LastName, email: Email)
                                            
                                            course.peopleOfInterest!.append(person)
                                        }
                                    }
                                    
                                    coursesDeserialized.append(course)
                                }
                            }
                            
                            GlobalUtils.log("Course list updated.")
                            
                        }
                    case .failure(let error):
                        GlobalUtils.log("Alamofire Error: \(error)")
                        GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self)
                    }
                    
                    Course.courses = coursesDeserialized
                    NotificationCenter.default.post(name: Notification.Name("potato.skyus.miniattend: update complete"), object: nil)
            }
        }
        else
        {
            GlobalUtils.createAlertDialog(title: "Error".localized, message: "The app has been met with a terrible fate and needs to stop.".localized, delegate: self)
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
