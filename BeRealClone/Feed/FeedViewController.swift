//
//  FeedViewController.swift
//  BeRealClone
//
//  Created by Aaryan Panthi on 2/2/26.
//

import UIKit
import ParseSwift

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    private var queryLimit = 10
    
    var posts = [Post]() {
        didSet {
            // Reload table view data whenever posts change
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false

        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
        tableView.insertSubview(refreshControl, at: 0)

        // Add Log Out button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log Out", style: .plain, target: self, action: #selector(onLogoutTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        queryPosts()
    }
    
    private func queryPosts(completion: (() -> Void)? = nil) {
        // 1. Create a query to fetch Posts
        // 2. Any properties that are Parse objects are stored by reference in Parse DB and as such need to explicitly use `include_:)` to be included in query results.
        // 3. Sort the posts by descending order based on the created at date
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .limit(queryLimit)

        // Fetch objects (posts) defined in query (async)
        query.find { [weak self] result in
            switch result {
            case .success(let posts):
                // Update local posts property with fetched posts
                self?.posts = posts
                completion?()
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
        }
    }

    @objc private func onPullToRefresh() {
        queryLimit = 10 // Reset limit on refresh
        queryPosts { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    @objc private func onLogoutTapped() {
        User.logout { [weak self] result in
            switch result {
            case .success:
                NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
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
        cell.configure(with: posts[indexPath.row])
        return cell
    }
    
    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}
