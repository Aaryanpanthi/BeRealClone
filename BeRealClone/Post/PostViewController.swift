//
//  PostViewController.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/1/22.
//

import UIKit
import PhotosUI
import ParseSwift
import CoreLocation

class PostViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: Outlets
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!

    private var pickedImage: UIImage?
    private var pickedLocation: String?
    private let geocoder = CLGeocoder()
    private var hasShownPicker = false
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Auto-open camera/photo picker on first appearance
        if !hasShownPicker && pickedImage == nil {
            hasShownPicker = true
            showImageSourcePicker()
        }
    }
    
    private func showImageSourcePicker() {
        let alert = UIAlertController(title: "Choose Image Source", message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.showCamera()
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.showPhotoLibrary()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(cameraAction)
        }
        alert.addAction(libraryAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        showImageSourcePicker()
    }
    
    private func showCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    private func showPhotoLibrary() {
        // Request photo library access first
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    self?.presentPhotoPicker()
                } else {
                    self?.showAlert(description: "Please allow photo library access in Settings to select photos with location data.")
                }
            }
        }
    }
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @IBAction func onShareTapped(_ sender: Any) {
        view.endEditing(true)

        guard let image = pickedImage,
              let normalizedImage = image.normalizedOrientation(),
              let imageData = normalizedImage.jpegData(compressionQuality: 0.5) else {
            return
        }

        // Disable share button to prevent double-tap
        shareButton.isEnabled = false

        var imageFile = ParseFile(name: "image.jpg", data: imageData)

        // Step 1: Save the file to Parse first
        imageFile.save { [weak self] result in
            switch result {
            case .success(let savedFile):
                print("✅ File Saved!")

                // Step 2: Create the post with the saved file reference
                var post = Post()
                post.imageFile = savedFile
                post.caption = self?.captionTextField.text
                post.user = User.current
                post.location = self?.pickedLocation

                post.save { [weak self] result in
                    switch result {
                    case .success(let post):
                        print("✅ Post Saved! \(post)")

                        if var currentUser = User.current {
                            currentUser.lastPostedDate = Date()

                            currentUser.save { [weak self] result in
                                switch result {
                                case .success(let user):
                                    print("✅ User Saved! \(user)")
                                    DispatchQueue.main.async {
                                        self?.navigationController?.popViewController(animated: true)
                                    }

                                case .failure(let error):
                                    DispatchQueue.main.async {
                                        self?.shareButton.isEnabled = true
                                        self?.showAlert(description: error.localizedDescription)
                                    }
                                }
                            }
                        }

                    case .failure(let error):
                        DispatchQueue.main.async {
                            self?.shareButton.isEnabled = true
                            self?.showAlert(description: error.localizedDescription)
                        }
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    self?.shareButton.isEnabled = true
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    @IBAction func onViewTapped(_ sender: Any) {
        view.endEditing(true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    
    // MARK: - Photo Metadata
    private func extractLocation(from asset: PHAsset) {
        guard let location = asset.location else {
            print("📍 No location data in photo metadata")
            return
        }
        
        reverseGeocodeLocation(location)
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                print("❌ Geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                let locationString = [placemark.locality, placemark.administrativeArea, placemark.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                
                DispatchQueue.main.async {
                    self?.pickedLocation = locationString
                    print("📍 Location extracted: \(locationString)")
                }
            }
        }
    }
    
    private func useCurrentLocation() {
        guard let location = currentLocation else {
            print("📍 No current location available")
            return
        }
        
        reverseGeocodeLocation(location)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }
        
        // Get asset identifier for location metadata
        if let assetIdentifier = result.assetIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            if let asset = fetchResult.firstObject {
                extractLocation(from: asset)
                print("📍 Found PHAsset with identifier: \(assetIdentifier)")
            } else {
                print("📍 Could not fetch PHAsset")
            }
        } else {
            print("📍 No asset identifier available - using current location as fallback")
            useCurrentLocation()
        }
        
        // Load the image
        guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
           guard let image = object as? UIImage else {
              self?.showAlert()
              return
           }

           if let error = error {
               self?.showAlert(description: error.localizedDescription)
              return
           }
            
           DispatchQueue.main.async {
              let normalizedImage = image.normalizedOrientation() ?? image
              self?.previewImageView.image = normalizedImage
              self?.pickedImage = normalizedImage
           }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.editedImage] as? UIImage else {
            print("❌ No image found")
            return
        }

        let normalizedImage = image.normalizedOrientation() ?? image
        previewImageView.image = normalizedImage
        pickedImage = normalizedImage
        
        // For camera photos, use the current device location
        useCurrentLocation()
        print("📍 Camera photo - using current location")
    }
}
