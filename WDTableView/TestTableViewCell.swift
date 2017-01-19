//
//  TestTableViewCell.swift
//  WDTableView
//
//  Created by 吴頔 on 17/1/19.
//  Copyright © 2017年 WD. All rights reserved.
//

import UIKit

class TestTableViewCell: UITableViewCell {

    var _contrast: Contrast = Contrast()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension TestTableViewCell {
    override func bind(model: AnyObject) {
        _contrast = model as! Contrast
        textLabel?.text = _contrast.chinese + "  (" + _contrast.english + ")"
    }
}
