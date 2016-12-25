import UIKit
import Alamofire

class ScreenX: UIViewController {
    
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

    @IBOutlet var Code: UILabel!
    @IBOutlet var Active: UISwitch!
    @IBOutlet var Late: UISwitch!
    @IBOutlet var UIActivitySpinner: UIActivityIndicatorView!
    var regenerateQR = false
    
    var currentSession: EventInstance?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let session = currentSession!
        
        self.Code.text = session.qrString
        self.Active.isOn = session.qrCodeActive
        self.Late.isOn = session.late
        self.UIActivitySpinner.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onClick_Regenerate(_ sender: Any)
    {
        regenerateQR = true
        onChangeValue(sender)
    }
    
    @IBAction func onChangeValue(_ sender: Any)
    {
        
        if let session = self.currentSession
        {
            let params: [String: Any] = ["ID": session.ID, "RegenerateQR": regenerateQR, "Late": self.Late.isOn, "QRCodeActive": self.Active.isOn]
            
            if let parameters = GlobalUtils.getPostParameters(forRequest: params)
            {
                
                self.UIActivitySpinner.isHidden = false
                self.UIActivitySpinner.startAnimating()
                
                
                Alamofire.request(GlobalUtils.getURL(forAPI: "alter.php?type=eventinstance"), method: .post, parameters: parameters, encoding: JSONEncoding.default)
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
                                    
                                    GlobalUtils.createAlertDialog(title: "Error".localized, message: "Instance no longer exists.".localized, delegate: self);
                                    
                                    return;
                                }
                                else if (json["status"]["code"] != 200)
                                {
                                    GlobalUtils.log("Server Error: \(json["status"]["msg"])")
                                    
                                    GlobalUtils.createAlertDialog(title: "Server Error".localized, message: "Please contact the system administrator.".localized, delegate: self);
                                    
                                    return;
                                }
                                
                                self.Code.text = json["response"]["QRString"].stringValue
                                
                            }
                        case .failure(let error):
                            GlobalUtils.log("Alamofire Error: \(error)")
                            GlobalUtils.createAlertDialog(message: "Check your internet connection.".localized, delegate: self);
                        }
                }
            }
        }

        regenerateQR = false
    }
}
