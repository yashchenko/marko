//  TeacherListViewController.swift
//  Marko
//
//  Created by Ivan on 26.02.2025.
//

import UIKit

class TeacherListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout { // Add FlowLayout delegate
    private let viewModel: TeacherListViewModel
    private var collectionView: UICollectionView!
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    init(viewModel: TeacherListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Teachers"

        // Register for updates - make sure to refresh on main thread
        viewModel.onTeachersLoaded = { [weak self] in
            print("Teachers loaded notification received: \(self?.viewModel.teachers.count ?? 0) teachers")
            DispatchQueue.main.async {
                print("Reloading collection view data on main thread.")
                self?.loadingIndicator.stopAnimating() // Hide indicator
                self?.collectionView.reloadData()
                print("7. VIEW: ViewModel сообщил мне, что учителя готовы. Теперь я перезагружу коллекционный вид!")

            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("TeacherListViewController viewDidLoad")
        view.backgroundColor = .systemBackground // Use system color
        setupCollectionView()
        setupLoadingIndicator()
        loadingIndicator.startAnimating()
        print("1. VIEW: Экран со списком учителей загружен. Мне нужны учителя.")

        
        
        // Show indicator until data loads
        // Data loading is triggered in ViewModel's init
    }

     private func setupLoadingIndicator() {
         loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(loadingIndicator)
         NSLayoutConstraint.activate([
             loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
         ])
     }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        // Item size calculation will be handled by delegate method for responsiveness
        layout.minimumLineSpacing = 15
        layout.minimumInteritemSpacing = 15

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.register(TeacherCollectionViewCell.self, forCellWithReuseIdentifier: TeacherCollectionViewCell.reuseIdentifier) // Use static identifier
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear // Make background clear to see view's background
        collectionView.alwaysBounceVertical = true // Allow scrolling
        // Hide initially until data loads? Optional.
        // collectionView.isHidden = true

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        // Ensure indicator is above collection view
        view.bringSubviewToFront(loadingIndicator)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor) // Use safe area bottom
        ])

        print("CollectionView set up")
    }

    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = viewModel.teachers.count
        // collectionView.isHidden = count == 0 // Show/hide based on data
        return count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TeacherCollectionViewCell.reuseIdentifier, for: indexPath) as? TeacherCollectionViewCell else {
            fatalError("Failed to dequeue TeacherCollectionViewCell")
        }

        guard indexPath.item < viewModel.teachers.count else {
             print("⚠️ Error: Index path item \(indexPath.item) out of bounds for teachers count \(viewModel.teachers.count)")
             // Return the empty cell gracefully? Or maybe fatalError is better here?
             return cell // Return empty cell
         }

        let teacher = viewModel.teachers[indexPath.item]
        print("Configuring cell for teacher: \(teacher.name) at index \(indexPath.item)")
        cell.configure(with: teacher)
        return cell
    }

    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected cell at index \(indexPath.item)")
        guard indexPath.item < viewModel.teachers.count else {
             print("Error: Selected index out of bounds.")
             return
        }
        let teacher = viewModel.teachers[indexPath.item]
        viewModel.didSelectTeacher?(teacher)
    }

    // MARK: - UICollectionViewDelegateFlowLayout
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
         let padding: CGFloat = 20 // Horizontal padding for the section
         let interitemSpacing: CGFloat = 15 // Space between items on the same row (if multiple columns)
         // Calculate available width based on section insets
         let availableWidth = collectionView.bounds.width - (padding * 2)
         // Example: Single column layout
         let itemWidth = availableWidth
         // Example: Two column layout (adjust as needed)
         // let itemWidth = (availableWidth - interitemSpacing) / 2

         return CGSize(width: itemWidth, height: 100) // Fixed height, calculated width
     }

     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
         // Consistent padding around the whole section
         let padding: CGFloat = 20
         return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
     }

     // minimumLineSpacing is set on the layout object during setup
     // minimumInteritemSpacing is set on the layout object during setup
}
