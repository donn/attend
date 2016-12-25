import UIKit

class About: UIViewController {
    
    @IBOutlet var OSAcknowledgements: UITextView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let concurrentQueue = DispatchQueue(label: "OSAcknowledgementsLoading", attributes: .concurrent)

        concurrentQueue.sync(execute: {
            
            let path = Bundle.main.path(forResource: "OSAcknowledgements", ofType: "txt")
            do
            {
                let text = try String(contentsOfFile: path!)
                OSAcknowledgements.text = text
            } catch {
                GlobalUtils.log("\(error)")
            }
        })
        

        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onClick_Done(_ sender: Any)
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
