//
//  SceneDelegate.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 10/29/22.
//

import UIKit
import ParseSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    private enum Constants {
        static let loginNavigationControllerIdentifier = "LoginNavigationController"
        static let feedNavigationControllerIdentifier = "FeedNavigationController"
        static let storyboardIdentifier = "Main"
    }

    var window: UIWindow?
    private var loginObserver: NSObjectProtocol?
    private var logoutObserver: NSObjectProtocol?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("🕵️ SceneDelegate: scene willConnectTo session")
        // Ensure we have a valid UIWindowScene and create the window explicitly so
        // snapshotting/scene transitions have a valid window to work with.
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Create the window and attach to the provided scene.
        let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // If a user is already cached, show feed; otherwise show login.
        if User.current != nil {
            print("🕵️ SceneDelegate: User is logged in. Setting root to FeedNavigationController")
            window.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.feedNavigationControllerIdentifier)
        } else {
            print("🕵️ SceneDelegate: User is NOT logged in. Setting root to LoginNavigationController")
            window.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.loginNavigationControllerIdentifier)
        }

        // Make the window visible and ensure it's the key window.
        window.makeKeyAndVisible()
        print("🕵️ SceneDelegate: Window made key and visible")

        // Add observers and keep tokens so we can remove them later.
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name("login"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.login()
        }

        logoutObserver = NotificationCenter.default.addObserver(forName: Notification.Name("logout"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.logOut()
        }

        // Note: we've already handled persisted login above by setting the root VC.
    }

    private func login() {
        // Ensure UI updates are performed on the main thread.
        DispatchQueue.main.async { [weak self] in
            let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
            self?.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.feedNavigationControllerIdentifier)
            self?.window?.makeKeyAndVisible()
        }
    }

    private func logOut() {
        // Log out Parse user.
        // This will also remove the session from the Keychain, log out of linked services and all future calls to current will return nil.
        User.logout { [weak self] result in

            switch result {
            case .success:

                // Make sure UI updates are done on main thread when initiated from background thread.
                DispatchQueue.main.async {

                    // Instantiate the storyboard that contains the view controller you want to go to (i.e. destination view controller).
                    let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)

                    // Instantiate the destination view controller (in our case it's a navigation controller) from the storyboard.
                    let viewController = storyboard.instantiateViewController(withIdentifier: Constants.loginNavigationControllerIdentifier)

                    // Programmatically set the current displayed view controller.
                    self?.window?.rootViewController = viewController
                    self?.window?.makeKeyAndVisible()
                }
            case .failure(let error):
                print("❌ Log out error: \(error)")
            }
        }

    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Remove observers to avoid dangling UI updates after the scene is disconnected.
        if let loginObserver = loginObserver {
            NotificationCenter.default.removeObserver(loginObserver)
            self.loginObserver = nil
        }
        if let logoutObserver = logoutObserver {
            NotificationCenter.default.removeObserver(logoutObserver)
            self.logoutObserver = nil
        }

        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
