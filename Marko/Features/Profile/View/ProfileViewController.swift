//
//  ProfileViewController.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import Firebase // Import Firebase Auth

// **FIX:** Conforms to the single, correct delegate protocol definition
class ProfileViewController: UIViewController, AuthViewControllerDelegate {

    private let viewModel: ProfileViewModel

    // --- UI Elements ---
    private let photoImageView = UIImageView()
    private let nameLabel = UILabel()
    private let levelLabel = UILabel()
    private let nextSessionLabel = UILabel()
    private let upgradePromptLabel = UILabel()
    private let bookedSessionsStackView = UIStackView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(handleSignOut), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    private let authButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign In / Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(presentAuthVC), for: .touchUpInside)
        return button
    }()

    // --- Initialization ---
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Profile"

        viewModel.onSessionsLoaded = { [weak self] in
            DispatchQueue.main.async {
                print("ProfileVC: onSessionsLoaded callback received.")
                self?.activityIndicator.stopAnimating()
                self?.updateDynamicUI()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // --- View Lifecycle ---
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupAuthAndSignOutButtons()
        setupActivityIndicator()
        updateUIForAuthState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ProfileVC: viewWillAppear")
        updateUIForAuthState()
    }

    // --- UI Setup ---
    private func setupViews() {
        // (Setup remains the same)
         photoImageView.contentMode = .scaleAspectFill
         photoImageView.layer.cornerRadius = 50
         photoImageView.clipsToBounds = true
         photoImageView.backgroundColor = .systemGray5
         photoImageView.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(photoImageView)
         nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
         nameLabel.textAlignment = .center
         nameLabel.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(nameLabel)
         levelLabel.font = UIFont.systemFont(ofSize: 18)
         levelLabel.textAlignment = .center
         levelLabel.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(levelLabel)
         nextSessionLabel.font = UIFont.systemFont(ofSize: 16)
         nextSessionLabel.textColor = .secondaryLabel
         nextSessionLabel.numberOfLines = 0
         nextSessionLabel.textAlignment = .center
         nextSessionLabel.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(nextSessionLabel)
         upgradePromptLabel.font = UIFont.systemFont(ofSize: 16)
         upgradePromptLabel.numberOfLines = 0
         upgradePromptLabel.textColor = .systemBlue
         upgradePromptLabel.textAlignment = .center
         upgradePromptLabel.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(upgradePromptLabel)
         let sessionsLabel = UILabel()
         sessionsLabel.text = "Your Upcoming Sessions:"
         sessionsLabel.font = UIFont.boldSystemFont(ofSize: 18)
         sessionsLabel.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(sessionsLabel)
         bookedSessionsStackView.axis = .vertical
         bookedSessionsStackView.spacing = 12
         bookedSessionsStackView.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(bookedSessionsStackView)

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
             bookedSessionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -standardPadding),
             // Constraints adjusted below
         ])
    }

    private func setupAuthAndSignOutButtons() {
        view.addSubview(authButton)
        view.addSubview(signOutButton)
        let standardPadding: CGFloat = 20
        NSLayoutConstraint.activate([
            authButton.topAnchor.constraint(greaterThanOrEqualTo: bookedSessionsStackView.bottomAnchor, constant: 30),
            authButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            authButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            authButton.heightAnchor.constraint(equalToConstant: 50),
            authButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -standardPadding),
            signOutButton.topAnchor.constraint(greaterThanOrEqualTo: bookedSessionsStackView.bottomAnchor, constant: 30),
            signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signOutButton.heightAnchor.constraint(equalToConstant: 44),
            signOutButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -standardPadding),
            bookedSessionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: authButton.topAnchor, constant: -standardPadding),
            bookedSessionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: signOutButton.topAnchor, constant: -standardPadding),
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // --- UI Update Logic ---
    private func updateUIForAuthState() {
        if let currentUser = Auth.auth().currentUser {
            print("User is logged in: \(currentUser.uid) - \(currentUser.email ?? "No Email")")
            signOutButton.isHidden = false
            authButton.isHidden = true
            activityIndicator.startAnimating()
            nameLabel.text = currentUser.email
            photoImageView.image = UIImage(systemName: "person.crop.circle.fill")
            levelLabel.isHidden = false
            nextSessionLabel.isHidden = false
            upgradePromptLabel.isHidden = false
            bookedSessionsStackView.isHidden = false
            (bookedSessionsStackView.superview?.subviews.first { $0 is UILabel && ($0 as! UILabel).text?.contains("Upcoming Sessions") ?? false })?.isHidden = false
            levelLabel.text = "English Level: \(viewModel.user.englishLevel)"
            if let prompt = viewModel.upgradePrompt() {
                upgradePromptLabel.text = prompt
                upgradePromptLabel.isHidden = false
            } else {
                upgradePromptLabel.isHidden = true
            }
            viewModel.loadBookedSessions()
        } else {
            print("User is logged out.")
            signOutButton.isHidden = true
            authButton.isHidden = false
            activityIndicator.stopAnimating()
            nameLabel.text = "Welcome!"
            photoImageView.image = UIImage(systemName: "person.circle")
            levelLabel.isHidden = true
            nextSessionLabel.isHidden = true
            upgradePromptLabel.isHidden = true
            bookedSessionsStackView.isHidden = true
            (bookedSessionsStackView.superview?.subviews.first { $0 is UILabel && ($0 as! UILabel).text?.contains("Upcoming Sessions") ?? false })?.isHidden = true
            bookedSessionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        }
    }

    private func updateDynamicUI() {
         guard Auth.auth().currentUser != nil else { return }
         updateNextSession()
         updateBookedSessions()
    }

    private func updateNextSession() {
        if let nextSessionInfo = viewModel.getNextSessionInfo() {
             nextSessionLabel.text = nextSessionInfo
        } else {
            nextSessionLabel.text = "No upcoming confirmed sessions."
        }
    }

    private func updateBookedSessions() {
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
        // (Remains the same)
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

    // --- Actions ---
    @objc private func presentAuthVC() {
        let authVC = AuthViewController()
        // **FIX:** Assign delegate correctly now that ambiguity is resolved
        authVC.delegate = self
        let navController = UINavigationController(rootViewController: authVC)
        authVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissAuthVC))
        present(navController, animated: true, completion: nil)
    }
    @objc private func dismissAuthVC() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func handleSignOut() {
        print("Signing out user...")
        do {
            try Auth.auth().signOut()
            print("Sign out successful.")
            viewModel.clearUserSessionData()
            updateUIForAuthState()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            showSimpleAlert(title: "Sign Out Error", message: signOutError.localizedDescription)
        }
    }

    // **FIX:** AuthViewControllerDelegate Method Implementation
    // Parameter type matches the protocol defined in AuthViewController.swift
    func didCompleteAuth(firebaseUser: FirebaseAuth.User) {
         print("ProfileVC received didCompleteAuth callback for user: \(firebaseUser.uid)")
         updateUIForAuthState() // Refresh UI after successful authentication
    }

     // Helper to show alerts
     private func showSimpleAlert(title: String, message: String) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
         present(alert, animated: true, completion: nil)
     }
}
