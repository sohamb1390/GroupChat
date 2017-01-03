//
//  RoundBorderedButton.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 30/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class RoundBorderedButton: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = frame.size.height / 2
        layer.borderColor = ColorConstants.baseColor.cgColor
        layer.borderWidth = 1.0
        layer.masksToBounds = true
    }

}
