import UIKit
import Alamofire

class Screen7: UIViewController
{
    
    @IBOutlet var TitleLabel: UILabel!
    
    @IBOutlet var DatePicker: UIDatePicker!
    
    @IBOutlet var Switch: UISwitch!
    
    @IBOutlet var UIActivitySpinner: UIActivityIndicatorView!
    
    var currentEvent: Event?
    
    
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
        
        self.title = "\("Instantiate".localized) \(currentEvent!.title)"
        self.UIActivitySpinner.isHidden = true
        if let date = currentEvent!.typicalStartTime
        {
            DatePicker.date = date
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func onClick_Submit(_ sender: Any)
    {
        if let event = currentEvent
        {
            var params: [String: Any] = ["EventID": event.ID]
            
            let date = DatePicker.date as NSDate
            
            params["StartTime"] = date.timeIntervalSince1970
            
            params["QRCodeActive"] = self.Switch.isOn
            
            if let parameters = GlobalUtils.getPostParameters(forRequest: params)
            {
                
                self.UIActivitySpinner.isHidden = false
                self.UIActivitySpinner.startAnimating()
                
                
                Alamofire.request(GlobalUtils.getURL(forAPI: "create.php?type=eventinstance"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
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
                                
                                GlobalUtils.createAlertDialog(title: "Creation Successful".localized, message: "Event instance created!".localized, delegate: self, completion: {
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
