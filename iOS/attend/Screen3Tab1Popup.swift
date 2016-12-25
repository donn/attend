import UIKit

class Screen3Tab1Popup: UIViewController, UITextFieldDelegate
{
    @IBOutlet var Code: UITextField!
    
    var linkBack: Screen3Tab1!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onClick_Attend(_ sender: Any)
    {
        self.view.endEditing(true)
        
        self.dismiss(animated: true) { 
            if let code = self.Code.text
            {
                self.linkBack.miniAttend(code)
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
