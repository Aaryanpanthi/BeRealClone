//
//  AppDelegate.swift
//  BeRealClone
//
//  Created by Aaryan Panthi on 2/2/26.
//

import UIKit
import ParseSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("AppDelegate: didFinishLaunchingWithOptions started")
        print("🕵️ Runtime SceneDelegate Class: \(NSStringFromClass(SceneDelegate.self))")
        
        // Initialize Parse SDK
        // TODO: Update with your own Application ID and Client Key from Back4App
        ParseSwift.initialize(
            applicationId: "2X5l8r8DI47Utat3npF92iVYC6OpZ5l5RxG4X6Xk",
            clientKey: "L1B5TMsQm9nEm1JFrCZxepvlcUBdB2YU6KRkp1tD",
            serverURL: URL(string: "https://parseapi.back4app.com")!
        )
        
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
