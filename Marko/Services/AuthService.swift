// file: Services/AuthService.swift

import Foundation
import Firebase

class AuthService {
    
    // AC #2: A singleton instance, accessible from anywhere.
    static let shared = AuthService()
    
    // This holds the current user. It can only be set by this file.
    private(set) var currentUser: FirebaseAuth.User?
    
    // This stores a reference to the listener so we can detach it if needed.
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    // AC #4: The notification mechanism. A closure that passes the user object.
    var onAuthStateChanged: ((FirebaseAuth.User?) -> Void)?
    
    // A private initializer enforces the singleton pattern.
    private init() {
        // AC #3: Add the state listener when the service is initialized.
        // [weak self] prevents a memory leak.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            // This code runs every time a user signs in or out.
            self?.currentUser = user
            self?.onAuthStateChanged?(user)
            print("AuthService: Auth state changed. User is now \(user?.uid ?? "Signed Out").")
        }
    }
    
    // A simple helper property to check if a user is signed in.
    var isSignedIn: Bool {
        return currentUser != nil
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
