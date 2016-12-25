import UIKit
import AVFoundation
import Alamofire

class Screen3Tab1: UIViewController, UIPopoverPresentationControllerDelegate, QRCodeReaderViewControllerDelegate
{
    @IBOutlet var QRCodeReaderContainer: UIView!
    @IBOutlet var CourseName: UILabel!
    @IBOutlet var CircleProgressOuter: KDCircularProgress!
    @IBOutlet var CircleProgressInner: KDCircularProgress!
    @IBOutlet var Attended: UILabel!
    @IBOutlet var Missed: UILabel!
    @IBOutlet var Excused: UILabel!
    @IBOutlet var Message: UILabel!
    @IBOutlet var AttendedLabel: UILabel!
    @IBOutlet var MissedLabel: UILabel!
    @IBOutlet var ExcusedLabel: UILabel!
    @IBOutlet var GoToClassButton: UIButton!
    
    var lastScanned: String?
    var upcoming: UpcomingEventInstance?
    var lastUpdatedInstance: Int64 = 0
    
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
        self.Attended.text = ""
        self.Message.text = "Loading..."
        self.Missed.text = ""
        self.Excused.text = ""
        self.CircleProgressOuter.angle = 0
        self.CircleProgressInner.angle = 0
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(getUpcomingInstance),
            name: Notification.Name(rawValue: "potato.skyus.miniattend: update complete"),
            object: nil)        
        //Move to threaded task later
        super.viewDidLoad()        
        embedScanner();
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        let now = Int64(NSTimeIntervalSince1970)
        if (now - self.lastUpdatedInstance > 60)
        {
            getUpcomingInstance()
        }
    }
    
    
    @IBAction func onClick_Refresh(_ sender: Any) {
        getUpcomingInstance()
    }
    
    internal func getUpcomingInstance()
    {
        GoToClassButton.isEnabled = false
        
        let parameters = GlobalUtils.getPostParameters()
        
        Alamofire.request(GlobalUtils.getURL(forAPI: "get.php?type=upcomingevent"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON
            {
                response in
                self.upcoming = nil
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
                            } )
                            return
                        }
                        else if (json["status"]["code"] != 200)
                        {
                            GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                            GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                            self.setUpcomingInstance()
                            return
                        }
                        
                        if (json["response"].dictionary != nil)
                        {
                            let responseObject = json["response"]
                            let Title = responseObject["Title"].stringValue
                            let CourseID = Int(responseObject["CourseID"].stringValue)!
                            let StartTime = responseObject["StartTime"].stringValue
                            let IsSpecial = responseObject["IsSpecial"].boolValue
                            
                            self.upcoming = UpcomingEventInstance(title: Title, courseID: CourseID, startTime: StartTime, special: IsSpecial)
                            self.lastUpdatedInstance = Int64(NSTimeIntervalSince1970)
                        }
                    }
                case .failure(let error):
                    GlobalUtils.log("Alamofire Error: \(error)")
                    GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                    self.upcoming = nil
                }
                self.setUpcomingInstance()
        }

    }
    
    internal func setUpcomingInstance()
    {
        if let upcoming = self.upcoming
        {
            
            self.Message.text = ""
            
            var header = "\(upcoming.title)"
            
            if let course = upcoming.course
            {
                GoToClassButton.isEnabled = true
                self.AttendedLabel.isHidden = false
                self.MissedLabel.isHidden = false
                self.ExcusedLabel.isHidden = false
                self.Attended.isHidden = false
                self.Missed.isHidden = false
                self.Excused.isHidden = false
                self.CircleProgressOuter.isHidden = false
                self.CircleProgressInner.isHidden = false
                
                if (course.doiCode != "S")
                {
                    self.AttendedLabel.isHidden = true
                    self.MissedLabel.isHidden = true
                    self.ExcusedLabel.isHidden = true
                    self.Attended.isHidden = true
                    self.Excused.isHidden = true
                    self.Missed.isHidden = true
                    self.CircleProgressOuter.isHidden = true
                    self.CircleProgressInner.isHidden = true
                }
                
                self.GoToClassButton.isHidden = false
                
                if (!upcoming.special)
                {
                    if let code = course.code
                    {
                        header = "\(code)"
                        if let section = course.section
                        {
                            header = "\(code)-\(section)"
                        }
                    }
                }
                
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "HH:mm:ss";
                dateFormat.timeZone = TimeZone(abbreviation: "UTC")
                let date = dateFormat.date(from: upcoming.startTime)
                
                let offset = TimeZone.current.secondsFromGMT()
                let localdate = date?.addingTimeInterval(Double(offset))
                dateFormat.dateFormat = "HH:mm:ss"
                let localdateS = dateFormat.string(from: localdate!);
                
                
                self.CourseName.text = "\("Up next".localized): \(header) \("at".localized) \(GlobalUtils.redactSeconds(time: localdateS))"
                
                self.Attended.text = "\(course.attendedEvents) / \(course.totalEvents)"
                
                self.Excused.text = "\(course.excusedAbsences)"
                
                let outerfraction = (course.totalEvents == 0) ? 1.0 : Double(course.attendedEvents + course.excusedAbsences) / Double(course.totalEvents) //Avoid dividing by zero
                
                let innerfraction = (course.totalEvents == 0) ? 1.0 : Double(course.attendedEvents) / Double(course.totalEvents)
                
                self.CircleProgressOuter.animate(toAngle: outerfraction * 360, duration: 1.0, completion: nil)
                
                self.CircleProgressInner.animate(toAngle: innerfraction * 360, duration: 1.0, completion: nil)
                
                
                if let missableEvents = course.missableEvents
                {
                    self.Missed.text = "\(course.totalEvents - course.attendedEvents) / \(missableEvents)"
                    
                    let missPercentage = Double(course.totalEvents - course.attendedEvents - course.excusedAbsences) / Double(missableEvents)
                    
                    if (missPercentage < 0.5)
                    {
                        self.Message.text = "Your attendance is in good shape.".localized
                    }
                    else if (missPercentage >= 0.5 && missPercentage < 1)
                    {
                        if ((course.totalEvents - course.attendedEvents - course.excusedAbsences - missableEvents) == 1)
                        {
                            self.Message.text = "You are one class away from your limit.".localized
                        }
                        else
                        {
                            self.Message.text = "Try not to miss more classes.".localized
                        }
                    }
                    else
                    {
                        self.Message.text = "You exceeded the absence limit.".localized
                    }
                    
                    if (course.doiCode != "S")
                    {
                        self.Message.text = ""
                    }
                    
                }
                else
                {
                    self.Missed.text = "\(course.totalEvents - course.attendedEvents)"
                }
            }
            
        }
        else
        {
            self.AttendedLabel.isHidden = true
            self.MissedLabel.isHidden = true
            self.ExcusedLabel.isHidden = true
            self.Attended.isHidden = true
            self.Missed.isHidden = true
            self.Excused.isHidden = true
            self.CircleProgressOuter.isHidden = true
            self.CircleProgressInner.isHidden = true
            self.GoToClassButton.isHidden = true
            self.CourseName.text = "Up next".localized
            self.Message.text = "You have no upcoming classes.".localized
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClick_goToClass(_ sender: Any)
    {
        
        if Course.getCourse(withID: upcoming?.courseID) != nil
        {
            performSegue(withIdentifier: "tab1gotoclass", sender: self)
        }
        
    }
    
    func miniAttend(_ qr: String)
    {
        if let parameters = GlobalUtils.getPostParameters(forRequest: ["QRString": qr])
        {
            
            Alamofire.request(GlobalUtils.getURL(forAPI: "attend.php"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
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
                                } )
                                return
                            }
                            else if (json["status"]["code"] == 401)
                            {
                                GlobalUtils.createAlertDialog(message: "You are not enrolled in this course." .localized, delegate: self, completion: nil)
                                return
                            }
                            else if (json["status"]["code"] == 403)
                            {
                                GlobalUtils.createAlertDialog(message: "Event no longer active.".localized, delegate: self, completion: nil)
                                return
                            }
                            else if (json["status"]["code"] == 400)
                            {
                                GlobalUtils.createAlertDialog(message: "Failed to attend session. You have likely already attended this session.".localized, delegate: self, completion: nil)
                                return
                            }
                            else if (json["status"]["code"] == 404)
                            {
                                GlobalUtils.createAlertDialog(message: "Event does not exist.".localized, delegate: self, completion: nil)
                                return
                            }
                            else if (json["status"]["code"] != 200)
                            {
                                GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                                self.setUpcomingInstance()
                                return
                            }
                            
                            GlobalUtils.createAlertDialog(title: "Done".localized, message: "Your attendance has been recorded.".localized, delegate: self);
                        }
                    case .failure(let error):
                        GlobalUtils.log("Alamofire Error: \(error)")
                        GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                    }
                    
                    self.setUpcomingInstance()
            }
        }

    }
    
    //Code adapted from https://github.com/yannickl (MIT License)
    
    lazy var reader: QRCodeReaderViewController =
    {
        let builder = QRCodeViewControllerBuilder
        {
            builder in
            builder.reader          = QRCodeReader(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
            builder.showCancelButton = false
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    internal func embedScanner()
    {
        if QRCodeReader.supportsMetadataObjectTypes()
        {
            reader.delegate = self
            
            reader.completionBlock =
                {
                    (result: QRCodeReaderResult?) in
                        if let result = result
                        {
                            print("Completion with result: \(result.value) of type \(result.metadataType)")
                            self.reader.startScanning()
                        }
                }
            
            QRCodeReaderContainer.addSubview(reader.view)
            self.addChildViewController(reader)
            reader.view.frame = QRCodeReaderContainer.frame
            reader.didMove(toParentViewController: self)
        }
        else
        {
            let alert = UIAlertController(title: "Error".localized, message: "QR Code Reader not supported by your device.".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    
    // MARK: - QRCodeReader Delegate Methods
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult)
    {
        if (result.value != lastScanned)
        {
            let code = result.value.components(separatedBy: ":")
            if (code[0] != "miniAttendCode")
            {
                return
            }
            
            miniAttend(code[1])
            
            lastScanned = result.value
        }
            
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController)
    {
        GlobalUtils.log("How did you even reach this point.")
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "popover")
        {
            let destination = segue.destination
            
            destination.preferredContentSize = CGSize(width: 200, height: 200)
            
            let controller = destination.popoverPresentationController
            
            controller?.delegate = self
            
            let destination_alt = segue.destination as! Screen3Tab1Popup
            
            destination_alt.linkBack = self
        }
        else if (segue.identifier == "tab1gotoclass")
        {
            if let upcomingCourse = Course.getCourse(withID: upcoming?.courseID)
            {
                let destination = segue.destination as! Screen4
                destination.currentCourse = upcomingCourse
            }
        }
        
        
        
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none;
    }
    
    
}
