import UIKit

class GlobalUtils
{
    static let baseurl = "YOUR_URL_HERE/php/"
    
    static func getURL(forAPI api: String) -> String
    {
        return baseurl + api
    }
    
    static func getPostParameters(forRequest request:[String: Any] = [:]) -> [String: Any]?
    {
        let defaults = UserDefaults.standard
        if let token  = defaults.string(forKey: "token")
        {
            return ["jwt":token, "request":request]
        }
        return nil;
    }
    
    static func emptyString(_ string: String?) -> Bool
    {
        return (string ?? "").isEmpty
    }
    
    static func nullableString(_ string: String?) -> String?
    {
        if emptyString(string)
        {
            return nil
        }
        return string!
    }
    
    static func nullableIntFromString(_ string: String?) -> Int?
    {
        if let no1 = string,
            let no2 = Int(no1)
        {
            return no2
        }
        return nil
    }
    
    static func createAlertDialog(title: String = "", message: String, delegate: UIViewController, animated: Bool = true, completion: (()->(Void))? = nil)
    {
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler:
        {
            (UIAlertAction) in
            dialog.dismiss(animated: true, completion: nil)
            if let onOK = completion
            {
                onOK()
            }
        }))
        
        delegate.present(dialog, animated: animated, completion: nil)
    }
    
    static func redactSeconds(time: String) -> String
    {
        let components = time.components(separatedBy: ":")        
        return "\(components[0]):\(components[1])"
    }
    
    static func log(_ string: String)
    {
        print("[miniAttend Log] \(string)")
    }
    
    
    //print(response.request!.stringValue)
    
    //print(response.result.value!)
    
    
}

extension String
{
    var localized: String
    {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}

extension URLRequest
{
    var stringValue: String
    {
        return NSString(data: self.httpBody!, encoding: String.Encoding.utf8.rawValue) as! String
    }
}

extension UIColor
{
    convenience init?(hex: String)
    {
        let conversion = Int(hex, radix: 16)
        if var colorInt = conversion
        {
            let intB = colorInt & 255
            let floatB = Float(intB) / Float(255)
            colorInt = colorInt >> 8
            let intG = colorInt & 255
            let floatG = Float(intG) / Float(255)
            colorInt = colorInt >> 8
            let intR = colorInt & 255
            let floatR = Float(intR) / Float(255)
            self.init(colorLiteralRed: floatR, green: floatG, blue: floatB, alpha: 1.0);
        }
        return nil
    }
}
