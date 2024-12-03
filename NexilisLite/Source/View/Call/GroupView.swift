//
//  GroupView.swift
//  Qmera
//
//  Created by Yayan Dwi on 11/10/21.
//

import UIKit

class GroupView: UIView {
    
    var circleSize: CGFloat = 150
    
    var maxUser: Int = 5
    
    var spacing: CGFloat = 30
    
    private let label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 34)
        return label
    }()
    
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
    
    private var count: Int = 0
    
    func addArrangedSubview(view: UIView) {
        count += 1
        if count > maxUser, let last = subviews.last {
            if count == maxUser + 1 {
                let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
                effectView.frame = UIScreen.main.bounds
                last.addSubview(effectView)
                last.addSubview(label)
                label.anchor(left: last.leftAnchor, right: last.rightAnchor, centerY: last.centerYAnchor)
                UIView.animate(withDuration: 0.3, animations: {
                    self.layoutIfNeeded()
                })
            }
            addSubview(view)
            view.anchor(top: last.topAnchor, left: last.leftAnchor, bottom: last.bottomAnchor, right: last.rightAnchor)
            view.isHidden = true
            
            label.text = "+\(count - maxUser)"
            return
        }
        addSubview(view)
        if subviews.count > 1 {
            NSLayoutConstraint.deactivate(constraints)
        }
        var total = circleSize
        for i in 0..<subviews.count {
            var left: NSLayoutXAxisAnchor? = nil
            if i > 0 {
                let before = subviews[i - 1]
                left = before.leftAnchor
                total += spacing
            }
            subviews[i].anchor(left: left, paddingLeft: spacing, width: circleSize, height: circleSize)
        }
        if subviews.count > 1 {
            anchor(centerX: superview!.centerXAnchor, centerY: superview!.centerYAnchor, width: total, height: circleSize)
            UIView.animate(withDuration: 0.3, animations: {
                self.layoutIfNeeded()
            })
        }
    }
    
    func removeArrangeSubview(view: UIView) {
        count -= 1
        NSLayoutConstraint.deactivate(constraints)
        view.removeFromSuperview()
        var total = circleSize
        for i in 0..<subviews.count {
            let subview = subviews[i]
            subview.isHidden = false
            NSLayoutConstraint.deactivate(subview.constraints)
            subview.subviews.forEach { $0.removeFromSuperview() }
            if i == 0 {
                subview.anchor(width: circleSize, height: circleSize)
            } else {
                if i + 1 > maxUser {
                    let last = subviews[i - 1]
                    if i == maxUser {
                        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))
                        effectView.frame = UIScreen.main.bounds
                        last.addSubview(effectView)
                        last.addSubview(label)
                        label.anchor(left: last.leftAnchor, right: last.rightAnchor, centerY: last.centerYAnchor)
                        label.text = "+\(count - maxUser)"
                    }
                    subview.anchor(top: last.topAnchor, left: last.leftAnchor, bottom: last.bottomAnchor, right: last.rightAnchor)
                    subview.isHidden = true
                } else {
                    let before = subviews[i - 1]
                    total += spacing
                    subview.anchor(left: before.leftAnchor, paddingLeft: spacing, width: circleSize, height: circleSize)
                }
            }
        }
        anchor(centerX: superview!.centerXAnchor, centerY: superview!.centerYAnchor, width: total, height: circleSize)
        UIView.animate(withDuration: 0.3, animations: {
            self.layoutIfNeeded()
        })
    }
    
}
