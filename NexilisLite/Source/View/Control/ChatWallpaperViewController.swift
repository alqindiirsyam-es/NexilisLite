//
//  ChatWallpaperViewController.swift
//  NexilisLite
//
//  Created by Maronakins on 13/03/25.
//

import Foundation
import UIKit
import PhotosUI

class ChatWallpaperViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, PHPickerViewControllerDelegate {

    // MARK: - Properties
    private let wallpapers: [UIImage] = {
        let imageNames = ["pb_chatwp1", "pb_chatwp2", "pb_chatwp3", "pb_chatwp4", "pb_chatwp5", "pb_chatwp6", "pb_chatwp7", "pb_chatwp8", "pb_chatwp9", "pb_chatwp10", "pb_chatwp11", "pb_chatwp12"]
        return imageNames.compactMap { UIImage(named: $0, in: Bundle.resourceBundle(for: Nexilis.self), with: nil) }
    }() // Add your predefined wallpapers here

    private var selectedWallpaper: UIImage?
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Choose Wallpaper"

        // Configure Collection View
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WallpaperCell.self, forCellWithReuseIdentifier: WallpaperCell.identifier)
        collectionView.backgroundColor = .clear

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 120, height: 200)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        collectionView.collectionViewLayout = layout

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120)
        ])

        // Add Custom Wallpaper Button
        let customWallpaperButton = UIButton(type: .system)
        customWallpaperButton.setTitle("Choose Custom Wallpaper", for: .normal)
        customWallpaperButton.addTarget(self, action: #selector(openPhotoLibrary), for: .touchUpInside)
        customWallpaperButton.backgroundColor = .systemBlue
        customWallpaperButton.setTitleColor(.white, for: .normal)
        customWallpaperButton.layer.cornerRadius = 8

        view.addSubview(customWallpaperButton)
        customWallpaperButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            customWallpaperButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            customWallpaperButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            customWallpaperButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            customWallpaperButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Add Clear Wallpaper Button
        let clearWallpaperButton = UIButton(type: .system)
        clearWallpaperButton.setTitle("Clear Wallpaper", for: .normal)
        clearWallpaperButton.addTarget(self, action: #selector(clearWallpaper), for: .touchUpInside)
        clearWallpaperButton.backgroundColor = .systemRed
        clearWallpaperButton.setTitleColor(.white, for: .normal)
        clearWallpaperButton.layer.cornerRadius = 8

        view.addSubview(clearWallpaperButton)
        clearWallpaperButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            clearWallpaperButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            clearWallpaperButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clearWallpaperButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            clearWallpaperButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add a back button
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
        
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }

    // MARK: - Collection View Data Source
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return wallpapers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WallpaperCell.identifier, for: indexPath) as! WallpaperCell
        cell.configure(with: wallpapers[indexPath.item])
        return cell
    }

    // MARK: - Collection View Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedWallpaper = wallpapers[indexPath.item]
        saveAndDismiss()
    }

    // MARK: - Custom Wallpaper Selection
    @objc private func openPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.selectedWallpaper = image
                    self?.saveAndDismiss()
                }
            }
        }
    }
    
    // MARK: - Clear Wallpaper
    @objc private func clearWallpaper() {
        // Clear the saved wallpaper
        UserDefaults.standard.removeObject(forKey: "chatWallpaper")

        // Notify the chat view to update the wallpaper
        NotificationCenter.default.post(name: Notification.Name("WallpaperDidChange"), object: nil)

        // Dismiss the view controller
        dismiss(animated: true)
    }

    // MARK: - Save and Dismiss
    private func saveAndDismiss() {
        guard let selectedWallpaper = selectedWallpaper else { return }

        // Save the selected wallpaper (e.g., to UserDefaults or a shared data model)
        UserDefaults.standard.set(selectedWallpaper.pngData(), forKey: "chatWallpaper")

        // Notify the chat view to update the wallpaper
        NotificationCenter.default.post(name: Notification.Name("WallpaperDidChange"), object: nil)

        // Dismiss the view controller
        dismiss(animated: true)
    }
}

// MARK: - Wallpaper Cell
class WallpaperCell: UICollectionViewCell {
    static let identifier = "WallpaperCell"

    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with image: UIImage) {
        imageView.image = image
    }
}
