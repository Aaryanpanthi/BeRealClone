//
//  PostCell.swift
//  BeRealClone
//
//  Created by Aaryan Panthi on 2/2/26.
//

import UIKit
import ParseSwift

protocol PostCellDelegate: AnyObject {
    func postCell(_ cell: PostCell, didTapLikeFor post: Post)
    func postCell(_ cell: PostCell, didSubmitComment text: String, for post: Post)
    func postCell(_ cell: PostCell, didTapDeleteFor post: Post)
    func postCell(_ cell: PostCell, didTapEditCaptionFor post: Post)
}

class PostCell: UITableViewCell {

    // Header outlets
    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var avatarLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var locationTimeLabel: UILabel!
    
    // Content outlets
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var blurView: UIVisualEffectView?
    @IBOutlet weak var captionLabel: UILabel!
    
    // Like row outlets
    @IBOutlet weak var likeButton: UIButton?
    @IBOutlet weak var likeCountLabel: UILabel?
    @IBOutlet weak var moreButton: UIButton?
    
    // Comments outlets
    @IBOutlet weak var commentsStackView: UIStackView?
    @IBOutlet weak var commentTextField: UITextField?
    
    weak var delegate: PostCellDelegate?
    private var imageDataRequest: URLSessionDataTask?
    private var currentPost: Post?
    private var comments: [Comment] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAvatarView()
    }
    
    private func setupAvatarView() {
        avatarView?.layer.cornerRadius = 20
        avatarView?.clipsToBounds = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        postImageView.image = nil
        imageDataRequest?.cancel()
        currentPost = nil
        comments = []
        clearCommentsStack()
    }
    
    private func clearCommentsStack() {
        commentsStackView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    func configure(with post: Post, comments: [Comment] = []) {
        currentPost = post
        self.comments = comments
        
        // Avatar - show first letter of username
        if let user = post.user {
            usernameLabel.text = user.username
            let initial = String(user.username?.prefix(1) ?? "?").uppercased()
            avatarLabel?.text = initial
        }
        
        // Location + Time combined (like "San Francisco, SOMA, 21hr late")
        var locationTimeText = ""
        if let location = post.location, !location.isEmpty {
            locationTimeText = location
        }
        if let date = post.createdAt {
            let timeAgo = timeAgoString(from: date)
            if !locationTimeText.isEmpty {
                locationTimeText += ", \(timeAgo)"
            } else {
                locationTimeText = timeAgo
            }
        }
        locationTimeLabel?.text = locationTimeText

        // Caption
        captionLabel.text = post.caption
        
        // Like Button
        updateLikeUI(for: post)
        
        // Comments
        displayComments(comments)
        
        // Show/hide more button for own posts
        let isOwnPost = post.user?.objectId == User.current?.objectId
        moreButton?.isHidden = !isOwnPost
        
        // Image
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {
            
            imageDataRequest = URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
                guard let data = data, error == nil, let image = UIImage(data: data) else {
                    print("❌ Error fetching image: \(String(describing: error))")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.postImageView.image = image
                }
            }
            imageDataRequest?.resume()
        }
        
        // Blur View Logic
        configureBlur(for: post)
    }
    
    private func configureBlur(for post: Post) {
        guard let blurView = blurView else { return }

        if let currentUser = User.current,
           let lastPostedDate = currentUser.lastPostedDate,
           let postCreatedDate = post.createdAt,
           let diffHours = Calendar.current.dateComponents([.hour], from: postCreatedDate, to: lastPostedDate).hour {
            blurView.isHidden = abs(diffHours) < 24
        } else {
            blurView.isHidden = false
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let mins = seconds / 60
            return "\(mins)min ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)hr late"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
    
    private func displayComments(_ comments: [Comment]) {
        clearCommentsStack()
        
        let displayComments = Array(comments.prefix(3))
        
        for comment in displayComments {
            let commentLabel = UILabel()
            commentLabel.numberOfLines = 0
            commentLabel.font = UIFont.systemFont(ofSize: 14)
            
            let username = comment.user?.username ?? "Unknown"
            let text = comment.text ?? ""
            
            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(
                string: "\(username) ",
                attributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.white]
            ))
            attributedString.append(NSAttributedString(
                string: text,
                attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]
            ))
            
            commentLabel.attributedText = attributedString
            commentsStackView?.addArrangedSubview(commentLabel)
        }
        
        if comments.count > 3 {
            let moreLabel = UILabel()
            moreLabel.font = UIFont.systemFont(ofSize: 14)
            moreLabel.textColor = .gray
            moreLabel.text = "View all \(comments.count) comments"
            commentsStackView?.addArrangedSubview(moreLabel)
        }
    }
    
    private func updateLikeUI(for post: Post) {
        let likedBy = post.likedBy ?? []
        let likeCount = likedBy.count
        
        let isLiked = User.current?.objectId != nil && likedBy.contains(User.current!.objectId!)
        
        let imageName = isLiked ? "heart.fill" : "heart"
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        likeButton?.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
        likeButton?.tintColor = isLiked ? .systemRed : .white
        
        if likeCount > 0 {
            likeCountLabel?.text = "\(likeCount)"
        } else {
            likeCountLabel?.text = ""
        }
    }
    
    // MARK: - Heart Animation
    private func animateHeartButton() {
        guard let likeButton = likeButton else { return }
        
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut) {
            likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        } completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.8) {
                likeButton.transform = .identity
            }
        }
    }
    
    @IBAction func onLikeTapped(_ sender: UIButton) {
        guard let post = currentPost else { return }
        animateHeartButton()
        delegate?.postCell(self, didTapLikeFor: post)
    }
    
    @IBAction func onMoreTapped(_ sender: UIButton) {
        guard let post = currentPost else { return }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Edit Caption", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.postCell(self, didTapEditCaptionFor: post)
        })
        
        alert.addAction(UIAlertAction(title: "Delete Post", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.postCell(self, didTapDeleteFor: post)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let viewController = self.window?.rootViewController?.presentedViewController ?? self.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    @IBAction func onCommentSubmit(_ sender: UITextField) {
        guard let post = currentPost,
              let text = sender.text,
              !text.isEmpty else { return }
        
        delegate?.postCell(self, didSubmitComment: text, for: post)
        sender.text = ""
        sender.resignFirstResponder()
    }
}
