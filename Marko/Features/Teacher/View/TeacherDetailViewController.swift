//
//  TeacherDetailViewController.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit
import FSCalendar
import PassKit // For Apple Pay
import Firebase // For Auth and Firestore

// **FIX:** Add PKPaymentAuthorizationViewControllerDelegate conformance here
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

    // State variables for handling Apple Pay flow
    private var selectedDate: Date = Date()
    private var timeSlotBeingBooked: TimeSlot?
    private var bookingResultStatus: PKPaymentAuthorizationStatus?
    private var bookingResultMessage: String?

    // Date Formatter for compatibility with iOS 14
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

        viewModel.addSampleTimeSlotsIfNeeded { [weak self] in
             guard let self = self else { return }
             print("Sample slots checked/added. Loading actual slots for selected date: \(self.shortDateFormatter.string(from: self.selectedDate))")
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
        teacherImageView.image = viewModel.teacher.profileImage
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
        // **FIX:** Use DateFormatter for compatibility
        let dateString = shortDateFormatter.string(from: selectedDate)
        print("Updating UI with \(timeSlots.count) time slots for date: \(dateString)")

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
                      print("Skipping slot \(slot.id) as it was just successfully booked.")
                      continue
                 }
                let price = slot.calculatePrice()
                let formattedPrice = String(format: "%.0f", price)
                let slotText = "\(slot.formattedTimeSlot()) (₴\(formattedPrice) UAH)"
                let slotView = AppointmentSlotView(slotText: slotText)
                slotView.onPayTapped = { [weak self] in
                    print("Pay button tapped for slot: \(slot.id) - \(slot.formattedTimeSlot())")
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
        print("Selected date updated to: \(shortDateFormatter.string(from: selectedDate))")
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
        paymentRequest.merchantIdentifier = "merchant.com.marko.languageapp" // ** YOUR MERCHANT ID **
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex]
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = "UA"
        paymentRequest.currencyCode = "UAH"

        let lessonPrice = NSDecimalNumber(value: timeSlot.calculatePrice())
        let lessonLabel = "Lesson: \(timeSlot.formattedTimeSlot())"
        let lessonItem = PKPaymentSummaryItem(label: lessonLabel, amount: lessonPrice, type: .final)
        let totalLabel = "Total (Marko School)"
        let totalItem = PKPaymentSummaryItem(label: totalLabel, amount: lessonPrice, type: .final)
        paymentRequest.paymentSummaryItems = [lessonItem, totalItem]

        if let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) {
            // **FIX:** Ensure delegate is set correctly after adding conformance
            paymentVC.delegate = self
            print("Presenting Apple Pay sheet for slot \(timeSlot.id)...")
            present(paymentVC, animated: true, completion: nil)
        } else {
            print("Error: Could not initialize PKPaymentAuthorizationViewController.")
            showSimpleAlert(title: "Error", message: "Could not start Apple Pay. Please try again.")
        }
    }

    // MARK: - PKPaymentAuthorizationViewControllerDelegate Methods (iOS 11+)
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                            didAuthorizePayment payment: PKPayment,
                                            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        print("Payment authorized (iOS 11+ delegate)")
        guard let slotToBook = timeSlotBeingBooked else {
            print("Error: timeSlotBeingBooked is nil during payment authorization.")
            completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User is not logged in. Cannot proceed with booking.")
            // **FIX:** Use standard NSError for custom error message
            let error = NSError(domain: "MarkoAppErrorDomain", code: 101, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to book a session."])
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            return
        }

        print("Attempting to book time slot \(slotToBook.id) for user \(userId)")
        viewModel.bookTimeSlot(slotToBook, userId: userId)
        storePaymentTokenDetails(payment.token, for: slotToBook.id, userId: userId)
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil)) // Let sheet proceed
    }

    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        print("Payment sheet finished.")
        controller.dismiss(animated: true) { [weak self] in
            print("Dismiss complete. Checking booking result...")
            self?.showBookingResultAlert() // Show result *after* dismissal
        }
    }

    // MARK: - Alert Presentation
    private func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            if self.presentedViewController == nil {
                self.present(alert, animated: true, completion: nil)
            } else {
                 print("Warning: Tried to present alert while another view controller was already presented.")
            }
        }
    }

    private func showBookingResultAlert() {
        guard let status = bookingResultStatus else {
            print("No booking result status available (possibly cancelled). No alert shown.")
             if timeSlotBeingBooked != nil { timeSlotBeingBooked = nil }
            return
         }

        let title = (status == .success) ? "Booking Confirmed!" : "Booking Failed"
        // **FIX:** Correctly use ?? on optional String?. Warning likely spurious if logic is correct.
        let message = bookingResultMessage ?? ((status == .success) ? "Your session is booked." : "Could not complete the booking.")

        print("Showing booking result alert: Title='\(title)', Message='\(message)'")
        showSimpleAlert(title: title, message: message)

        if status == .success {
            print("Booking successful, refreshing time slots for the selected date.")
            viewModel.loadTimeSlots(for: selectedDate)
        }
        bookingResultStatus = nil
        bookingResultMessage = nil
        timeSlotBeingBooked = nil
    }

    // MARK: - Payment Token Storage (Example)
    private func storePaymentTokenDetails(_ token: PKPaymentToken, for timeSlotId: String, userId: String) {
        let db = Firestore.firestore()
        let paymentRef = db.collection("payments").document()
        let tokenDataString = token.paymentData.base64EncodedString()
        let paymentRecord: [String: Any] = [
            "userId": userId,
            "timeSlotId": timeSlotId,
            "teacherId": viewModel.teacher.id,
            "transactionIdentifier": token.transactionIdentifier ?? "N/A",
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

// MARK: - Legacy PKPaymentAuthorizationViewControllerDelegate (Pre-iOS 11)
// If supporting < iOS 11 (unlikely for target 14.4), keep this. Otherwise, can be removed.
extension TeacherDetailViewController {
     func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController,
                                             didAuthorizePayment payment: PKPayment,
                                             completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
         print("Payment authorized (Legacy delegate)")
         guard let slotToBook = timeSlotBeingBooked else {
             print("Error: timeSlotBeingBooked is nil (Legacy).")
             completion(.failure)
             return
         }
         guard let userId = Auth.auth().currentUser?.uid else {
             print("Error: User not logged in (Legacy).")
             completion(.failure)
             return
         }
         print("Attempting to book slot \(slotToBook.id) for user \(userId) (Legacy)")
         viewModel.bookTimeSlot(slotToBook, userId: userId)
         storePaymentTokenDetails(payment.token, for: slotToBook.id, userId: userId)
         completion(.success) // Let sheet proceed
     }
}
