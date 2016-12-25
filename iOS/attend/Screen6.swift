import UIKit
import Alamofire

class Screen6: UITableViewController
{
    
    func logout()
    {
        let defaults = UserDefaults.standard
        let token = ""
        defaults.set(token, forKey: "token")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let viewcontroller = storyboard.instantiateInitialViewController()
        
        let window = (UIApplication.shared.delegate!.window!)!
        
        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromBottom, animations: {
            window.rootViewController = viewcontroller
            }, completion: nil)
    }
    
    var rowSelected: Int = 0
    var currentCourse: Course?
    var events = [Event]()
    
    @IBOutlet var AddButton: UIBarButtonItem!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        update()
        
    }
    
    internal func update()
    {
        if let courseID = currentCourse?.ID,
            let parameters = GlobalUtils.getPostParameters(forRequest: ["CourseID": courseID])
        {
            Alamofire.request(GlobalUtils.getURL(forAPI: "get.php?type=event"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .responseJSON
                {
                    response in
                    
                    self.events.removeAll()
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
                            else if (json["status"]["code"] == 404)
                            {
                                GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                
                                GlobalUtils.createAlertDialog(message: "Course no longer exists.".localized, delegate: self);
                                
                                return
                            }
                            else if (json["status"]["code"] == 401)
                            {
                                
                                GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                
                                GlobalUtils.createAlertDialog(title: "Error".localized, message: "You are not authorized to perform this action.".localized, delegate: self);
                                
                            }
                            else if (json["status"]["code"] == 999)
                            {
                                GlobalUtils.createAlertDialog(message: "Your session has expired. You will be logged out." .localized, delegate: self, completion:
                                    {
                                        self.logout()
                                } )
                                
                                return
                            }
                            
                            if let eventArray = json["response"].array
                            {
                                var eventsDeserialized = [Event]()
                                
                                for event in eventArray
                                {
                                    let ID = Int(event["ID"].stringValue)!
                                    let title = event["Title"].stringValue
                                    let courseID = Int(event["CourseID"].stringValue)!
                                    let special = event["Special"].boolValue
                                    let typicalStartTime = GlobalUtils.nullableString(event["TypicalStartTime"].stringValue)
                                    
                                    let event = Event(withID: ID, courseID: courseID, title: title, special: special, typicalStartTime: typicalStartTime)
                                    
                                    eventsDeserialized.append(event)
                                }
                                
                                self.events = eventsDeserialized
                            }
                            
                        }
                    case .failure(let error):
                        GlobalUtils.log("Alamofire Error: \(error)")
                        GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                    }
                    
                    self.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
            }
           
        }

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
        return self.events.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        cell.textLabel?.text = self.events[indexPath.row].title
        
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
        self.performSegue(withIdentifier: "screen6instantiateevent", sender: self)
    }
    
    
    @IBAction func onClick_BarPlus(_ sender: Any)
    {
        self.performSegue(withIdentifier: "screen6createevent", sender: self)
    }
    
    @IBAction func refresh(_ sender: Any)
    {
        self.update()
    }
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "screen6instantiateevent")
        {
            let destination = segue.destination as! Screen7
            destination.currentEvent = self.events[rowSelected]
        }
        else if (segue.identifier == "screen6create")
        {
            let destination = segue.destination as! Screen6a
            destination.currentCourse = self.currentCourse
        }
    }
    
    
}
