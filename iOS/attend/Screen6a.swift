import UIKit
import Alamofire

class Screen6a: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource
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
    
    let hours = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
    
    let minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
    
    var currentHours = 0
    var currentMinutes = 0
    var currentCourse: Course?
    
    
    @IBOutlet var EventTitle: UITextField!
    @IBOutlet var Special: UISwitch!
    @IBOutlet var TypicalTimeEnabled: UISwitch!
    @IBOutlet var UIActivitySpinner: UIActivityIndicatorView!
    @IBOutlet var TimePicker: UIPickerView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.UIActivitySpinner.isHidden = true
        
        self.TimePicker.delegate = self
        self.TimePicker.dataSource = self
        
        self.EventTitle.delegate = self
        
        if (self.currentCourse!.privilege <= 2)
        {
            self.Special.isOn = false
        }
        else
        {
            self.Special.isOn = true
            self.Special.isUserInteractionEnabled = false
        }
    
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        self.view.endEditing(true)
        
        return true
    }
    
    @IBAction func onClick_Create(_ sender: Any)
    {
        if (GlobalUtils.emptyString(self.EventTitle.text))
        {
            GlobalUtils.createAlertDialog(message: "All fields are required.".localized, delegate: self);
            return
        }
        
        
        if let title = self.EventTitle.text
        {
            var params: [String: Any] = ["CourseID": self.currentCourse!.ID, "Title": title, "Special": self.Special.isOn]
            
            if (self.TypicalTimeEnabled.isOn)
            {
                let gregorian = Calendar(identifier: Calendar.Identifier.gregorian)
                let now = NSDate()
                var components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now as Date)
                
                
                components.hour = self.currentHours
                components.minute = self.currentMinutes
                components.second = 0
                
                if let date = gregorian.date(from: components)
                {
                    let dateFormat = DateFormatter()
                    dateFormat.dateFormat = "HH:mm:ss"
                    dateFormat.timeZone = TimeZone(identifier: "UTC")
                    params["TypicalStartTime"] = dateFormat.string(from: date)
                }
            }
            
            if let parameters = GlobalUtils.getPostParameters(forRequest: params)
            {
                
                self.UIActivitySpinner.isHidden = false
                self.UIActivitySpinner.startAnimating()
                
                
                Alamofire.request(GlobalUtils.getURL(forAPI: "create.php?type=event"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
                    .responseJSON
                    {
                        response in
                        
                        self.UIActivitySpinner.isHidden = true
                        self.UIActivitySpinner.stopAnimating()
                        
                        switch response.result
                        {
                        case .success:
                            if let value = response.result.value
                            {
                                let json = JSON(value)
                                
                                if (json["status"]["code"] == 999)
                                {
                                    GlobalUtils.createAlertDialog(title: "Error".localized, message: "Your session has expired. You will be logged out." .localized, delegate: self, completion:
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
                                else if (json["status"]["code"] != 200)
                                {
                                    GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                    
                                    GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                                    
                                    return;
                                }
                                
                                GlobalUtils.createAlertDialog(message: "Successfully created event.".localized, delegate: self, completion: {
                                    let _ = self.navigationController?.popViewController(animated: true)
                                });
                                
                            }
                        case .failure(let error):
                            GlobalUtils.log("Alamofire Error: \(error)")
                            GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                        }
                }
            }
        }
        
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (component == 0)
        {
            return 24
        }
        else
        {
            return 12
        }
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (component == 0)
        {
            return "\(hours[row])"
        }
        else
        {
            return "\(minutes[row])"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (component == 0)
        {
            currentHours = hours[row]
        }
        else
        {
            currentMinutes = minutes[row]
        }
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    
}
