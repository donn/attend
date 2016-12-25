import UIKit
import Alamofire

class Screen4Popup: UIViewController, UITextFieldDelegate
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
    
    var linkBack: Screen4!

    @IBOutlet var Email: UITextField!
    
    @IBOutlet var UIActivitySpinner: UIActivityIndicatorView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.UIActivitySpinner.isHidden = true
        self.Email.delegate = self
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClick_Excuse(_ sender: Any)
    {
        self.view.endEditing(true)
        
        if let course = linkBack.currentCourse,
            let email = self.Email.text
        {
            let params: Parameters = ["CourseID": course.ID, "Email": email]
            
            if let parameters = GlobalUtils.getPostParameters(forRequest: params)
            {
                
                self.UIActivitySpinner.isHidden = false
                self.UIActivitySpinner.startAnimating()
                
                
                Alamofire.request(GlobalUtils.getURL(forAPI: "excuse.php"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
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
                                else if (json["status"]["code"] == 404 || json["status"]["code"] == 403)
                                {
                                    GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                    
                                    GlobalUtils.createAlertDialog(title: "Error".localized, message: "User does not exist or is not enrolled.".localized, delegate: self);
                                    
                                    return;
                                }
                                else if (json["status"]["code"] != 200)
                                {
                                    GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                    
                                    GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                                    
                                    return;
                                }
                                
                                GlobalUtils.createAlertDialog(message: "Excused.".localized, delegate: self, completion: {
                                     self.dismiss(animated: true)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
