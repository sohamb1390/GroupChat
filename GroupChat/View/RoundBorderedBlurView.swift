//
//  RoundBorderedBlurView.swift
//  GroupChat
//
//  Created by Soham Bhattacharjee on 30/12/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class RoundBorderedBlurView: UIVisualEffectView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
    }

}
