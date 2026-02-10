//
//  FeedViewController.swift
//  BeRealClone
//
//  Created by Aaryan Panthi on 2/2/26.
//

import UIKit
import ParseSwift

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PostCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    private var queryLimit = 10
    private var suppressReload = false
    
    var posts = [Post]() {
        didSet {
            if !suppressReload {
                tableView.reloadData()
            }
        }
    }
    
    // Store comments for each post
    private var postComments: [String: [Comment]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.rowHeight = 520  // BeReal-style layout height

        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        queryPosts()
    }
    
    private func queryPosts(completion: (() -> Void)? = nil) {
        guard let yesterdayDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
             return
        }
        
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .where("createdAt" >= yesterdayDate)
            .limit(queryLimit)

        query.find { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let posts):
                    self?.posts = posts
                    // Fetch comments for each post
                    self?.fetchCommentsForPosts(posts)
                    completion?()
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
    
    private func fetchCommentsForPosts(_ posts: [Post]) {
        for post in posts {
            guard let postId = post.objectId else { continue }
            
            let query = Comment.query()
                .include("user")
                .where("post" == Pointer<Post>(objectId: postId))
                .order([.descending("createdAt")])
                .limit(10)
            
            query.find { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let comments):
                        self?.postComments[postId] = comments
                        // Reload the specific row
                        if let index = self?.posts.firstIndex(where: { $0.objectId == postId }) {
                            self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        }
                    case .failure(let error):
                        print("❌ Failed to fetch comments: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    @objc private func onPullToRefresh() {
        queryLimit = 10
        postComments = [:]
        queryPosts { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    @IBAction func onLogOutTapped(_ sender: Any) {
        User.logout { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Successfully logged out")
                    NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func onProfileTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let profileVC = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController {
            navigationController?.pushViewController(profileVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == posts.count && posts.count >= queryLimit {
            queryLimit += 10
            queryPosts()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }
        let post = posts[indexPath.row]
        let comments = postComments[post.objectId ?? ""] ?? []
        cell.configure(with: post, comments: comments)
        cell.delegate = self
        return cell
    }
    
    // MARK: - PostCellDelegate
    
    func postCell(_ cell: PostCell, didTapLikeFor post: Post) {
        guard let currentUserId = User.current?.objectId,
              let postIndex = posts.firstIndex(where: { $0.objectId == post.objectId }) else {
            return
        }
        
        var updatedPost = post
        var likedBy = updatedPost.likedBy ?? []
        
        if likedBy.contains(currentUserId) {
            likedBy.removeAll { $0 == currentUserId }
        } else {
            likedBy.append(currentUserId)
        }
        
        updatedPost.likedBy = likedBy
        
        // Optimistically update UI immediately
        suppressReload = true
        posts[postIndex] = updatedPost
        suppressReload = false
        tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: .none)
        
        updatedPost.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedPost):
                    guard let self = self else { return }
                    self.suppressReload = true
                    self.posts[postIndex] = savedPost
                    self.suppressReload = false
                    self.tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: .none)
                case .failure(let error):
                    print("❌ Failed to save like: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func postCell(_ cell: PostCell, didSubmitComment text: String, for post: Post) {
        guard let postId = post.objectId else { return }
        
        var comment = Comment()
        comment.text = text
        comment.user = User.current
        comment.post = Pointer<Post>(objectId: postId)
        
        // Keep a reference to the current user for display purposes
        let currentUser = User.current
        
        comment.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(var savedComment):
                    print("✅ Comment saved!")
                    // The saved comment from Parse may not include the full user object,
                    // so we restore it for immediate display in the UI.
                    if savedComment.user == nil || savedComment.user?.username == nil {
                        savedComment.user = currentUser
                    }
                    // Add to local cache and reload
                    var comments = self?.postComments[postId] ?? []
                    comments.insert(savedComment, at: 0)
                    self?.postComments[postId] = comments
                    
                    if let index = self?.posts.firstIndex(where: { $0.objectId == postId }) {
                        self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                    }
                case .failure(let error):
                    print("❌ Failed to save comment: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func postCell(_ cell: PostCell, didTapDeleteFor post: Post) {
        let alert = UIAlertController(title: "Delete Post", message: "Are you sure you want to delete this post?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePost(post)
        })
        
        present(alert, animated: true)
    }
    
    private func deletePost(_ post: Post) {
        post.delete { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Post deleted!")
                    self?.posts.removeAll { $0.objectId == post.objectId }
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
    
    func postCell(_ cell: PostCell, didTapEditCaptionFor post: Post) {
        let alert = UIAlertController(title: "Edit Caption", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = post.caption
            textField.placeholder = "Enter new caption"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let newCaption = alert.textFields?.first?.text else { return }
            self?.updatePostCaption(post, newCaption: newCaption)
        })
        
        present(alert, animated: true)
    }
    
    private func updatePostCaption(_ post: Post, newCaption: String) {
        var updatedPost = post
        updatedPost.caption = newCaption
        
        updatedPost.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let savedPost):
                    print("✅ Caption updated!")
                    if let index = self?.posts.firstIndex(where: { $0.objectId == post.objectId }) {
                        self?.posts[index] = savedPost
                    }
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }
    
    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}
