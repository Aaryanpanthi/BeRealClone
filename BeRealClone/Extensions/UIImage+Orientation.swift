//
//  UIImage+Orientation.swift
//  BeRealClone
//
//  Created by Aaryan Panthi on 2/9/26.
//

import UIKit

extension UIImage {
    /// Returns a new image with the orientation baked into the pixel data.
    /// This fixes the common iOS issue where camera photos have EXIF orientation
    /// metadata that isn't always respected when the image is loaded from a URL.
    func normalizedOrientation() -> UIImage? {
        // If the orientation is already correct, return self
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}
