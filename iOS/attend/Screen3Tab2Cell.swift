import UIKit

class Screen3Tab2Cell: UITableViewCell
{
    @IBOutlet var CourseFullID: UILabel!
    @IBOutlet var CourseName: UILabel!
    @IBOutlet var ProfessorName: UILabel!
    @IBOutlet var Attendance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
