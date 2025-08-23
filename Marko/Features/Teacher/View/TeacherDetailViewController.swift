//
//  TeacherDetailViewController.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import FSCalendar
import PassKit
import Firebase
import Kingfisher

class TeacherDetailViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource, PKPaymentAuthorizationViewControllerDelegate {
    private let viewModel: TeacherDetailViewModel
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private var calendar: FSCalendar!

    // UI components
    private let teacherImageView = UIImageView()
    private let teacherNameLabel = UILabel()
    private let teacherDescriptionLabel = UILabel()
    private let teacherRankLabel = UILabel()
    private let appointmentSlotsStackView = UIStackView()

    // State variables
    private var selectedDate: Date = Date() // Default to today
    private var timeSlotBeingBooked: TimeSlot?
    private var bookingResultStatus: PKPaymentAuthorizationStatus?
    private var bookingResultMessage: String?

    // Date Formatter
    private lazy var shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    init(viewModel: TeacherDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = viewModel.teacher.name

        viewModel.onTimeSlotsLoaded = { [weak self] timeSlots in
            DispatchQueue.main.async {
                self?.updateTimeSlotsUI(timeSlots)
            }
        }

        viewModel.onBookingCompleted = { [weak self] success, message, timeSlot in
            print("Booking completed callback received: Success=\(success), Message=\(message ?? "N/A")")
            self?.bookingResultStatus = success ? .success : .failure
            self?.bookingResultMessage = message
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupScrollView()
        setupContentStackView()
        setupCalendar()
        setupAppointmentSlotsSection()
        selectDate(Date()) // Select today initially

        viewModel.ensureSampleDataExists { [weak self] in
            guard let self = self else { return }
            print("Sample data setup complete. Loading actual slots for selected date: \(self.shortDateFormatter.string(from: self.selectedDate))")
            self.viewModel.loadTimeSlots(for: self.selectedDate)
        }
    }

    // MARK: - UI Setup Helpers
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupContentStackView() {
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)

        let padding: CGFloat = 20
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: padding),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: padding),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -padding),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -padding),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(2 * padding))
        ])

        // --- Add Teacher Info ---
        let url = URL(string: viewModel.teacher.profileImageURL)
        let placeholder = UIImage(systemName: "person.crop.square.fill")
        teacherImageView.kf.setImage(with: url, placeholder: placeholder) // Using Kingfisher
        teacherImageView.contentMode = .scaleAspectFill
        teacherImageView.layer.cornerRadius = 10
        teacherImageView.clipsToBounds = true
        teacherImageView.backgroundColor = .systemGray5
        teacherImageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        contentStackView.addArrangedSubview(teacherImageView)

        teacherNameLabel.text = viewModel.teacher.name
        teacherNameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        teacherNameLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(teacherNameLabel)

        teacherDescriptionLabel.text = viewModel.teacher.description
        teacherDescriptionLabel.numberOfLines = 0
        teacherDescriptionLabel.font = UIFont.systemFont(ofSize: 16)
        teacherDescriptionLabel.textColor = .secondaryLabel
        contentStackView.addArrangedSubview(teacherDescriptionLabel)

        teacherRankLabel.text = "Rank: \(viewModel.teacher.rank)"
        teacherRankLabel.font = UIFont.systemFont(ofSize: 16)
        teacherRankLabel.textColor = .tertiaryLabel
        contentStackView.addArrangedSubview(teacherRankLabel)
    }

    private func setupCalendar() {
        calendar = FSCalendar()
        calendar.delegate = self
        calendar.dataSource = self
        calendar.translatesAutoresizingMaskIntoConstraints = false
        calendar.appearance.todayColor = .systemGray
        calendar.appearance.selectionColor = .systemBlue
        calendar.appearance.headerTitleFont = UIFont.boldSystemFont(ofSize: 18)
        calendar.appearance.weekdayFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        contentStackView.addArrangedSubview(calendar)
        calendar.heightAnchor.constraint(equalToConstant: 300).isActive = true
    }

    private func setupAppointmentSlotsSection() {
        let appointmentLabel = UILabel()
        appointmentLabel.text = "Available Slots:"
        appointmentLabel.font = UIFont.boldSystemFont(ofSize: 18)
        contentStackView.addArrangedSubview(appointmentLabel)

        appointmentSlotsStackView.axis = .vertical
        appointmentSlotsStackView.spacing = 10
        appointmentSlotsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(appointmentSlotsStackView)
    }

    // MARK: - UI Update Logic
    private func updateTimeSlotsUI(_ timeSlots: [TimeSlot]) {
        appointmentSlotsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if timeSlots.isEmpty {
            let noSlotsLabel = UILabel()
            noSlotsLabel.text = "No available slots found for this date."
            noSlotsLabel.textAlignment = .center
            noSlotsLabel.textColor = .secondaryLabel
            noSlotsLabel.font = UIFont.systemFont(ofSize: 15)
            appointmentSlotsStackView.addArrangedSubview(noSlotsLabel)
        } else {
            for slot in timeSlots {
                if let bookedSlot = timeSlotBeingBooked, slot.id == bookedSlot.id, bookingResultStatus == .success {
                    continue
                }
                let price = slot.calculatePrice()
                let formattedPrice = String(format: "%.0f", price)
                let slotText = "\(slot.formattedTimeSlot()) (₴\(formattedPrice) UAH)"
                let slotView = AppointmentSlotView(slotText: slotText)
                slotView.onPayTapped = { [weak self] in
                    self?.handleApplePayRequest(for: slot)
                }
                appointmentSlotsStackView.addArrangedSubview(slotView)
            }
        }
    }

    // MARK: - FSCalendar Delegate & DataSource
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        selectDate(date)
        viewModel.loadTimeSlots(for: selectedDate)
    }

    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let dateStart = Calendar.current.startOfDay(for: date)
        return dateStart >= todayStart
    }

    private func selectDate(_ date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
        calendar.select(selectedDate, scrollToDate: true)
    }

    // MARK: - Apple Pay Handling
    private func handleApplePayRequest(for timeSlot: TimeSlot) {
        bookingResultStatus = nil
        bookingResultMessage = nil
        timeSlotBeingBooked = timeSlot
        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            showSimpleAlert(title: "Apple Pay Unavailable", message: "This device cannot make Apple Pay payments or it's not set up.")
            return
        }
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = "merchant.com.marko.languageapp"
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex]
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = "UA"
        paymentRequest.currencyCode = "UAH"
        let lessonPrice = NSDecimalNumber(value: timeSlot.calculatePrice())
        let lessonItem = PKPaymentSummaryItem(label: "Lesson: \(timeSlot.formattedTimeSlot())", amount: lessonPrice)
        let totalItem = PKPaymentSummaryItem(label: "Total (Marko School)", amount: lessonPrice)
        paymentRequest.paymentSummaryItems = [lessonItem, totalItem]
        
        if let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) {
            paymentVC.delegate = self
            present(paymentVC, animated: true, completion: nil)
        } else {
            showSimpleAlert(title: "Error", message: "Could not start Apple Pay. Please try again.")
        }
    }

    // MARK: - PKPaymentAuthorizationViewControllerDelegate Methods
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        guard let slotToBook = timeSlotBeingBooked else {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        
        // ** THE FIX IS HERE **
        guard let userId = AuthService.shared.currentUser?.uid else {
            let error = NSError(domain: "MarkoAppErrorDomain", code: 101, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to book a session."])
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            return
        }
        
        viewModel.bookTimeSlot(slotToBook, userId: userId)
        storePaymentTokenDetails(payment.token, for: slotToBook.id, userId: userId)
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.showBookingResultAlert()
        }
    }

    // MARK: - Alert Presentation
    private func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func showBookingResultAlert() {
        guard let status = bookingResultStatus else {
            timeSlotBeingBooked = nil
            return
        }
        let title = (status == .success) ? "Booking Confirmed!" : "Booking Failed"
        let message = bookingResultMessage ?? ((status == .success) ? "Your session is booked." : "Could not complete the booking.")
        showSimpleAlert(title: title, message: message)
        
        if status == .success {
            viewModel.loadTimeSlots(for: selectedDate)
        }
        
        bookingResultStatus = nil
        bookingResultMessage = nil
        timeSlotBeingBooked = nil
    }

    // MARK: - Payment Token Storage
    private func storePaymentTokenDetails(_ token: PKPaymentToken, for timeSlotId: String, userId: String) {
        let db = Firestore.firestore()
        let paymentRef = db.collection("payments").document()
        let tokenDataString = token.paymentData.base64EncodedString()
        let paymentRecord: [String: Any] = [
            "userId": userId,
            "timeSlotId": timeSlotId,
            "teacherId": viewModel.teacher.id,
            "transactionIdentifier": token.transactionIdentifier,
            "paymentData_base64": tokenDataString,
            "paymentMethodNetwork": token.paymentMethod.network?.rawValue ?? "N/A",
            "paymentMethodDisplayName": token.paymentMethod.displayName ?? "N/A",
            "timestamp": FieldValue.serverTimestamp()
        ]
        paymentRef.setData(paymentRecord) { error in
            if let error = error {
                print("Error storing payment token details in Firestore: \(error.localizedDescription)")
            } else {
                print("Payment token details stored successfully (Payment Record ID: \(paymentRef.documentID))")
            }
        }
    }
}

// MARK: - Legacy PKPaymentAuthorizationViewControllerDelegate
extension TeacherDetailViewController {
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        guard let slotToBook = timeSlotBeingBooked else {
            completion(.failure)
            return
        }
        
        // This was already correct in your version, but included for completeness
        guard let userId = AuthService.shared.currentUser?.uid else {
            completion(.failure)
            return
        }
        
        viewModel.bookTimeSlot(slotToBook, userId: userId)
        storePaymentTokenDetails(payment.token, for: slotToBook.id, userId: userId)
        completion(.success)
    }
}
