import UIKit
import Alamofire

class Screen8: UIViewController, UITextFieldDelegate
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
    
    
    class TitleDelegate: NSObject, UIPickerViewDelegate, UIPickerViewDataSource
    {
        
        let titles = ["Student", "Teaching Assistant",  "Senior Teaching Assistant", "Professor"]
        var currentRow = 0
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
       
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return titles.count
        }
        
       
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return titles[row]
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            currentRow = row
            
        }
    }
    
    class PrivilegeDelegate: NSObject, UIPickerViewDelegate, UIPickerViewDataSource
    {
        
        let privileges = ["None", "Create and Instantiate Special Events", "Full Access"]
        var currentRow = 0
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return privileges.count
        }
        
        
        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return privileges[row]
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            currentRow = row
        }
    }
    
    var currentCourse: Course?
    var titleDelegate = TitleDelegate()
    var privilegeDelegate = PrivilegeDelegate()
    
    let doiCodes = ["S", "TA", "ST", "P"]
    
    @IBOutlet var Email: UITextField!
    @IBOutlet var TitlePicker: UIPickerView!
    @IBOutlet var PrivilegePicker: UIPickerView!
    
    @IBOutlet var UIActivitySpinner: UIActivityIndicatorView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.TitlePicker.delegate = titleDelegate
        self.TitlePicker.dataSource = titleDelegate
        
        self.PrivilegePicker.delegate = privilegeDelegate
        self.PrivilegePicker.dataSource = privilegeDelegate
        
        self.UIActivitySpinner.isHidden = true
        
        self.Email.delegate = self

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
    
    @IBAction func onClick_Submit(_ sender: Any)
    {
        if (GlobalUtils.emptyString(self.Email.text))
        {
            GlobalUtils.createAlertDialog(message: "Email is required.".localized, delegate: self);
        }
        
        
        if let course = self.currentCourse,
            let email = self.Email.text
        {
            let params: Parameters = ["CourseID": course.ID, "Privilege": privilegeDelegate.currentRow, "DoICode": doiCodes[titleDelegate.currentRow], "Email": email]
            
            if let parameters = GlobalUtils.getPostParameters(forRequest: params)
            {
                
                self.UIActivitySpinner.isHidden = false
                self.UIActivitySpinner.startAnimating()
                
                
                Alamofire.request(GlobalUtils.getURL(forAPI: "alter.php?type=involvement"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
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
                                else if (json["status"]["code"] == 404)
                                {
                                    GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                    
                                    GlobalUtils.createAlertDialog(title: "Error".localized, message: "User does not exist.".localized, delegate: self);
                                    
                                    return;
                                }
                                else if (json["status"]["code"] != 200)
                                {
                                    GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                    
                                    GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                                    
                                    return;
                                }
                                
                                GlobalUtils.createAlertDialog(message: "Altering involvement successful.".localized, delegate: self, completion: {
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
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    
}
