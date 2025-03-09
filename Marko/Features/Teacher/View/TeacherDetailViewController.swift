//
//  TeacherDetailViewController.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import FSCalendar
import PassKit

class TeacherDetailViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource {
    private let viewModel: TeacherDetailViewModel
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private var calendar: FSCalendar!
    
    // UI components
    private let teacherImageView = UIImageView()
    private let teacherNameLabel = UILabel()
    private let teacherDescriptionLabel = UILabel()
    private let teacherRankLabel = UILabel()
    // Container for appointment slots
    private let appointmentSlotsStackView = UIStackView()
    
    init(viewModel: TeacherDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = viewModel.teacher.name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupScrollView()
        setupContent()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupContent() {
        // Teacher photo
        teacherImageView.image = viewModel.teacher.profileImage
        teacherImageView.contentMode = .scaleAspectFill
        teacherImageView.layer.cornerRadius = 10
        teacherImageView.clipsToBounds = true
        teacherImageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        contentStackView.addArrangedSubview(teacherImageView)
        
        // Teacher name
        teacherNameLabel.text = viewModel.teacher.name
        teacherNameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        contentStackView.addArrangedSubview(teacherNameLabel)
        
        // Teacher description (using subject as placeholder)
        teacherDescriptionLabel.text = "Subject: \(viewModel.teacher.subject). Experienced and passionate educator."
        teacherDescriptionLabel.numberOfLines = 0
        teacherDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        contentStackView.addArrangedSubview(teacherDescriptionLabel)
        
        // Teacher rank
        teacherRankLabel.text = "Rank: Expert" // Replace with dynamic data as needed.
        teacherRankLabel.font = UIFont.systemFont(ofSize: 16)
        contentStackView.addArrangedSubview(teacherRankLabel)
        
        // FSCalendar
        calendar = FSCalendar()
        calendar.delegate = self
        calendar.dataSource = self
        calendar.heightAnchor.constraint(equalToConstant: 300).isActive = true
        contentStackView.addArrangedSubview(calendar)
        
        // Appointment Slots Section Label
        let appointmentLabel = UILabel()
        appointmentLabel.text = "Available Appointment Slots:"
        appointmentLabel.font = UIFont.boldSystemFont(ofSize: 18)
        contentStackView.addArrangedSubview(appointmentLabel)
        
        // Container for appointment slots
        appointmentSlotsStackView.axis = .vertical
        appointmentSlotsStackView.spacing = 10
        appointmentSlotsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(appointmentSlotsStackView)
        
        // Sample appointment slot (in a real app, these would be generated dynamically)
        let slot1 = AppointmentSlotView(slotText: "Thursday 10am - 11am (300 UAH/hr)")
        slot1.onPayTapped = { [weak self] in
            self?.handleApplePay(for: "Thursday 10am - 11am", costPerHour: 300)
        }
        appointmentSlotsStackView.addArrangedSubview(slot1)
    }
    
    // FSCalendar Delegate & DataSource Methods
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // Update available appointment slots based on the selected date if needed.
        print("Selected date: \(date)")
    }
    
    private func handleApplePay(for slot: String, costPerHour: Int) {
        // Check Apple Pay availability
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            let alert = UIAlertController(title: "Error", message: "Apple Pay is not available on this device.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Configure the payment request
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "your.merchant.identifier" // Replace with your merchant identifier.
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex]
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = "UA"
        paymentRequest.currencyCode = "UAH"
        
        // For a one-hour appointment
        let amount = NSDecimalNumber(value: costPerHour)
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Appointment Slot", amount: amount)
        ]
        
        if let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) {
            paymentVC.delegate = self
            present(paymentVC, animated: true)
        } else {
            let alert = UIAlertController(title: "Error", message: "Unable to present Apple Pay authorization.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

// MARK: - Apple Pay Delegate

extension TeacherDetailViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Process payment (e.g., send payment.token to your backend).
        // For demonstration, we assume success.
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true)
    }
}
