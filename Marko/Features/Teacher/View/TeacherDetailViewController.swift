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
    
    // Currently selected date
    private var selectedDate: Date = Date()
    
    init(viewModel: TeacherDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = viewModel.teacher.name
        
        // Set up callbacks
        viewModel.onTimeSlotsLoaded = { [weak self] timeSlots in
            DispatchQueue.main.async {
                self?.updateTimeSlots(timeSlots)
            }
        }
        
        viewModel.onBookingCompleted = { [weak self] success, timeSlot in
            DispatchQueue.main.async {
                if success {
                    self?.showBookingSuccess(for: timeSlot)
                } else {
                    self?.showBookingError()
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupScrollView()
        setupContent()
        
        // Add sample time slots for testing (comment out for production)
        viewModel.addSampleTimeSlots { [weak self] in
            self?.viewModel.loadAvailableTimeSlots()
        }
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
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
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
        
        // Teacher description
        teacherDescriptionLabel.text = viewModel.teacher.description
        teacherDescriptionLabel.numberOfLines = 0
        teacherDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        contentStackView.addArrangedSubview(teacherDescriptionLabel)
        
        // Teacher rank
        teacherRankLabel.text = "Rank: \(viewModel.teacher.rank)"
        teacherRankLabel.font = UIFont.systemFont(ofSize: 16)
        contentStackView.addArrangedSubview(teacherRankLabel)
        
        // FSCalendar
        calendar = FSCalendar()
        calendar.delegate = self
        calendar.dataSource = self
        calendar.heightAnchor.constraint(equalToConstant: 300).isActive = true
        contentStackView.addArrangedSubview(calendar)
        
        // Select today's date by default
        calendar.select(Date())
        
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
        
        // Load initial time slots for today
        viewModel.loadTimeSlots(for: Date())
    }
    
    // Update UI with available time slots
    private func updateTimeSlots(_ timeSlots: [TimeSlot]) {
        // Clear existing slots
        appointmentSlotsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if timeSlots.isEmpty {
            let noSlotsLabel = UILabel()
            noSlotsLabel.text = "No available slots for this date."
            noSlotsLabel.textAlignment = .center
            noSlotsLabel.textColor = .gray
            appointmentSlotsStackView.addArrangedSubview(noSlotsLabel)
            return
        }
        
        // Add slot views for each time slot
        for slot in timeSlots {
            let slotView = AppointmentSlotView(slotText: slot.formattedTimeSlot() + " (₴\(Int(slot.calculatePrice())) UAH)")
            slotView.onPayTapped = { [weak self] in
                self?.handleApplePay(for: slot)
            }
            appointmentSlotsStackView.addArrangedSubview(slotView)
        }
    }
    
    // FSCalendar Delegate & DataSource Methods
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectedDate = date
        viewModel.loadTimeSlots(for: date)
    }
    
    // Handle Apple Pay for the selected time slot
    private func handleApplePay(for timeSlot: TimeSlot) {
        // Check Apple Pay availability
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            let alert = UIAlertController(title: "Error", message: "Apple Pay is not available on this device.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Configure the payment request
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "merchant.com.marko.languageapp" // Replace with your merchant identifier
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex]
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = "UA"
        paymentRequest.currencyCode = "UAH"
        
        // For the appointment
        let amount = NSDecimalNumber(value: timeSlot.calculatePrice())
        let totalLabel = "Lesson with \(viewModel.teacher.name): \(timeSlot.formattedTimeSlot())"
        
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: totalLabel, amount: amount)
        ]
        
        if let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) {
            // Store the timeSlot for use in the delegate methods
            UserDefaults.standard.set(timeSlot.id, forKey: "pendingBookingTimeSlotId")
            
            paymentVC.delegate = self
            present(paymentVC, animated: true)
        } else {
            let alert = UIAlertController(title: "Error", message: "Unable to present Apple Pay authorization.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    // Show success message after booking
    private func showBookingSuccess(for timeSlot: TimeSlot) {
        let alert = UIAlertController(
            title: "Booking Confirmed!",
            message: "Your session with \(viewModel.teacher.name) has been booked for \(timeSlot.formattedTimeSlot()).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Show error message if booking fails
    private func showBookingError() {
        let alert = UIAlertController(
            title: "Booking Failed",
            message: "There was an error while booking your session. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Apple Pay Delegate Extension
//extension TeacherDetailViewController: PKPaymentAuthorizationViewControllerDelegate {
//    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
//                                            didAuthorizePayment payment: PKPayment,
//                                            completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
//        // In a real app, you would send payment.token to your server for processing
//
//        // For this demo, we'll assume payment is successful and book the slot
//        guard let timeSlotId = UserDefaults.standard.string(forKey: "pendingBookingTimeSlotId"),
//              let selectedTimeSlot = viewModel.availableTimeSlots.first(where: { $0.id == timeSlotId }) else {
//            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
//            return
//        }
//
//        // Book the time slot (using a mock user ID for now)
//        viewModel.bookTimeSlot(selectedTimeSlot, userId: "current_user_id")
//        UserDefaults.standard.removeObject(forKey: "pendingBookingTimeSlotId")
//
//        // Complete the Apple Pay transaction
//        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
//    }
//
//    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
//        controller.dismiss(animated: true)
//    }
//}
//
//



// MARK: - Apple Pay Delegate Extension
extension TeacherDetailViewController: PKPaymentAuthorizationViewControllerDelegate {
    // Current implementation (iOS 11+)
    
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // In a real app, you would send payment.token to your server for processing
        
        // For this demo, we'll assume payment is successful and book the slot
        guard let timeSlotId = UserDefaults.standard.string(forKey: "pendingBookingTimeSlotId"),
              let selectedTimeSlot = viewModel.availableTimeSlots.first(where: { $0.id == timeSlotId }) else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        
        // Book the time slot (using a mock user ID for now)
        viewModel.bookTimeSlot(selectedTimeSlot, userId: "current_user_id")
        UserDefaults.standard.removeObject(forKey: "pendingBookingTimeSlotId")
        
        // Complete the Apple Pay transaction
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    // Legacy implementation (pre-iOS 11) - add this method
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                           didAuthorizePayment payment: PKPayment,
                                           completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        print("Payment authorized (legacy method)")
        print("Payment token: \(payment.token)")
        
        // Mirror the same logic as above
        guard let timeSlotId = UserDefaults.standard.string(forKey: "pendingBookingTimeSlotId"),
              let selectedTimeSlot = viewModel.availableTimeSlots.first(where: { $0.id == timeSlotId }) else {
            completion(.failure)
            return
        }
        
        // Book the time slot (using a mock user ID for now)
        viewModel.bookTimeSlot(selectedTimeSlot, userId: "current_user_id")
        UserDefaults.standard.removeObject(forKey: "pendingBookingTimeSlotId")
        
        // Complete the Apple Pay transaction
        completion(.success)
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true)
    }
}
