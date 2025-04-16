//
//  AuthViewController.swift
//  Marko
//
//  Created by [Your Name/Date]
//

import UIKit
import Firebase // Import Firebase Auth

// Protocol to notify the presenter when authentication is complete
protocol AuthViewControllerDelegate: AnyObject {
    func didCompleteAuth(firebaseUser: FirebaseAuth.User) // Pass the Firebase User object
}

class AuthViewController: UIViewController {

    // Delegate to inform the presenting controller (e.g., ProfileVC)
    weak var delegate: AuthViewControllerDelegate? // Uses the protocol defined above

    // --- UI Elements ---
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password (min. 6 characters)"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign In / Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleAuthAction), for: .touchUpInside)
        return button
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Enter your email and password to sign in, or sign up if you're new."
        return label
    }()

    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    // --- View Lifecycle ---
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Sign In / Sign Up"
        setupViews()
        setupActivityIndicator()
    }

    // --- UI Setup ---
    private func setupViews() {
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(actionButton)
        stackView.addArrangedSubview(messageLabel)
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            actionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20)
        ])
    }

    // --- Actions ---
    @objc private func handleAuthAction() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showErrorAlert(message: "Please enter both email and password.")
            return
        }
        if password.count < 6 {
            showErrorAlert(message: "Password must be at least 6 characters long.")
            return
        }
        if !isValidEmail(email) {
            showErrorAlert(message: "Please enter a valid email address.")
            return
        }

        print("Attempting auth for email: \(email)")
        activityIndicator.startAnimating()
        actionButton.isEnabled = false

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }

            if let user = authResult?.user { // user is FirebaseAuth.User
                print("Sign In Successful! User: \(user.uid)")
                self.activityIndicator.stopAnimating()
                self.actionButton.isEnabled = true
                // Calls the method defined in the protocol above
                self.delegate?.didCompleteAuth(firebaseUser: user)
                self.dismiss(animated: true, completion: nil)
            } else if let error = error as NSError? {
                // Handle error cases
                print("Sign In Error Details: \(error)") // Keep detailed logging
                print("Sign In Error Localized: \(error.localizedDescription)")
                print("Sign In Error Domain: \(error.domain), Code: \(error.code)")

                // Check for specific underlying error message if top-level code is generic
                let underlyingErrorMessage = (error.userInfo[NSUnderlyingErrorKey] as? NSError)?
                    .userInfo[NSLocalizedDescriptionKey] as? String ?? ""

                let deserializedMessage = (error.userInfo[NSUnderlyingErrorKey] as? NSError)?
                    .userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] as? [String: Any]

                let firebaseMessage = deserializedMessage?["message"] as? String

                // If user doesn't exist OR credentials are just plain wrong, try signing up
                if error.code == AuthErrorCode.userNotFound.rawValue || firebaseMessage == "INVALID_LOGIN_CREDENTIALS" {
                    print("User not found or invalid credentials, attempting to sign up...")
                    self.signUpUser(email: email, password: password)
                } else {
                    // Handle other specific errors or show generic message
                    self.activityIndicator.stopAnimating()
                    self.actionButton.isEnabled = true
                    self.showErrorAlert(message: "Sign In Failed: \(error.localizedDescription)")
                }
            } else {
                // Unexpected state
                print("Sign In: Unexpected result without user or error.")
                self.activityIndicator.stopAnimating()
                self.actionButton.isEnabled = true
                self.showErrorAlert(message: "An unexpected error occurred during sign in.")
            }
        }
    }

    private func signUpUser(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.actionButton.isEnabled = true

            if let user = authResult?.user { // user is FirebaseAuth.User
                print("Sign Up Successful! User: \(user.uid)")
                // Calls the method defined in the protocol above
                self.delegate?.didCompleteAuth(firebaseUser: user)
                self.dismiss(animated: true, completion: nil)
            } else if let error = error {
                print("Sign Up Error: \(error.localizedDescription)")
                self.showErrorAlert(message: "Sign Up Failed: \(error.localizedDescription)")
            } else {
                print("Sign Up: Unexpected result without user or error.")
                self.showErrorAlert(message: "An unexpected error occurred during sign up.")
            }
        }
    }

    // --- Helpers ---
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Authentication Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
