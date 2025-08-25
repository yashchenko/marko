// file: Main/MainViewController.swift

import UIKit

class MainViewController: UIViewController {

    // MARK: - Properties
    private lazy var teacherListVC: TeacherListViewController = {
        let viewModel = TeacherListViewModel()
        // We will hook up navigation later
        return TeacherListViewController(viewModel: viewModel)
    }()

    private lazy var wordsVC = UIViewController()   // Still a placeholder
    private lazy var profileVC = UIViewController()  // Still a placeholder
    private var currentViewController: UIViewController?

    // MARK: - UI Elements
    private let containerView = UIView()
    private let customNavBar = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupPlaceholderVCs()
        setupUI()
        
        showViewController(teacherListVC)
    }
    
    private func setupPlaceholderVCs() {
        teacherListVC.view.backgroundColor = .systemGray5
        let teachersLabel = UILabel()
        teachersLabel.text = "Teachers VC Area"
        teachersLabel.textAlignment = .center
        teacherListVC.view.addSubview(teachersLabel)
        teachersLabel.frame = teacherListVC.view.bounds
        
        wordsVC.view.backgroundColor = .systemGray6
        profileVC.view.backgroundColor = .systemTeal
    }

    // MARK: - UI Setup
    private func setupUI() {
        customNavBar.backgroundColor = .secondarySystemBackground
        customNavBar.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(customNavBar)
        view.addSubview(containerView)
        
        // AC #4: Setup Navigation Bar Title
        let titleLabel = UILabel()
        titleLabel.text = "Marko School"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        customNavBar.addSubview(titleLabel)
        
        // AC #5: Setup Navigation Buttons
        let myLessonsButton = createNavButton(title: "My Lessons")
        let profileButton = createNavButton(title: "AB") // Initials
        
        let buttonStackView = UIStackView(arrangedSubviews: [myLessonsButton, profileButton])
        buttonStackView.spacing = 12
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        customNavBar.addSubview(buttonStackView)
        
        NSLayoutConstraint.activate([
            // Custom Nav Bar
            customNavBar.topAnchor.constraint(equalTo: view.topAnchor),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Container View for child VCs
            containerView.topAnchor.constraint(equalTo: customNavBar.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor), // Will be adjusted for custom tab bar later
            
            // Title in Nav Bar
            titleLabel.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: customNavBar.bottomAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            
            // Buttons in Nav Bar
            buttonStackView.trailingAnchor.constraint(equalTo: customNavBar.trailingAnchor, constant: -16),
            buttonStackView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
    }
    
    private func createNavButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemGray4
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 15 // Make it circular
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return button
    }

    // MARK: - Helper Methods
    private func showViewController(_ vc: UIViewController) {
        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        
        addChild(vc)
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParent: self)
        
        currentViewController = vc
    }
}
