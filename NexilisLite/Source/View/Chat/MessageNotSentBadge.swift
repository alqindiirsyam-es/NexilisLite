//
//  MessageNotSentBadge.swift
//  NexilisLite
//
//  The red mark beside a message that never left.
//
//  The sheet it opens is not here: the app already has BottomChoiceSheet for "here are your
//  choices", and a second sheet built beside it would be a second look to keep in step.
//

import UIKit

// MARK: - The badge beside a message that never left

/// The red mark next to a failed message. Round, white exclamation, and it takes a tap.
public final class MessageNotSentBadge: UIButton {

    public static let side: CGFloat = 22

    public override init(frame: CGRect) {
        super.init(frame: frame)
        // Drawn from the size it is constrained to rather than measured afterwards: a corner
        // radius taken from bounds in a parent's layout pass is read before this view has one.
        layer.cornerRadius = MessageNotSentBadge.side / 2
        layer.masksToBounds = true
        backgroundColor = .systemRed
        tintColor = .white
        setImage(UIImage(systemName: "exclamationmark",
                         withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold))?
                    .withRenderingMode(.alwaysTemplate), for: .normal)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: MessageNotSentBadge.side),
            heightAnchor.constraint(equalToConstant: MessageNotSentBadge.side)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
