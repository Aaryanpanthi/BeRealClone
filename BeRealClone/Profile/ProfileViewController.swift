//
//  ProfileViewController.swift
//  BeRealClone
//
//  Created by Aaryan Panthi on 2/9/26.
//

import UIKit
import ParseSwift

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        loadUserData()
    }
    
    private func loadUserData() {
        guard let user = User.current else { return }
        usernameTextField.text = user.username
        emailTextField.text = user.email
    }
    
    @IBAction func onSaveTapped(_ sender: UIButton) {
        guard var user = User.current else { return }
        
        let newUsername = usernameTextField.text ?? ""
        let newEmail = emailTextField.text ?? ""
        
        // Validate
        guard !newUsername.isEmpty else {
            showAlert(title: "Error", message: "Username cannot be empty")
            return
        }
        
        user.username = newUsername
        user.email = newEmail.isEmpty ? nil : newEmail
        
        // Show loading
        saveButton.isEnabled = false
        saveButton.setTitle("Saving...", for: .normal)
        
        user.save { [weak self] result in
            DispatchQueue.main.async {
                self?.saveButton.isEnabled = true
                self?.saveButton.setTitle("Save", for: .normal)
                
                switch result {
                case .success(let updatedUser):
                    print("✅ Profile updated: \(updatedUser)")
                    self?.showAlert(title: "Success", message: "Profile updated successfully") {
                        self?.navigationController?.popViewController(animated: true)
                    }
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
