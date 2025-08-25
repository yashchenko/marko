// file: Features/Teacher/View/NewTeacherCollectionViewCell.swift

import UIKit
import Kingfisher

class NewTeacherCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "NewTeacherCell"
    
    // MARK: - UI Elements
    
    // A full-width background image for the teacher
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // A semi-transparent gradient overlay at the bottom to make text readable
    private let gradientOverlayView: UIView = {
        let view = UIView()
        // The gradient will be applied in layoutSubviews
        return view
    }()
    
    // A stack view to hold the labels at the bottom
    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .white // White text for the overlay
        return label
    }()
    
    private let subjectAndRankLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .right
        return label
    }()
    
    // Gradient layer for the overlay
    private let gradientLayer = CAGradientLayer()

    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // We update the gradient layer's frame here because the view's bounds are now final.
        gradientLayer.frame = gradientOverlayView.bounds
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Cell appearance
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        // Add all subviews
        [backgroundImageView, gradientOverlayView, infoStackView, priceLabel].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Setup the info stack
        infoStackView.addArrangedSubview(nameLabel)
        infoStackView.addArrangedSubview(subjectAndRankLabel)
        
        // Setup the gradient
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        gradientOverlayView.layer.insertSublayer(gradientLayer, at: 0)
        
        // Layout constraints
        let padding: CGFloat = 16
        NSLayoutConstraint.activate([
            // Background image fills the entire cell
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Gradient overlay covers the bottom half
            gradientOverlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientOverlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradientOverlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientOverlayView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.4),
            
            // Info stack is pinned to the bottom left
            infoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            infoStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding),
            infoStackView.trailingAnchor.constraint(lessThanOrEqualTo: priceLabel.leadingAnchor, constant: -padding),
            
            // Price is pinned to the bottom right
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            priceLabel.bottomAnchor.constraint(equalTo: infoStackView.bottomAnchor)
        ])
    }
    
    // MARK: - Configuration
    
    // AC #5 & #6: ViewModel populates the new cell view
    func configure(with teacher: Teacher) {
        nameLabel.text = teacher.name
        subjectAndRankLabel.text = "\(teacher.subject) • \(teacher.rank)"
        
        // For now, let's use a static price for the UI
        priceLabel.text = "$40/hr"
        
        let url = URL(string: teacher.profileImageURL)
        backgroundImageView.kf.setImage(
            with: url,
            placeholder: UIImage(systemName: "photo")
        )
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImageView.kf.cancelDownloadTask()
        backgroundImageView.image = nil
        nameLabel.text = nil
        subjectAndRankLabel.text = nil
        priceLabel.text = nil
    }
}
