//
//  TeacherListViewController.swift
//  Marko
//
//  Created by Ivan on 26.02.2025.
//

import UIKit

class TeacherListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    private let viewModel: TeacherListViewModel
    private var collectionView: UICollectionView!
    
    init(viewModel: TeacherListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.title = "Teachers"
        
        // Register for updates - make sure to refresh on main thread
        viewModel.onTeachersLoaded = { [weak self] in
            print("Teachers loaded notification received: \(self?.viewModel.teachers.count ?? 0) teachers")
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TeacherListViewController viewDidLoad")
        view.backgroundColor = .white
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        // Create a layout that works well
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width - 40, height: 120) // Ensure cells are visible
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        layout.minimumLineSpacing = 20
        
        // Create collection view with explicit frame and layout
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.register(TeacherCollectionViewCell.self, forCellWithReuseIdentifier: "TeacherCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground // Use system colors
        
        // Add collection view to view hierarchy with auto layout
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add debugging border to see if collection view is visible
        collectionView.layer.borderWidth = 1
        collectionView.layer.borderColor = UIColor.red.cgColor
        
        print("CollectionView set up with bounds: \(collectionView.bounds)")
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = viewModel.teachers.count
        print("Number of teachers to display: \(count)")
        return count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("Configuring cell at index \(indexPath.item)")
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeacherCell", for: indexPath) as? TeacherCollectionViewCell else {
            print("Failed to dequeue TeacherCell")
            return UICollectionViewCell()
        }
        
        let teacher = viewModel.teachers[indexPath.item]
        print("Configuring cell with teacher: \(teacher.name)")
        cell.configure(with: teacher)
        
        // Add debugging border to see if cells are visible
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.borderColor = UIColor.blue.cgColor
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected cell at index \(indexPath.item)")
        let teacher = viewModel.teachers[indexPath.item]
        viewModel.didSelectTeacher?(teacher)
    }
}
