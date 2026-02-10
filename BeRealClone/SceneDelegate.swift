//
//  SceneDelegate.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 10/29/22.
//

import UIKit
import ParseSwift
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private enum Constants {
        static let loginNavigationControllerIdentifier = "LoginNavigationController"
        static let feedNavigationControllerIdentifier = "FeedNavigationController"
        static let storyboardIdentifier = "Main"
        static let notificationIdentifier = "bereal-reminder"
    }

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        // Add observers
        NotificationCenter.default.addObserver(forName: Notification.Name("login"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.login()
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("logout"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.logOut()
        }

        // Check for cached user for persisted log in.
        if User.current != nil {
            print("🕵️ SceneDelegate: User is logged in. Setting root to FeedNavigationController")
            let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
            window?.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.feedNavigationControllerIdentifier)
            
            // Schedule notification reminder for returning users
            scheduleNotificationReminder()
        } else {
             print("🕵️ SceneDelegate: User is NOT logged in. Defaulting to Storyboard entry.")
        }
    }

    private func login() {
        DispatchQueue.main.async { [weak self] in
            let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
            self?.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.feedNavigationControllerIdentifier)
            self?.window?.makeKeyAndVisible()
            
            // Request notification permissions and schedule reminder
            self?.requestNotificationPermissions()
        }
    }

    private func logOut() {
        // Remove pending notifications on logout
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Constants.notificationIdentifier])
        print("🔔 Notifications unregistered")
        
        // User.logout is already called by FeedViewController before posting this notification.
        // SceneDelegate only needs to handle the navigation transition.
        DispatchQueue.main.async { [weak self] in
            let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: Constants.loginNavigationControllerIdentifier)
            self?.window?.rootViewController = viewController
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
                return
            }
            
            if granted {
                print("✅ Notification permission granted")
                self?.scheduleNotificationReminder()
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    private func scheduleNotificationReminder() {
        let content = UNMutableNotificationContent()
        content.title = "⚡️ Time to BeReal!"
        content.body = "Share what you're doing right now with your friends."
        content.sound = .default
        
        // Trigger every 4 hours
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 60 * 60, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: Constants.notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Remove any existing notification before scheduling new one
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Constants.notificationIdentifier])
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("🔔 Notification reminder scheduled")
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
