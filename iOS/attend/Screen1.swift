import UIKit
import Alamofire

class Screen1: UIViewController, UITextFieldDelegate
{
    
    @IBOutlet var firstName: UITextField!
    @IBOutlet var lastName: UITextField!
    @IBOutlet var email: UITextField!
    @IBOutlet var password: UITextField!
    @IBOutlet var confirmPassword: UITextField!
    @IBOutlet weak var UIActivitySpinner: UIActivityIndicatorView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        let token = defaults.string(forKey: "token")
        if (!GlobalUtils.emptyString(token))
        {
            let storyboard = UIStoryboard(name: "Tabs", bundle: nil)
            
            let viewcontroller = storyboard.instantiateInitialViewController()
            
            let window = UIApplication.shared.delegate!.window!!
            
            window.rootViewController = viewcontroller
        }
        
        firstName.delegate = self
        lastName.delegate = self
        email.delegate = self
        password.delegate = self
        confirmPassword.delegate = self
        self.UIActivitySpinner.isHidden = true
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
        case self.firstName:
            self.lastName.becomeFirstResponder()
        case self.lastName:
            self.email.becomeFirstResponder()
        case self.email:
            self.password.becomeFirstResponder()
        case self.password:
            self.confirmPassword.becomeFirstResponder()
        case self.confirmPassword:
            self.view.endEditing(true)
        default:
            GlobalUtils.log("\\_(ツ)_/")
            return false
        }
        
        return true
    }

    @IBAction func touchUpInside_Register(_ sender: Any)
    {
        self.view.endEditing(true)
        
        if (GlobalUtils.emptyString(self.firstName.text) || GlobalUtils.emptyString( self.lastName.text) || GlobalUtils.emptyString( self.email.text) || GlobalUtils.emptyString(self.password.text) || GlobalUtils.emptyString(self.confirmPassword.text))
        {
           GlobalUtils.createAlertDialog(message: "All fields are required.".localized, delegate: self)
            return;
        }
        
        if (self.password.text != self.confirmPassword.text)
        {
            GlobalUtils.createAlertDialog(message: "Passwords do not match.".localized, delegate: self)
            return;
        }
        
        self.UIActivitySpinner.isHidden = false
        self.UIActivitySpinner.startAnimating()
        
        let parameters = ["fname": self.firstName.text!, "lname": self.lastName.text!, "email":self.email.text!, "password":self.password.text!];
        
        Alamofire.request(GlobalUtils.getURL(forAPI: "register.php?action=new"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON
            {
                response in
                self.UIActivitySpinner.isHidden = true
                self.UIActivitySpinner.stopAnimating()
                self.dismiss(animated: true, completion: nil)
                switch response.result
                {
                case .success:
                    if let value = response.result.value
                    {
                        let json = JSON(value)
                        if (json["status"]["code"] != 200)
                        {
                            GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                            GlobalUtils.createAlertDialog(title: "Registration Error".localized, message: "Your email may be invalid.".localized, delegate: self);
                            return;
                        }
                        GlobalUtils.createAlertDialog(title: "Registration Successful".localized, message: "You should be recieving an email to confirm your account shortly.".localized, delegate: self)
                    }
                case .failure(let error):
                    GlobalUtils.log("Alamofire Error: \(error)")
                    GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                }
            }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        self.view.endEditing(true)
        //self.navigationController?.popViewController(animated: false);
    }
}

