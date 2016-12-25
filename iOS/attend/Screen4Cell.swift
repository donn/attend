import UIKit

class Screen4Cell: UITableViewCell
{
    @IBOutlet var Title: UILabel!
    @IBOutlet var Name: UILabel!
    @IBOutlet var Email: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
