//
//  File.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit

class TeacherDetailViewModel {
    let teacher: Teacher
    private let timeSlotRepository = TimeSlotRepository()
    private(set) var availableTimeSlots: [TimeSlot] = []
    
    // Callback for when time slots are loaded
    var onTimeSlotsLoaded: (([TimeSlot]) -> Void)?
    
    // Callback for when booking is completed
    var onBookingCompleted: ((Bool, TimeSlot) -> Void)?
    
    init(teacher: Teacher) {
        self.teacher = teacher
    }
    
    // Load all available time slots for this teacher
    func loadAvailableTimeSlots() {
        timeSlotRepository.fetchTimeSlots(for: teacher.id) { [weak self] timeSlots in
            guard let self = self else { return }
            
            // Filter to only include non-booked slots in the future
            let now = Date()
            self.availableTimeSlots = timeSlots.filter { !$0.isBooked && $0.startTime > now }
            
            // Sort by start time
            self.availableTimeSlots.sort { $0.startTime < $1.startTime }
            
            // Notify listeners
            self.onTimeSlotsLoaded?(self.availableTimeSlots)
        }
    }
    
    // Load time slots for a specific date
    func loadTimeSlots(for date: Date) {
        timeSlotRepository.fetchTimeSlots(for: teacher.id, on: date) { [weak self] timeSlots in
            guard let self = self else { return }
            
            // Filter to only include non-booked slots in the future
            let now = Date()
            self.availableTimeSlots = timeSlots.filter { !$0.isBooked && $0.startTime > now }
            
            // Sort by start time
            self.availableTimeSlots.sort { $0.startTime < $1.startTime }
            
            // Notify listeners
            self.onTimeSlotsLoaded?(self.availableTimeSlots)
        }
    }
    
    // Book a time slot
    func bookTimeSlot(_ timeSlot: TimeSlot, userId: String) {
        timeSlotRepository.bookTimeSlot(timeSlot, userId: userId) { [weak self] success in
            guard let self = self else { return }
            
            // Notify listeners of booking result
            self.onBookingCompleted?(success, timeSlot)
            
            // If successful, refresh time slots
            if success {
                self.loadAvailableTimeSlots()
            }
        }
    }
    
    // Add sample time slots (for testing)
    func addSampleTimeSlots(completion: @escaping () -> Void) {
        timeSlotRepository.addSampleTimeSlots(for: teacher.id, completion: completion)
    }
}
