//
//  ProfileView.swift
//  Qmera
//
//  Created by Yayan Dwi on 12/10/21.
//

import UIKit

class ProfileView: UIImageView {
    
    var user: User? {
        didSet {
            guard let user = self.user else {
                return
            }
            getImage(name: user.thumb, isCircle: true) { result, isDownloaded, image in
                if !result {
                    self.tintColor = .mainColor
                    self.backgroundColor = .white
                } else {
                    self.image = image
                }
            }
        }
    }
    
    override init(image: UIImage?) {
        super.init(image: image)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        
    }
    
    override func layoutSubviews() {
        contentMode = .scaleAspectFill
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.cgColor
        circle()
    }
    
}
