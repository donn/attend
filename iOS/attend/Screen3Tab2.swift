import UIKit
import Alamofire

class Screen3Tab2: UITableViewController
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
    
    var rowSelected: Int = 0
    
    @IBOutlet var AddButton: UIBarButtonItem!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reload),
            name: Notification.Name("potato.skyus.miniattend: update complete"),
            object: nil)
        
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        Alamofire.request(GlobalUtils.getURL(forAPI: "check_verification.php"), method: .post, parameters: GlobalUtils.getPostParameters(), encoding: JSONEncoding.default)
            .responseJSON
            {
                response in
                
                switch response.result
                {
                case .success:
                    if let value = response.result.value
                    {
                        let json = JSON(value)
                        if (json["status"]["code"] == 500 || json["status"]["code"] == 400)
                        {
                            GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                            
                            GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator." .localized, delegate: self);
                            
                            return
                        }
                        else if (json["status"]["code"] == 999)
                        {
                            GlobalUtils.createAlertDialog(message: "Your session has expired. You will be logged out." .localized, delegate: self, completion:
                            {
                              self.logout()
                            } )
                            
                            return
                        }
                        if (json["response"]["VerifiedProfessor"].boolValue)
                        {
                            self.navigationItem.rightBarButtonItem?.isEnabled = true
                        }
                        
                    }
                case .failure(let error):
                    GlobalUtils.log("Alamofire Error: \(error)")
                    GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                }
        }

    }
    
    
    @objc internal func reload()
    {
        self.refreshControl?.endRefreshing()
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return Course.courses?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellID = "Class Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as! Screen3Tab2Cell
        
        let currentclass = Course.courses![indexPath.row]
        if let courseCode = currentclass.code
        {
            cell.CourseFullID.text = courseCode
            if let section = currentclass.section
            {
                cell.CourseFullID.text = "\(cell.CourseFullID.text!)-\(section)"
            }
        }
        else
        {
            cell.CourseFullID.text = ""
        }
        
        cell.CourseName.text = currentclass.name
        
        var notfirst = false
        var cat = ""
        if let peopleOfInterest = currentclass.peopleOfInterest
        {
                for personOfInterest in peopleOfInterest
                {
                    if (personOfInterest.doiCode == "P")
                    {
                        if (notfirst)
                        {
                            cat += "; "
                        }
                        cat += "\(personOfInterest.lastName), \(personOfInterest.firstName)"
                        
                        notfirst = true
                    }
            }
        }
        
        cell.ProfessorName.text = cat
        cell.Attendance.text = "\(currentclass.attendedEvents)/\(currentclass.totalEvents)"
        
        return cell;
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if (Course.courses == nil)
        {
            GlobalUtils.createAlertDialog(message: "Please wait until the update is finished.", delegate: self);
            return;
        }
        rowSelected = indexPath.row
        self.performSegue(withIdentifier: "tab2gotoclass", sender: self)
    }
    
    
    @IBAction func onClick_BarPlus(_ sender: Any)
    {
      /*
        let actionSheet = UIAlertController(title: "", message: "Create or Join?".localized, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Join Class".localized, style: .default, handler: { (UIAlertAction) in
            //self.performSegue(withIdentifier: "tab2joinclass", sender: self)
            
            let dialog = UIAlertController(title: "Join Class".localized, message: "To join a course, attend any of its events by either scanning its QR Code or entering the numeric code.".localized, preferredStyle: .alert)
            dialog.addAction(UIKit.UIAlertAction(title: "OK".localized, style: .default, handler: { (UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            }))
                
            self.present(dialog, animated: true, completion: nil)
        }))
        
        
        actionSheet.addAction(UIAlertAction(title: "Create Class".localized, style: .default, handler: { (UIAlertAction) in
            self.performSegue(withIdentifier: "tab2createclass", sender: self)
        }))
        
        /*
        actionSheet.addAction(UIAlertAction(title: "Update".localized, style: .default, handler:
        {
            UIAlertAction in
            let screen3 = self.tabBarController as! Screen3
            screen3.updateCourses()
        }))*/
        
        actionSheet.addAction(UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil))
        
        actionSheet.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        
        present(actionSheet, animated: true)
         */
        
        self.performSegue(withIdentifier: "tab2createclass", sender: self)
    }
    
    @IBAction func refresh(_ sender: Any)
    {
        let screen3 = self.tabBarController as! Screen3
        screen3.updateCourses()
    }
     // MARK: - Navigation
    
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?)
     {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
        if (segue.identifier == "tab2gotoclass")
        {
            let destination = segue.destination as! Screen4
            destination.currentCourse = Course.courses![rowSelected]
        }
     }
    
    
}
