//
//  File.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit

class ProfileViewController: UIViewController {
    private let viewModel: ProfileViewModel
    private let photoImageView = UIImageView()
    private let nameLabel = UILabel()
    private let upgradePromptLabel = UILabel()
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Profile"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        populateData()
    }
    
    private func setupViews() {
        // Setup profile photo
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.layer.cornerRadius = 50
        photoImageView.clipsToBounds = true
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(photoImageView)
        
        // Setup name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        // Setup upgrade prompt label
        upgradePromptLabel.font = UIFont.systemFont(ofSize: 16)
        upgradePromptLabel.numberOfLines = 0
        upgradePromptLabel.textColor = .systemBlue
        upgradePromptLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(upgradePromptLabel)
        
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            photoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            photoImageView.widthAnchor.constraint(equalToConstant: 100),
            photoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: 20),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            upgradePromptLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            upgradePromptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            upgradePromptLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func populateData() {
        photoImageView.image = viewModel.user.photo
        nameLabel.text = viewModel.user.name
        if let prompt = viewModel.upgradePrompt() {
            upgradePromptLabel.text = prompt
        } else {
            upgradePromptLabel.text = "Your English level is up to date."
        }
    }
}
