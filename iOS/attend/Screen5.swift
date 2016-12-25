import UIKit
import Alamofire

class Screen5: UIViewController, UITextFieldDelegate
{
    
    @IBOutlet var CourseName: UITextField!
    @IBOutlet var CourseCode: UITextField!
    @IBOutlet var Section: UITextField!
    @IBOutlet var MissableClasses: UITextField!
    
    @IBOutlet var UIActivitySpinner: UIActivityIndicatorView!
    
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
        self.CourseName.delegate = self
        self.CourseCode.delegate = self
        self.Section.delegate = self
        self.MissableClasses.delegate = self
        self.UIActivitySpinner.isHidden = true
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        switch (textField)
        {
        case self.CourseName:
            self.CourseCode.becomeFirstResponder()
        case self.CourseCode:
            self.Section.becomeFirstResponder()
        case self.Section:
            self.MissableClasses.becomeFirstResponder()
        case self.MissableClasses:
            self.view.endEditing(true)
        default:
            GlobalUtils.log("\\_(ツ)_/")
            return false
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        let currentCharacterCount = textField.text?.characters.count ?? 0
        if (range.length + range.location > currentCharacterCount){
            return false
        }
        let newLength = currentCharacterCount + string.characters.count - range.length
        
        
        switch (textField)
        {
        case self.CourseName:
            return newLength <= 64
        case self.CourseCode:
            return newLength <= 8
        case self.Section:
            return newLength <= 2
        case self.MissableClasses:
            return true
        default:
            return false
        }
    }

    
    @IBAction func onClick_Submit(_ sender: Any)
    {
        self.view.endEditing(true)
        
        if (GlobalUtils.emptyString(self.CourseName.text))
        {
            GlobalUtils.createAlertDialog(message: "A course name is required.".localized, delegate: self)
            return;
        }
        
        var params: Parameters = ["Title": self.CourseName.text!]
        
        if let courseCode = GlobalUtils.nullableString(self.CourseCode.text)
        {
            params["Code"] = courseCode;
        }
        
        if let section = GlobalUtils.nullableString(self.Section.text)
        {
            params["Section"] = section;
        }
        
        if let missableClasses = GlobalUtils.nullableIntFromString(self.MissableClasses.text)
        {
            params["MissableEvents"] = missableClasses;
        }
        
        if let parameters = GlobalUtils.getPostParameters(forRequest: params)
        {
            
            self.UIActivitySpinner.isHidden = false
            self.UIActivitySpinner.startAnimating()
            
            
            Alamofire.request(GlobalUtils.getURL(forAPI: "create.php?type=course"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
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
                            else if (json["status"]["code"] == 500)
                            {                                
                                GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                
                                GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                                
                                return;
                            }
                            
                            GlobalUtils.createAlertDialog(title: "Creation Successful".localized, message: "The course has been successfully created.".localized, delegate: self, completion: {
                                let _ = self.navigationController?.popToRootViewController(animated: true)
                            });
                            
                        }
                    case .failure(let error):
                        GlobalUtils.log("Alamofire Error: \(error)")
                        GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
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
