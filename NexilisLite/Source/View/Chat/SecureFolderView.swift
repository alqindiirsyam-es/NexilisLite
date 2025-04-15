//
//  SecureFolderView.swift
//  NexilisLite
//
//  Created by Maronakins on 06/12/24.
//

import UIKit
import AVFoundation
import AVKit
import QuickLook

class SecureFolderViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, QLPreviewControllerDataSource {
    
    var directoryPath: URL!
    var files: [SecureFolderItem] = []
    var filteredFiles: [SecureFolderItem] = []
    var previewItem: NSURL?
    
    let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search files"
        return sb
    }()
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.register(FileCell.self, forCellWithReuseIdentifier: "FileCell")
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Secure Folder"
        view.backgroundColor = .white
        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16.0), NSAttributedString.Key.foregroundColor: UIColor.white]
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = self.traitCollection.userInterfaceStyle == .dark ? .blackDarkMode : UIColor.mainColor
        navBarAppearance.titleTextAttributes = attributes
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(cancel(sender:)))
        
        setupSubviews()
        loadFiles()
        filteredFiles = files
    }
    
    @objc func cancel(sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func getThumbnail(for fileName: String) -> UIImage? {
        // Logic to get the file thumbnail if it exists.
        // This could include generating a thumbnail from the actual file.
        // Placeholder image is used here as an example.
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            let thumbURL = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
            return UIImage(contentsOfFile: thumbURL.path) ?? UIImage(systemName: "photo")?.withTintColor(.black)
        }
        return UIImage(systemName: "text.document.fill")?.withTintColor(.black) // Replace with actual thumbnail logic
    }

    func setupSubviews() {
        // Add search bar
        searchBar.delegate = self
        view.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Add collection view
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func loadFiles() {
        do {
            var query = "SELECT audio_id, video_id, image_id, thumb_id, file_id, attachment_flag, status, server_date FROM MESSAGE where (video_id IS NOT NULL AND video_id != '') OR (image_id IS NOT NULL AND image_id != '') OR (file_id IS NOT NULL AND file_id != '') order by server_date asc"
            Database.shared.database?.inTransaction({ (fmdb, rollback) in
                do {
                    if let cursorData = Database.shared.getRecords(fmdb: fmdb, query: query) {
                        while cursorData.next() {
                            var fileName = ""
                            let audioId = cursorData.string(forColumn: "audio_id") ?? ""
                            let videoId = cursorData.string(forColumn: "video_id") ?? ""
                            let imageId = cursorData.string(forColumn: "image_id") ?? ""
                            let thumbId = cursorData.string(forColumn: "thumb_id") ?? ""
                            let fileId = cursorData.string(forColumn: "file_id") ?? ""
                            let attachmentFlag = cursorData.string(forColumn: "attachment_flag") ?? ""
                            let status = cursorData.string(forColumn: "status") ?? ""
                            let serverDate = cursorData.string(forColumn: "server_date") ?? ""
                            if imageId != "" {
                                fileName = imageId
                            }
                            else if videoId != "" {
                                fileName = videoId
                            }
                            else if fileId != "" {
                                fileName = fileId
                            }
                            else if audioId != "" {
                                fileName = audioId
                            }
                            if FileEncryption.shared.isSecureExists(filename: fileName) {
                                let secureFolderItem = SecureFolderItem(audioId: audioId, videoId: videoId, imageId: imageId, fileId: fileId, thumbId: thumbId, attachmentFlag: attachmentFlag, serverDate: serverDate, status: status, filename: fileName)
                                files.append(secureFolderItem)
                            }
                        }
                        cursorData.close()
                    }
                }
                catch {
                    rollback.pointee = true
                    print("Access database error: \(error.localizedDescription)")
                }
            })
        } catch {
            print("Error loading files: \(error.localizedDescription)")
        }
    }

    // MARK: Search Bar Delegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredFiles = searchText.isEmpty ? files : files.filter { $0.filename.contains(searchText) }
        collectionView.reloadData()
    }
    
    // MARK: Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileCell", for: indexPath) as! FileCell
        let fileItem = filteredFiles[indexPath.item]
        cell.label.text = fileItem.filename
        cell.imageView.tintColor = .black
        cell.imageView.sizeThatFits(CGSize(width: 200.0, height: 200.0))
        var thumbnailImage = UIImage(systemName: "doc.text")?.withTintColor(.black)
        if fileItem.thumbId != "" {
            thumbnailImage = getThumbnail(for: fileItem.thumbId)
        } else if fileItem.audioId != "" {
            thumbnailImage = UIImage(systemName: "speaker.wave.3")?.withTintColor(.black)
        }
        cell.imageView.image = thumbnailImage

        return cell
    }
    
    // MARK: Collection View Delegate Flow Layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 10
        let collectionViewSize = collectionView.frame.size.width - padding
        let width = collectionViewSize / 2
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let fileItem = filteredFiles[indexPath.item]
        if fileItem.imageId != "" {
            print("this image")
            do {
                if var data = try FileEncryption.shared.readSecure(filename: fileItem.filename) {
                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: data)
                    if dataDecrypt != nil {
                        data = dataDecrypt!
                    }
                    let image = UIImage(data: data)
                    let previewImageVC = PreviewAttachmentImageVideo(nibName: "PreviewAttachmentImageVideo", bundle: Bundle.resourceBundle(for: Nexilis.self))
                    previewImageVC.image = image
                    previewImageVC.isHiddenTextField = true
                    previewImageVC.modalPresentationStyle = .custom
                    previewImageVC.modalTransitionStyle  = .crossDissolve
                    self.present(previewImageVC, animated: true, completion: nil)
                }
            }
            catch {
                print("Error reading secure file")
            }
        }
        else if fileItem.videoId != "" {
            print("this video")
            do {
                if var secureData = try FileEncryption.shared.readSecure(filename: fileItem.filename) {
                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: secureData)
                    if dataDecrypt != nil {
                        secureData = dataDecrypt!
                    }
                    let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    let tempPath = cachesDirectory.appendingPathComponent(fileItem.filename)
                    try secureData.write(to: tempPath)
                    let player = AVPlayer(url: tempPath as URL)
                    let playerVC = AVPlayerViewController()
                    playerVC.modalPresentationStyle = .custom
                    playerVC.player = player
                    self.present(playerVC, animated: true, completion: nil)
                }
            } catch {
                
            }
        }
        else if fileItem.fileId != "" {
            print("this file")
            do {
                if var docData = try FileEncryption.shared.readSecure(filename: fileItem.filename) {
                    let dataDecrypt = FileEncryption.shared.decryptFileFromServer(data: docData)
                    if dataDecrypt != nil {
                        docData = dataDecrypt!
                    }
                    let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    let tempPath = cachesDirectory.appendingPathComponent(fileItem.filename)
                    try docData.write(to: tempPath)
                    self.previewItem = tempPath as NSURL
                    let previewController = QLPreviewController()
                    let rightBarButton = UIBarButtonItem()
                    previewController.navigationItem.rightBarButtonItem = rightBarButton
                    previewController.dataSource = self
                    previewController.modalPresentationStyle = .custom
                    self.present(previewController,animated: true)
                }
            }
            catch {
                
            }
        }
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.previewItem != nil ? 1 : 0
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem!
    }
    
}
                                                    
struct SecureFolderItem {
    let audioId: String
    let videoId: String
    let imageId: String
    let fileId: String
    let thumbId: String
    let attachmentFlag: String
    let serverDate: String
    let status: String
    let filename: String
    
    init(audioId: String, videoId: String, imageId: String, fileId: String, thumbId: String, attachmentFlag: String, serverDate: String, status: String, filename: String) {
        self.audioId = audioId
        self.videoId = videoId
        self.imageId = imageId
        self.fileId = fileId
        self.thumbId = thumbId
        self.attachmentFlag = attachmentFlag
        self.serverDate = serverDate
        self.status = status
        self.filename = filename
    }
}

// Custom UICollectionViewCell
class FileCell: UICollectionViewCell {
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.image = UIImage(systemName: "doc") // Default placeholder image
        return iv
    }()
    
    let label: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.numberOfLines = 1
        lbl.font = UIFont.systemFont(ofSize: 12)
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
                
        contentView.addSubview(imageView)
        contentView.addSubview(label)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.75),

            label.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
