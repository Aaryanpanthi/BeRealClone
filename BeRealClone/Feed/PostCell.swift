//
//  PostCell.swift
//  BeRealClone
//
//  Created by Aaryan Panthi on 2/2/26.
//

import UIKit
import ParseSwift

class PostCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var blurView: UIVisualEffectView! // For BeReal reveal effect if needed later
    
    private var imageDataRequest: URLSessionDataTask?

    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset image view image.
        postImageView.image = nil

        // Cancel image request.
        imageDataRequest?.cancel()
    }

    func configure(with post: Post) {
        // Username
        if let user = post.user {
            usernameLabel.text = user.username
        }

        // Caption
        captionLabel.text = post.caption

        // Date
        if let date = post.createdAt {
            dateLabel.text = DateFormatter.beRealPostFormatter.string(from: date)
        }
        
        // Image
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {
            
            // Use native URLSession to fetch remote image from URL
            imageDataRequest = URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
                guard let data = data, error == nil, let image = UIImage(data: data) else {
                    print("❌ Error fetching image: \(String(describing: error))")
                    return
                }
                
                DispatchQueue.main.async {
                    // Start with a generic transition or just set it
                    self?.postImageView.image = image
                }
            }
            imageDataRequest?.resume()
        }
    }
}

