import UIKit
import Alamofire

class Screen4: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPopoverPresentationControllerDelegate
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
    
    @IBOutlet var ErrorMessage: UILabel!
    @IBOutlet var CircleProgressOuter: KDCircularProgress!
    @IBOutlet var CircleProgressInner: KDCircularProgress!
    @IBOutlet var Attended: UILabel!
    @IBOutlet var Missed: UILabel!
    @IBOutlet var Excused: UILabel!
    @IBOutlet var Message: UILabel!
    @IBOutlet var AttendedLabel: UILabel!
    @IBOutlet var MissedLabel: UILabel!
    @IBOutlet var ExcusedLabel: UILabel!
    @IBOutlet var PoITableView: UITableView!
    @IBOutlet var AttendanceView: UIView!
    @IBOutlet var PoILabel: UILabel!
    @IBOutlet var AttendanceLabel: UILabel!
    
    var currentCourse: Course?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.PoITableView.isUserInteractionEnabled = false
        self.PoITableView.delegate = self
        self.PoITableView.dataSource = self
        
        ErrorMessage.isHidden = true
        
        if (currentCourse == nil)
        {
            ErrorMessage.isHidden = false
            PoITableView.isHidden = true
            AttendanceView.isHidden = true
            PoILabel.isHidden = true
            return
        }
        
        self.Attended.text = ""
        self.Message.text = ""
        self.Missed.text = ""
        self.Excused.text = ""
        self.CircleProgressOuter.angle = 0
        self.CircleProgressInner.angle = 0
    
        
        let course = currentCourse!
        
        
        
        self.navigationItem.title = "\(course.name)"
        
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
            self.Message.text = "You are not involved as a student."
        }
        else
        {
        
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
            
            
        }
        else
        {
            self.Missed.text = "\(course.totalEvents - course.attendedEvents)"
            self.Message.text = ""
        }
        }
    }
    
    func onGetPeopleOfInterest()
    {
        PoITableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let count = currentCourse?.peopleOfInterest?.count
        {
            return count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellID = "Screen 4 Cell ID"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as! Screen4Cell
        
        let currentPerson = currentCourse!.peopleOfInterest![indexPath.row]
        
        if (currentPerson.doiCode == "P" || currentPerson.doiCode == "LP")
        {
            cell.Title.text = "Professor".localized
        }
        else if (currentPerson.doiCode == "ST" || currentPerson.doiCode == "SR")
        {
            cell.Title.text = "Senior Teaching Assistant".localized
        }
        else if (currentPerson.doiCode == "TA" || currentPerson.doiCode == "TR")
        {
            cell.Title.text = "Teaching Assistant".localized
        }
        
        cell.Name.text = "\(currentPerson.firstName) \(currentPerson.lastName)"
        cell.Email.text = currentPerson.email
        
        return cell;
        
    }
    
    @IBAction func onClick_Overflow(_ sender: Any)
    {
        
        let actionSheet = UIAlertController(title: "", message: "Options", preferredStyle: .actionSheet)
        
        if (currentCourse!.privilege >= 2)
        {
            actionSheet.addAction(UIAlertAction(title: "Excuse".localized, style: .default, handler: { (UIAlertAction) in
                self.performSegue(withIdentifier: "screen4popup", sender: self)
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Involve".localized, style: .default, handler: { (UIAlertAction) in
                self.performSegue(withIdentifier: "screen4gotoaddperson", sender: self)
            }))
        }
        
        if (currentCourse!.privilege >= 1)
        {
            actionSheet.addAction(UIAlertAction(title: "Events".localized, style: .default, handler: { (UIAlertAction) in
                self.performSegue(withIdentifier: "screen4gotoevents", sender: self)
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Sessions".localized, style: .default, handler: { (UIAlertAction) in
                self.performSegue(withIdentifier: "screen4gotosessions", sender: self)
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Drop Class".localized, style: .default, handler: {
            (UIAlertAction) in
            let dialog = UIAlertController(title: "Drop Class".localized, message: "Are you sure you want to send a drop request?".localized, preferredStyle: .alert)
            dialog.addAction(UIKit.UIAlertAction(title: "Yes".localized, style: .default, handler: { (UIAlertAction) in
                self.drop()
                self.dismiss(animated: true, completion: nil)                
                
                }))
            
            dialog.addAction(UIKit.UIAlertAction(title: "No".localized, style: .cancel, handler: { (UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(dialog, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: { (UIAlertAction) in
            //THANKS OBAMA
        }))
        
        actionSheet.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        present(actionSheet, animated: true) {
            //Look it's nothing
        }

    }
    
    
    func drop()
    {
        
        if let parameters = GlobalUtils.getPostParameters(forRequest: ["CourseID": currentCourse!.ID])
        {
            
            Alamofire.request(GlobalUtils.getURL(forAPI: "drop_request.php"), method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON
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
                            GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                            
                            GlobalUtils.createAlertDialog(title: "Error".localized, message: "You are not authorized to perform this action.".localized, delegate: self);
                            
                            return;
                        }
                        else if (json["status"]["code"] == 400)
                        {
                            GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                            
                            GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                            
                            return;
                        }
                        
                        GlobalUtils.createAlertDialog(title: "Done".localized, message: "Those responsible for the course have recieved your drop request.".localized, delegate: self)
                        
                    }
                case .failure(let error):
                    GlobalUtils.log("Alamofire Error: \(error)")
                    GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                }
            }
        
        
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if (segue.identifier == "screen4gotoevents")
        {
            let destination = segue.destination as! Screen6
            destination.currentCourse = currentCourse
        }
        else if (segue.identifier == "screen4gotoaddperson")
        {
            let destination = segue.destination as! Screen8
            destination.currentCourse = currentCourse
        }
        else if (segue.identifier == "screen4gotosessions")
        {
            let destination = segue.destination as! Screen9
            destination.currentCourse = currentCourse
        }
        else if (segue.identifier == "screen4popup")
        {
            let destination = segue.destination
            
            destination.preferredContentSize = CGSize(width: 400, height: 400)
            
            let controller = destination.popoverPresentationController
            
            controller?.delegate = self
            
            let destination_alt = segue.destination as! Screen4Popup
            
            destination_alt.linkBack = self

        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none;
    }
    
    
}
