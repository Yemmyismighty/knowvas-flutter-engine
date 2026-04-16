import Foundation
import UIKit
import PDFKit

/// View controller for PDF reader with controls and UI
class PdfViewController: UIViewController {
    // MARK: - Properties
    
    private let pdfReader: PdfReader
    private var pdfView: PDFView?
    
    // UI Controls
    private var topToolbar: UIView!
    private var bottomToolbar: UIView!
    private var titleLabel: UILabel!
    private var pageLabel: UILabel!
    private var pageSlider: UISlider!
    private var bookmarkButton: UIButton!
    private var settingsButton: UIButton!
    private var closeButton: UIButton!
    
    // Control visibility
    private var controlsVisible: Bool = true
    private var tapGestureRecognizer: UITapGestureRecognizer?
    
    // Bookmarks
    private var bookmarks: Set<Int> = []
    
    // Settings
    private var currentTheme: String = "light"
    private var currentTransition: String = "swipe"
    
    // MARK: - Initialization
    
    init(pdfReader: PdfReader) {
        self.pdfReader = pdfReader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPDFView()
        setupToolbars()
        setupTapGesture()
        setupTextSelection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePageLabel()
    }
    
    // MARK: - Setup Methods
    
    private func setupPDFView() {
        guard let pdfView = pdfReader.getPDFView() else { return }
        self.pdfView = pdfView
        
        // Add PDF view to the view hierarchy
        view.addSubview(pdfView)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Observe page changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pdfViewPageChanged),
            name: .PDFViewPageChanged,
            object: pdfView
        )
    }
    
    private func setupToolbars() {
        setupTopToolbar()
        setupBottomToolbar()
    }
    
    private func setupTopToolbar() {
        // Create top toolbar
        topToolbar = UIView()
        topToolbar.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        topToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topToolbar)
        
        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        topToolbar.addSubview(closeButton)
        
        // Title label
        titleLabel = UILabel()
        titleLabel.text = "PDF Document"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topToolbar.addSubview(titleLabel)
        
        // Bookmark button
        bookmarkButton = UIButton(type: .system)
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = .white
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
        topToolbar.addSubview(bookmarkButton)
        
        // Settings button
        settingsButton = UIButton(type: .system)
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.tintColor = .white
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        topToolbar.addSubview(settingsButton)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            topToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topToolbar.heightAnchor.constraint(equalToConstant: 50),
            
            closeButton.leadingAnchor.constraint(equalTo: topToolbar.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            titleLabel.centerXAnchor.constraint(equalTo: topToolbar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            
            settingsButton.trailingAnchor.constraint(equalTo: topToolbar.trailingAnchor, constant: -16),
            settingsButton.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 30),
            settingsButton.heightAnchor.constraint(equalToConstant: 30),
            
            bookmarkButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -16),
            bookmarkButton.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 30),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupBottomToolbar() {
        // Create bottom toolbar
        bottomToolbar = UIView()
        bottomToolbar.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomToolbar)
        
        // Page label
        pageLabel = UILabel()
        pageLabel.text = "1 / 1"
        pageLabel.textColor = .white
        pageLabel.font = UIFont.systemFont(ofSize: 14)
        pageLabel.textAlignment = .center
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(pageLabel)
        
        // Page slider
        pageSlider = UISlider()
        pageSlider.minimumValue = 0
        pageSlider.maximumValue = 1
        pageSlider.value = 0
        pageSlider.addTarget(self, action: #selector(pageSliderChanged), for: .valueChanged)
        pageSlider.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(pageSlider)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 80),
            
            pageLabel.topAnchor.constraint(equalTo: bottomToolbar.topAnchor, constant: 8),
            pageLabel.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            
            pageSlider.topAnchor.constraint(equalTo: pageLabel.bottomAnchor, constant: 8),
            pageSlider.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor, constant: 20),
            pageSlider.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupTapGesture() {
        // Add single tap gesture to toggle controls
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        
        // Make sure it doesn't interfere with double-tap zoom
        if let pdfView = pdfView {
            for gesture in pdfView.gestureRecognizers ?? [] {
                if let tapGesture = gesture as? UITapGestureRecognizer,
                   tapGesture.numberOfTapsRequired == 2 {
                    tapGesture.require(toFail: tapGesture)
                }
            }
        }
        
        view.addGestureRecognizer(tapGesture)
        tapGestureRecognizer = tapGesture
    }
    
    private func setupTextSelection() {
        // PDFView automatically supports text selection
        // We just need to enable user interaction
        pdfView?.isUserInteractionEnabled = true
        
        // Add menu items for text selection
        let copyMenuItem = UIMenuItem(title: "Copy", action: #selector(copySelectedText))
        UIMenuController.shared.menuItems = [copyMenuItem]
    }
    
    // MARK: - Control Actions
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Toggle controls visibility
        toggleControls()
    }
    
    private func toggleControls() {
        controlsVisible.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.topToolbar.alpha = self.controlsVisible ? 1.0 : 0.0
            self.bottomToolbar.alpha = self.controlsVisible ? 1.0 : 0.0
        }
    }
    
    @objc private func closeButtonTapped() {
        // Close the reader
        dismiss(animated: true) {
            self.pdfReader.close()
        }
    }
    
    @objc private func bookmarkButtonTapped() {
        guard let pdfView = pdfView,
              let currentPage = pdfView.currentPage,
              let document = pdfView.document,
              let pageIndex = document.index(for: currentPage) else {
            return
        }
        
        // Toggle bookmark
        if bookmarks.contains(pageIndex) {
            bookmarks.remove(pageIndex)
            bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
            emitBookmarkEvent(pageIndex: pageIndex, action: "remove")
        } else {
            bookmarks.insert(pageIndex)
            bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
            emitBookmarkEvent(pageIndex: pageIndex, action: "add")
        }
    }
    
    @objc private func settingsButtonTapped() {
        showSettingsMenu()
    }
    
    @objc private func pageSliderChanged(_ slider: UISlider) {
        let pageIndex = Int(slider.value)
        pdfReader.goToPage(pageIndex)
    }
    
    @objc private func pdfViewPageChanged(_ notification: Notification) {
        updatePageLabel()
        updateBookmarkButton()
    }
    
    @objc private func copySelectedText() {
        guard let pdfView = pdfView,
              let selection = pdfView.currentSelection else {
            return
        }
        
        let selectedText = selection.string ?? ""
        UIPasteboard.general.string = selectedText
        
        // Show confirmation
        showToast(message: "Text copied")
    }
    
    // MARK: - Settings Menu
    
    private func showSettingsMenu() {
        let alertController = UIAlertController(
            title: "PDF Settings",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        // Theme options
        let themeAction = UIAlertAction(title: "Theme", style: .default) { [weak self] _ in
            self?.showThemeOptions()
        }
        alertController.addAction(themeAction)
        
        // Page transition options
        let transitionAction = UIAlertAction(title: "Page Transition", style: .default) { [weak self] _ in
            self?.showTransitionOptions()
        }
        alertController.addAction(transitionAction)
        
        // View bookmarks
        let bookmarksAction = UIAlertAction(title: "View Bookmarks", style: .default) { [weak self] _ in
            self?.showBookmarks()
        }
        alertController.addAction(bookmarksAction)
        
        // Cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        // For iPad
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = settingsButton
            popoverController.sourceRect = settingsButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func showThemeOptions() {
        let alertController = UIAlertController(
            title: "Select Theme",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let themes = [
            ("Light", "light"),
            ("Dark", "dark"),
            ("Sepia", "sepia")
        ]
        
        for (title, value) in themes {
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applyTheme(value)
            }
            if value == currentTheme {
                action.setValue(true, forKey: "checked")
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = settingsButton
            popoverController.sourceRect = settingsButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func showTransitionOptions() {
        let alertController = UIAlertController(
            title: "Page Transition",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        let transitions = [
            ("Swipe", "swipe"),
            ("Continuous Scroll", "continuous")
        ]
        
        for (title, value) in transitions {
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applyTransition(value)
            }
            if value == currentTransition {
                action.setValue(true, forKey: "checked")
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = settingsButton
            popoverController.sourceRect = settingsButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func showBookmarks() {
        if bookmarks.isEmpty {
            showToast(message: "No bookmarks")
            return
        }
        
        let alertController = UIAlertController(
            title: "Bookmarks",
            message: "Select a bookmark to navigate",
            preferredStyle: .actionSheet
        )
        
        let sortedBookmarks = bookmarks.sorted()
        for pageIndex in sortedBookmarks {
            let action = UIAlertAction(title: "Page \(pageIndex + 1)", style: .default) { [weak self] _ in
                self?.pdfReader.goToPage(pageIndex)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = bookmarkButton
            popoverController.sourceRect = bookmarkButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func applyTheme(_ theme: String) {
        currentTheme = theme
        pdfReader.setPreferences(["theme": theme])
        
        // Update toolbar colors based on theme
        let toolbarColor: UIColor
        switch theme {
        case "dark":
            toolbarColor = UIColor.black.withAlphaComponent(0.9)
        case "sepia":
            toolbarColor = UIColor(red: 0.8, green: 0.75, blue: 0.65, alpha: 0.9)
        default:
            toolbarColor = UIColor.black.withAlphaComponent(0.7)
        }
        
        topToolbar.backgroundColor = toolbarColor
        bottomToolbar.backgroundColor = toolbarColor
    }
    
    private func applyTransition(_ transition: String) {
        currentTransition = transition
        pdfReader.setPreferences(["page_transition": transition])
    }
    
    private func updatePageLabel() {
        guard let pdfView = pdfView,
              let currentPage = pdfView.currentPage,
              let document = pdfView.document,
              let pageIndex = document.index(for: currentPage) else {
            return
        }
        
        let totalPages = pdfReader.getTotalPages()
        pageLabel.text = "\(pageIndex + 1) / \(totalPages)"
        
        // Update slider
        pageSlider.maximumValue = Float(max(0, totalPages - 1))
        pageSlider.value = Float(pageIndex)
    }
    
    private func updateBookmarkButton() {
        guard let pdfView = pdfView,
              let currentPage = pdfView.currentPage,
              let document = pdfView.document,
              let pageIndex = document.index(for: currentPage) else {
            return
        }
        
        if bookmarks.contains(pageIndex) {
            bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        } else {
            bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        }
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toastLabel.widthAnchor.constraint(equalToConstant: 200),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Event Emission
    
    private func emitBookmarkEvent(pageIndex: Int, action: String) {
        // This would typically emit an event through the reader
        // For now, we'll just print it
        print("Bookmark \(action) at page \(pageIndex)")
    }
    
    // MARK: - Public Methods
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    func loadBookmarks(_ bookmarkPages: [Int]) {
        bookmarks = Set(bookmarkPages)
        updateBookmarkButton()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
