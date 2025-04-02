//
//  ProfileViewController.swift
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
    private let bookedSessionsStackView = UIStackView() // Correct name

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Profile"

        viewModel.onSessionsLoaded = { [weak self] in
            DispatchQueue.main.async {
                print("ProfileVC: onSessionsLoaded callback received.")
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
        view.backgroundColor = .systemBackground
        setupViews()
        populateStaticData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ProfileVC: viewWillAppear - Requesting session refresh.")
        viewModel.loadBookedSessions()
    }

    private func setupViews() {
        // Setup profile photo
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.layer.cornerRadius = 50
        photoImageView.clipsToBounds = true
        photoImageView.backgroundColor = .systemGray5
        photoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(photoImageView)

        // Setup name label
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        // Setup level label
        levelLabel.font = UIFont.systemFont(ofSize: 18)
        levelLabel.textAlignment = .center
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(levelLabel)

        // Setup next session label
        nextSessionLabel.font = UIFont.systemFont(ofSize: 16)
        nextSessionLabel.textColor = .secondaryLabel
        nextSessionLabel.numberOfLines = 0
        nextSessionLabel.textAlignment = .center
        nextSessionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nextSessionLabel)

        // Setup upgrade prompt label
        upgradePromptLabel.font = UIFont.systemFont(ofSize: 16)
        upgradePromptLabel.numberOfLines = 0
        upgradePromptLabel.textColor = .systemBlue
        upgradePromptLabel.textAlignment = .center
        upgradePromptLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(upgradePromptLabel)

        // Setup booked sessions title label
        let sessionsLabel = UILabel()
        sessionsLabel.text = "Your Upcoming Sessions:"
        sessionsLabel.font = UIFont.boldSystemFont(ofSize: 18)
        sessionsLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sessionsLabel)

        // Setup stack view for booked sessions
        bookedSessionsStackView.axis = .vertical
        bookedSessionsStackView.spacing = 12
        bookedSessionsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bookedSessionsStackView)

        // --- Layout Constraints ---
        let standardPadding: CGFloat = 20
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: standardPadding),
            photoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            photoImageView.widthAnchor.constraint(equalToConstant: 100),
            photoImageView.heightAnchor.constraint(equalToConstant: 100),

            nameLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: standardPadding),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardPadding),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -standardPadding),

            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            levelLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardPadding),
            levelLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -standardPadding),

            nextSessionLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: standardPadding),
            nextSessionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardPadding),
            nextSessionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -standardPadding),

            upgradePromptLabel.topAnchor.constraint(equalTo: nextSessionLabel.bottomAnchor, constant: standardPadding),
            upgradePromptLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardPadding),
            upgradePromptLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -standardPadding),

            sessionsLabel.topAnchor.constraint(equalTo: upgradePromptLabel.bottomAnchor, constant: 30),
            sessionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardPadding),
            sessionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -standardPadding),

            bookedSessionsStackView.topAnchor.constraint(equalTo: sessionsLabel.bottomAnchor, constant: 10),
            bookedSessionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: standardPadding),
            // **FIXED TYPO HERE**
            bookedSessionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -standardPadding),
            bookedSessionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -standardPadding)
        ])
    }

    private func populateStaticData() {
        photoImageView.image = viewModel.user.photo
        nameLabel.text = viewModel.user.name
        levelLabel.text = "English Level: \(viewModel.user.englishLevel)"

        if let prompt = viewModel.upgradePrompt() {
            upgradePromptLabel.text = prompt
            upgradePromptLabel.isHidden = false
        } else {
            upgradePromptLabel.isHidden = true
        }
        nextSessionLabel.text = "Loading sessions..."
        updateBookedSessions() // Show initial empty/loading state
    }

    private func updateNextSession() {
        if let nextSessionInfo = viewModel.getNextSessionInfo() {
             // print("ProfileVC: Updating next session label: \(nextSessionInfo)") // Verbose log
             nextSessionLabel.text = nextSessionInfo
        } else {
            // print("ProfileVC: No upcoming session found.") // Verbose log
            nextSessionLabel.text = "No upcoming confirmed sessions."
        }
    }

    private func updateBookedSessions() {
         // print("ProfileVC: Updating booked sessions list view. Count: \(viewModel.bookedSessions.count)") // Verbose log
        bookedSessionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if viewModel.bookedSessions.isEmpty {
            let noSessionsLabel = UILabel()
            noSessionsLabel.text = "You haven't booked any upcoming sessions yet."
            noSessionsLabel.textColor = .secondaryLabel
            noSessionsLabel.textAlignment = .center
            noSessionsLabel.font = UIFont.systemFont(ofSize: 15)
            bookedSessionsStackView.addArrangedSubview(noSessionsLabel)
        } else {
            for booking in viewModel.bookedSessions {
                let sessionView = createSessionView(for: booking)
                bookedSessionsStackView.addArrangedSubview(sessionView)
            }
        }
    }

    private func createSessionView(for booking: Booking) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 8

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stackView)

        let dateLabel = UILabel()
        dateLabel.text = booking.timeSlot.formattedTimeSlot()
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        dateLabel.numberOfLines = 0

        let teacherLabel = UILabel()
        let teacherName = viewModel.teachers[booking.teacherId]?.name ?? "Teacher"
        teacherLabel.text = "Teacher: \(teacherName)"
        teacherLabel.font = UIFont.systemFont(ofSize: 14)
        teacherLabel.textColor = .secondaryLabel

        let priceLabel = UILabel()
        let formattedPrice = String(format: "%.0f", booking.paymentAmount)
        priceLabel.text = "Paid: ₴\(formattedPrice) UAH"
        priceLabel.font = UIFont.systemFont(ofSize: 14)
        priceLabel.textColor = .tertiaryLabel

        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(teacherLabel)
        stackView.addArrangedSubview(priceLabel)

        let innerPadding: CGFloat = 12
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: innerPadding),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: innerPadding),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -innerPadding),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -innerPadding)
        ])

        return container
    }
}
