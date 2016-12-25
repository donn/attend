import UIKit
import Alamofire

class Screen2: UIViewController, UITextFieldDelegate {

    @IBOutlet var email: UITextField!
    @IBOutlet weak var UIActivitySpinner: UIActivityIndicatorView!
    
    @IBOutlet var password: UITextField!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        email.delegate = self
        password.delegate = self
        // Do any additional setup after loading the view.
        
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
        case self.email:
            self.password.becomeFirstResponder()
        case self.password:
            self.view.endEditing(true)
        default:
            GlobalUtils.log("\\_(ツ)_/")
            return false
        }
        
        return true
    }
    
    @IBAction func onClick_Login(_ sender: Any)
    {
        self.view.endEditing(true)
        
        if (GlobalUtils.emptyString(self.email.text) || GlobalUtils.emptyString(self.password.text))
        {
            GlobalUtils.createAlertDialog(message: "All fields are required.".localized, delegate: self)
            return;
        }
        
        self.UIActivitySpinner.isHidden = false
        self.UIActivitySpinner.startAnimating()
        
        let parameters = ["email":self.email.text!, "password":self.password.text!];
        
        Alamofire.request(GlobalUtils.getURL(forAPI: "login.php"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
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
                        if (json["status"]["code"] != 200)
                        {
                            GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                            
                            GlobalUtils.createAlertDialog(title: "Error".localized, message: "Email and password combination does not match any of our records.".localized, delegate: self);
                            
                            return;
                        }
                        let defaults = UserDefaults.standard
                        let token = json["jwt"].stringValue
                        
                        defaults.set(token, forKey: "token")
                        
                        let storyboard = UIStoryboard(name: "Tabs", bundle: nil)
                        
                        let viewcontroller = storyboard.instantiateInitialViewController()
                        
                        let window = UIApplication.shared.delegate!.window!!
                        
                        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromBottom, animations: {
                            window.rootViewController = viewcontroller
                            }, completion: nil)
                    }
                case .failure(let error):
                    GlobalUtils.log("Alamofire Error: \(error)")
                    GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                }
        }
        
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        //self.navigationController?.popViewController(animated: false);
    }
 

}
