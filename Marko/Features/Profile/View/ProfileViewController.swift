//
//  ProfileViewController.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import Firebase // Import Firebase Auth

class ProfileViewController: UIViewController, AuthViewControllerDelegate {

    private let viewModel: ProfileViewModel

    // --- UI Elements ---
    // Scroll view to contain everything, allowing content to scroll if it exceeds screen height
    private let scrollView = UIScrollView()
    // Content view inside the scroll view to hold all other elements
    private let contentView = UIView()

    // Profile specific elements
    private let photoImageView = UIImageView()
    private let nameLabel = UILabel()
    private let levelLabel = UILabel()
    private let nextSessionLabel = UILabel()
    private let upgradePromptLabel = UILabel()
    private let sessionsLabel = UILabel() // Keep the title label
    private let bookedSessionsStackView = UIStackView() // The main stack for booked items
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // Auth buttons outside the main content stack, pinned relative to safe area or scroll view
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
        // ** CHANGE: Call new setup structure **
        setupScrollViewAndContentView()
        setupProfileElements() // Setup elements within contentView
        setupActivityIndicator()
        updateUIForAuthState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("ProfileVC: viewWillAppear")
        updateUIForAuthState()
    }

    // --- UI Setup ---

    // ** NEW: Setup Scroll View and Content View **
    private func setupScrollViewAndContentView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // ScrollView constraints (pin to safe area)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor) // Let scroll view define boundary
        ])

        // ContentView constraints (pin to scroll view's content guides, width matches frame guide)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            // Critical: ContentView width must equal ScrollView's frame width for vertical scrolling
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // ** MODIFIED: Setup elements relative to contentView **
    private func setupProfileElements() {
         // Add all profile elements to the contentView now, not the main view
         contentView.addSubview(photoImageView)
         contentView.addSubview(nameLabel)
         contentView.addSubview(levelLabel)
         contentView.addSubview(nextSessionLabel)
         contentView.addSubview(upgradePromptLabel)
         contentView.addSubview(sessionsLabel) // Add the sessions title label
         contentView.addSubview(bookedSessionsStackView)
         contentView.addSubview(authButton)
         contentView.addSubview(signOutButton)

         // --- Configure elements ---
         photoImageView.contentMode = .scaleAspectFill
         photoImageView.layer.cornerRadius = 50
         photoImageView.clipsToBounds = true
         photoImageView.backgroundColor = .systemGray5
         photoImageView.translatesAutoresizingMaskIntoConstraints = false

         nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
         nameLabel.textAlignment = .center
         nameLabel.numberOfLines = 0
         nameLabel.translatesAutoresizingMaskIntoConstraints = false

         levelLabel.font = UIFont.systemFont(ofSize: 18)
         levelLabel.textAlignment = .center
         levelLabel.translatesAutoresizingMaskIntoConstraints = false

         nextSessionLabel.font = UIFont.systemFont(ofSize: 16)
         nextSessionLabel.textColor = .secondaryLabel
         nextSessionLabel.numberOfLines = 0
         nextSessionLabel.textAlignment = .center
         nextSessionLabel.translatesAutoresizingMaskIntoConstraints = false

         upgradePromptLabel.font = UIFont.systemFont(ofSize: 16)
         upgradePromptLabel.numberOfLines = 0
         upgradePromptLabel.textColor = .systemBlue
         upgradePromptLabel.textAlignment = .center
         upgradePromptLabel.translatesAutoresizingMaskIntoConstraints = false

         sessionsLabel.text = "Your Upcoming Sessions:"
         sessionsLabel.font = UIFont.boldSystemFont(ofSize: 18)
         sessionsLabel.translatesAutoresizingMaskIntoConstraints = false

         bookedSessionsStackView.axis = .vertical
         bookedSessionsStackView.spacing = 12
         bookedSessionsStackView.translatesAutoresizingMaskIntoConstraints = false

         // --- Layout Constraints within contentView ---
         let standardPadding: CGFloat = 20
         NSLayoutConstraint.activate([
             // Pin elements vertically from top to bottom of contentView
             photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: standardPadding),
             photoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
             photoImageView.widthAnchor.constraint(equalToConstant: 100),
             photoImageView.heightAnchor.constraint(equalToConstant: 100),

             nameLabel.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: standardPadding),
             nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: standardPadding),
             nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -standardPadding),

             levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
             levelLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: standardPadding),
             levelLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -standardPadding),

             nextSessionLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor, constant: standardPadding),
             nextSessionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: standardPadding),
             nextSessionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -standardPadding),

             upgradePromptLabel.topAnchor.constraint(equalTo: nextSessionLabel.bottomAnchor, constant: standardPadding),
             upgradePromptLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: standardPadding),
             upgradePromptLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -standardPadding),

             sessionsLabel.topAnchor.constraint(equalTo: upgradePromptLabel.bottomAnchor, constant: 30),
             sessionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: standardPadding),
             sessionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -standardPadding),

             bookedSessionsStackView.topAnchor.constraint(equalTo: sessionsLabel.bottomAnchor, constant: 10),
             bookedSessionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: standardPadding),
             bookedSessionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -standardPadding),

             // Auth Button pinned below stack view
             authButton.topAnchor.constraint(equalTo: bookedSessionsStackView.bottomAnchor, constant: 30),
             authButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 50),
             authButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -50),
             authButton.heightAnchor.constraint(equalToConstant: 50),
             // ** Pin Auth button to BOTTOM of contentView **
             authButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -standardPadding),


             // Sign Out Button pinned below stack view
             signOutButton.topAnchor.constraint(equalTo: bookedSessionsStackView.bottomAnchor, constant: 30),
             signOutButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
             signOutButton.heightAnchor.constraint(equalToConstant: 44),
              // ** Pin Sign Out button to BOTTOM of contentView **
             signOutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -standardPadding)
         ])
    }


    // Remove setupAuthAndSignOutButtons - integrated above
    // Remove setupViews - integrated above

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        // Add to main view, not scroll view, so it stays centered on screen
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // --- UI Update Logic (No changes needed here) ---
    private func updateUIForAuthState() {
         // This logic correctly hides/shows elements based on auth state
         // It should work fine with the new scroll view structure
        if let currentUser = Auth.auth().currentUser {
             print("User is logged in: \(currentUser.uid) - \(currentUser.email ?? "No Email")")
             signOutButton.isHidden = false
             authButton.isHidden = true
             activityIndicator.startAnimating() // Start loading

             // Show logged-in UI elements within contentView
             photoImageView.isHidden = false
             nameLabel.isHidden = false
             levelLabel.isHidden = false
             nextSessionLabel.isHidden = false
             upgradePromptLabel.isHidden = false // Or based on logic
             sessionsLabel.isHidden = false
             bookedSessionsStackView.isHidden = false

             // Update static content
             nameLabel.text = currentUser.email
             photoImageView.image = UIImage(systemName: "person.crop.circle.fill")
             levelLabel.text = "English Level: \(viewModel.user.englishLevel)"
             if let prompt = viewModel.upgradePrompt() {
                 upgradePromptLabel.text = prompt
                 upgradePromptLabel.isHidden = false
             } else {
                 upgradePromptLabel.isHidden = true
             }

             viewModel.loadBookedSessions() // Load dynamic data

         } else {
             print("User is logged out.")
             signOutButton.isHidden = true
             authButton.isHidden = false
             activityIndicator.stopAnimating() // Stop loading

              // Show logged-out UI elements within contentView
              photoImageView.isHidden = false // Keep photo placeholder visible
              nameLabel.isHidden = false
              levelLabel.isHidden = true
              nextSessionLabel.isHidden = true
              upgradePromptLabel.isHidden = true
              sessionsLabel.isHidden = true
              bookedSessionsStackView.isHidden = true

              // Update static content for logged out state
              nameLabel.text = "Welcome!"
              photoImageView.image = UIImage(systemName: "person.circle")
              bookedSessionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() } // Clear old views
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
         print("ProfileVC: Updating booked sessions list view. Count: \(viewModel.bookedSessions.count)")
        bookedSessionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if viewModel.bookedSessions.isEmpty {
             let noSessionsLabel = UILabel()
             noSessionsLabel.text = "You haven't booked any upcoming sessions yet."
             noSessionsLabel.textColor = .secondaryLabel
             noSessionsLabel.textAlignment = .center
             noSessionsLabel.font = UIFont.systemFont(ofSize: 15)
             // Add label directly to stack view
             bookedSessionsStackView.addArrangedSubview(noSessionsLabel)
        } else {
            for booking in viewModel.bookedSessions {
                print("ProfileVC: Creating session view for booking ID \(booking.id)")
                let sessionView = createSessionView(for: booking)
                bookedSessionsStackView.addArrangedSubview(sessionView)
            }
        }
         // Ensure the stack view and its parents are visible
          bookedSessionsStackView.isHidden = viewModel.bookedSessions.isEmpty && Auth.auth().currentUser != nil // Hide stack if logged in but no sessions
          sessionsLabel.isHidden = bookedSessionsStackView.isHidden // Hide title if stack is hidden
    }

    // createSessionView remains the same as the previous corrected version
    private func createSessionView(for booking: Booking) -> UIView {
        print("--- createSessionView executing for booking ID \(booking.id) ---")
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 5
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let dateLabel = UILabel()
        dateLabel.text = booking.timeSlot.formattedTimeSlot()
        dateLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        dateLabel.numberOfLines = 0
        dateLabel.textColor = .label
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        print("    Date Label Text: \(dateLabel.text ?? "NIL")")

        let teacherLabel = UILabel()
        let teacherName = viewModel.teachers[booking.teacherId]?.name ?? "Teacher \(booking.teacherId)"
        teacherLabel.text = "Teacher: \(teacherName)"
        teacherLabel.font = UIFont.systemFont(ofSize: 14)
        teacherLabel.textColor = .secondaryLabel
        teacherLabel.numberOfLines = 0
        teacherLabel.translatesAutoresizingMaskIntoConstraints = false
        print("    Teacher Label Text: \(teacherLabel.text ?? "NIL")")

        let priceLabel = UILabel()
        let formattedPrice = String(format: "%.0f", booking.paymentAmount)
        priceLabel.text = "Paid: ₴\(formattedPrice) UAH"
        priceLabel.font = UIFont.systemFont(ofSize: 14)
        priceLabel.textColor = .tertiaryLabel
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        print("    Price Label Text: \(priceLabel.text ?? "NIL")")

        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(teacherLabel)
        stackView.addArrangedSubview(priceLabel)

        container.addSubview(stackView)
        print("    Inner stackView added to container. Subviews: \(container.subviews.count)")
        print("    Inner stackView arranged subviews: \(stackView.arrangedSubviews.count)")

        let innerPadding: CGFloat = 12
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: innerPadding),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: innerPadding),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -innerPadding),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -innerPadding)
        ])

        print("--- Returning container view ---")
        return container
    }

    // --- Actions (Keep as is) ---
    @objc private func presentAuthVC() {
        let authVC = AuthViewController()
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

    // --- AuthViewControllerDelegate (Keep as is) ---
    func didCompleteAuth(firebaseUser: FirebaseAuth.User) {
         print("ProfileVC received didCompleteAuth callback for user: \(firebaseUser.uid)")
         updateUIForAuthState()
    }

     // --- Helpers (Keep as is) ---
     private func showSimpleAlert(title: String, message: String) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
         present(alert, animated: true, completion: nil)
     }
}
