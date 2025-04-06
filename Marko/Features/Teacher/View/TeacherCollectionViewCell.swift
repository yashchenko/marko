//
//  TeacherCollectionViewCell.swift
//  Marko
//
//  Created by Ivan on 15.03.2025.
//

import UIKit

class TeacherCollectionViewCell: UICollectionViewCell {

    // Define a static reuse identifier for type safety
    static let reuseIdentifier = "TeacherCell"

    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let subjectLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupViews() {
        // Cell Appearance
        contentView.backgroundColor = .secondarySystemBackground // Use semantic color
        contentView.layer.cornerRadius = 10 // Slightly more rounded corners
        contentView.layer.masksToBounds = true // Clip content to rounded corners

        // Cell Shadow (applied to the cell's layer, not contentView)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1.5)
        layer.shadowRadius = 3.0
        layer.shadowOpacity = 0.15
        layer.masksToBounds = false // Allow shadow to be visible outside bounds
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath


        // Image View
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30 // Keep image circular
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray4 // Placeholder color
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        // Name Label
        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline) // Dynamic Type support
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .label // Semantic color
        nameLabel.numberOfLines = 1 // Keep name to one line usually
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        // Subject Label
        subjectLabel.font = UIFont.preferredFont(forTextStyle: .subheadline) // Dynamic Type support
        subjectLabel.adjustsFontForContentSizeCategory = true
        subjectLabel.textColor = .secondaryLabel // Semantic color
        subjectLabel.numberOfLines = 1
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subjectLabel)

        // --- Layout Constraints ---
        let padding: CGFloat = 15
        NSLayoutConstraint.activate([
            // Image View
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),

            // Name Label
            nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: padding),
            // Adjust vertical positioning if needed, e.g., slightly higher
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding + 5), // Example offset
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Subject Label
            subjectLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            subjectLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4), // Spacing below name
            subjectLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
            // Ensure subject label doesn't go below image if text is short
            // subjectLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -padding)
        ])
    }

    func configure(with teacher: Teacher) {
        imageView.image = teacher.profileImage
        nameLabel.text = teacher.name
        subjectLabel.text = teacher.subject
        // print("Configured cell for \(teacher.name)") // Optional debug log
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset content for reuse
        imageView.image = nil
        nameLabel.text = nil
        subjectLabel.text = nil
    }

    // Update shadow path if cell bounds change (e.g., orientation)
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
    }
}
