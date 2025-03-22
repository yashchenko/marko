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
    private let levelLabel = UILabel()
    private let nextSessionLabel = UILabel()
    private let upgradePromptLabel = UILabel()
    private let bookedSessionsStackView = UIStackView()
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Profile"
        
        // Set up callback
        viewModel.onSessionsLoaded = { [weak self] in
            DispatchQueue.main.async {
                self?.updateNextSession()
                self?.updateBookedSessions()
            }
        }
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
        
        // Setup level label
        levelLabel.font = UIFont.systemFont(ofSize: 18)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(levelLabel)
        
        // Setup next session label
        nextSessionLabel.font = UIFont.systemFont(ofSize: 16)
        nextSessionLabel.textColor = .darkGray
        nextSessionLabel.numberOfLines = 0
        nextSessionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextSessionLabel)
        
        // Setup upgrade prompt label
        upgradePromptLabel.font = UIFont.systemFont(ofSize: 16)
        upgradePromptLabel.numberOfLines = 0
        upgradePromptLabel.textColor = .systemBlue
        upgradePromptLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(upgradePromptLabel)
        
        // Setup booked sessions stack
        let sessionsLabel = UILabel()
        sessionsLabel.text = "Your Booked Sessions:"
        sessionsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        sessionsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sessionsLabel)
        
        bookedSessionsStackView.axis = .vertical
        bookedSessionsStackView.spacing = 10
        bookedSessionsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bookedSessionsStackView)
        
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            photoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            photoImageView.widthAnchor.constraint(equalToConstant: 100),
            photoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: 20),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            levelLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            nextSessionLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: 20),
            nextSessionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextSessionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            upgradePromptLabel.topAnchor.constraint(equalTo: nextSessionLabel.bottomAnchor, constant: 20),
            upgradePromptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            upgradePromptLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            sessionsLabel.topAnchor.constraint(equalTo: upgradePromptLabel.bottomAnchor, constant: 30),
            sessionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            bookedSessionsStackView.topAnchor.constraint(equalTo: sessionsLabel.bottomAnchor, constant: 10),
            bookedSessionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bookedSessionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            bookedSessionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func populateData() {
        photoImageView.image = viewModel.user.photo
        nameLabel.text = viewModel.user.name
        levelLabel.text = "English Level: \(viewModel.user.englishLevel)"
        
        if let prompt = viewModel.upgradePrompt() {
            upgradePromptLabel.text = prompt
            upgradePromptLabel.isHidden = false
        } else {
            upgradePromptLabel.isHidden = true
        }
        
        // Initially set next session to loading
        nextSessionLabel.text = "Loading your next session..."
        
        // Load booked sessions
        viewModel.loadBookedSessions()
    }

    private func updateNextSession() {
        if let nextSessionInfo = viewModel.getNextSessionInfo() {
            nextSessionLabel.text = nextSessionInfo
        } else {
            nextSessionLabel.text = "No upcoming sessions. Book a lesson with one of our teachers!"
        }
    }

    private func updateBookedSessions() {
        // Clear existing views
        bookedSessionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if viewModel.bookedSessions.isEmpty {
            let noSessionsLabel = UILabel()
            noSessionsLabel.text = "You don't have any booked sessions yet."
            noSessionsLabel.textColor = .gray
            noSessionsLabel.textAlignment = .center
            bookedSessionsStackView.addArrangedSubview(noSessionsLabel)
            return
        }
        
        // Add session views
        for session in viewModel.bookedSessions {
            let sessionView = createSessionView(for: session)
            bookedSessionsStackView.addArrangedSubview(sessionView)
        }
    }

    private func createSessionView(for session: TimeSlot) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 8
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stackView)
        
        // Session date/time
        let dateLabel = UILabel()
        dateLabel.text = session.formattedTimeSlot()
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        // Teacher name
        let teacherLabel = UILabel()
        if let teacher = viewModel.teachers[session.teacherId] {
            teacherLabel.text = "Teacher: \(teacher.name)"
        } else {
            teacherLabel.text = "Teacher: Loading..."
        }
        teacherLabel.font = UIFont.systemFont(ofSize: 14)
        
        // Price
        let priceLabel = UILabel()
        priceLabel.text = "Price: ₴\(Int(session.calculatePrice())) UAH"
        priceLabel.font = UIFont.systemFont(ofSize: 14)
        priceLabel.textColor = .darkGray
        
        // Add to stack
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(teacherLabel)
        stackView.addArrangedSubview(priceLabel)
        
        // Add constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        
        return container
    }
}
