//
//  AppDelegate.swift
//  Marko
//
//  Created by Ivan on 24.02.2025.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Ensure Firebase is only configured once.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Initialize auth service after Firebase is configured.
        let _ = AuthService.shared

        // --- TEMPORARY HACK TO SIGN OUT (keep only for local testing) ---
        #if DEBUG
        do {
            try Auth.auth().signOut()
            print("Successfully signed out on launch for testing.")
        } catch {
            print("Error signing out on launch: \(error.localizedDescription)")
        }
        #endif
        // ------------------------------------

        return true
    }


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

