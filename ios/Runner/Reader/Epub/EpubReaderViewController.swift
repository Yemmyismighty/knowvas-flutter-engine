import UIKit
import WebKit

/// View controller for EPUB reader with controls and interactions
class EpubReaderViewController: UIViewController {
    
    // MARK: - Properties
    
    private let epubReader: EpubReader
    private let sessionId: String
    private var webView: WKWebView!
    
    // UI Components
    private var topToolbar: UIView!
    private var bottomToolbar: UIView!
    private var titleLabel: UILabel!
    private var bookmarkButton: UIButton!
    private var settingsButton: UIButton!
    private var progressSlider: UISlider!
    private var pageLabel: UILabel!
    private var closeButton: UIButton!
    
    // State
    private var controlsVisible = true
    private var currentPage = 0
    private var totalPages = 0
    private var bookmarks: Set<Int> = []
    
    // Text selection
    private var selectedText: String?
    private var selectedRange: NSRange?
    
    // MARK: - Initialization
    
    init(epubReader: EpubReader, sessionId: String) {
        self.epubReader = epubReader
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWebView()
        setupToolbars()
        setupGestures()
        applyTheme()
        
        // Set webView reference in reader
        epubReader.setWebView(webView)
    }
    
    // MARK: - Setup Methods
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupToolbars() {
        setupTopToolbar()
        setupBottomToolbar()
    }
    
    private func setupTopToolbar() {
        topToolbar = UIView()
        topToolbar.translatesAutoresizingMaskIntoConstraints = false
        topToolbar.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.addSubview(topToolbar)
        
        // Close button
        closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        topToolbar.addSubview(closeButton)
        
        // Title label
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.text = "EPUB Reader"
        topToolbar.addSubview(titleLabel)
        
        // Bookmark button
        bookmarkButton = UIButton(type: .system)
        bookmarkButton.translatesAutoresizingMaskIntoConstraints = false
        bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        bookmarkButton.tintColor = .white
        bookmarkButton.addTarget(self, action: #selector(bookmarkButtonTapped), for: .touchUpInside)
        topToolbar.addSubview(bookmarkButton)
        
        // Settings button
        settingsButton = UIButton(type: .system)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setImage(UIImage(systemName: "textformat.size"), for: .normal)
        settingsButton.tintColor = .white
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        topToolbar.addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            topToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topToolbar.heightAnchor.constraint(equalToConstant: 50),
            
            closeButton.leadingAnchor.constraint(equalTo: topToolbar.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: topToolbar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
            
            settingsButton.trailingAnchor.constraint(equalTo: topToolbar.trailingAnchor, constant: -16),
            settingsButton.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
            
            bookmarkButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -8),
            bookmarkButton.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            bookmarkButton.widthAnchor.constraint(equalToConstant: 44),
            bookmarkButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupBottomToolbar() {
        bottomToolbar = UIView()
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.addSubview(bottomToolbar)
        
        // Progress slider
        progressSlider = UISlider()
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.tintColor = .systemBlue
        progressSlider.addTarget(self, action: #selector(progressSliderChanged), for: .valueChanged)
        bottomToolbar.addSubview(progressSlider)
        
        // Page label
        pageLabel = UILabel()
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        pageLabel.textColor = .white
        pageLabel.font = UIFont.systemFont(ofSize: 14)
        pageLabel.textAlignment = .center
        pageLabel.text = "Page 0 of 0"
        bottomToolbar.addSubview(pageLabel)
        
        NSLayoutConstraint.activate([
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 80),
            
            progressSlider.topAnchor.constraint(equalTo: bottomToolbar.topAnchor, constant: 16),
            progressSlider.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor, constant: 20),
            progressSlider.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -20),
            
            pageLabel.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 8),
            pageLabel.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor)
        ])
    }
    
    private func setupGestures() {
        // Tap gesture to toggle controls
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        webView.addGestureRecognizer(tapGesture)
        
        // Long press for text selection menu
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        webView.addGestureRecognizer(longPressGesture)
    }
    
    private func applyTheme() {
        let settings = epubReader.getSettings()
        view.backgroundColor = settings.theme.backgroundColor
        webView.backgroundColor = settings.theme.backgroundColor
    }
    
    // MARK: - Control Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true) {
            self.epubReader.close()
        }
    }
    
    @objc private func bookmarkButtonTapped() {
        toggleBookmark()
    }
    
    @objc private func settingsButtonTapped() {
        showSettingsPanel()
    }
    
    @objc private func progressSliderChanged(_ sender: UISlider) {
        let page = Int(sender.value * Float(totalPages - 1))
        goToPage(page)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: webView)
        
        // Check if tap is in center area (not on toolbars)
        let centerRect = CGRect(
            x: 0,
            y: topToolbar.frame.maxY,
            width: webView.bounds.width,
            height: webView.bounds.height - topToolbar.frame.height - bottomToolbar.frame.height
        )
        
        if centerRect.contains(location) {
            toggleControls()
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let location = gesture.location(in: webView)
            checkTextSelectionAt(location)
        }
    }
    
    // MARK: - Control Visibility
    
    private func toggleControls() {
        controlsVisible.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.topToolbar.alpha = self.controlsVisible ? 1.0 : 0.0
            self.bottomToolbar.alpha = self.controlsVisible ? 1.0 : 0.0
        }
    }
    
    private func showControls() {
        guard !controlsVisible else { return }
        controlsVisible = true
        
        UIView.animate(withDuration: 0.3) {
            self.topToolbar.alpha = 1.0
            self.bottomToolbar.alpha = 1.0
        }
    }
    
    private func hideControls() {
        guard controlsVisible else { return }
        controlsVisible = false
        
        UIView.animate(withDuration: 0.3) {
            self.topToolbar.alpha = 0.0
            self.bottomToolbar.alpha = 0.0
        }
    }
    
    // MARK: - Navigation
    
    func goToPage(_ page: Int) {
        guard page >= 0 && page < totalPages else { return }
        
        currentPage = page
        updatePageDisplay()
        updateBookmarkButton()
        
        // Navigate in reader
        epubReader.goToPage(page)
        
        // Update slider without triggering change event
        progressSlider.value = totalPages > 1 ? Float(page) / Float(totalPages - 1) : 0
    }
    
    func updateTotalPages(_ total: Int) {
        totalPages = total
        progressSlider.maximumValue = Float(total - 1)
        updatePageDisplay()
    }
    
    private func updatePageDisplay() {
        pageLabel.text = "Page \(currentPage + 1) of \(totalPages)"
    }
    
    // MARK: - Bookmarks
    
    private func toggleBookmark() {
        if bookmarks.contains(currentPage) {
            removeBookmark()
        } else {
            addBookmark()
        }
    }
    
    private func addBookmark() {
        bookmarks.insert(currentPage)
        updateBookmarkButton()
        emitBookmarkEvent(added: true)
        
        // Show feedback
        showToast(message: "Bookmark added")
    }
    
    private func removeBookmark() {
        bookmarks.remove(currentPage)
        updateBookmarkButton()
        emitBookmarkEvent(added: false)
        
        // Show feedback
        showToast(message: "Bookmark removed")
    }
    
    private func updateBookmarkButton() {
        let imageName = bookmarks.contains(currentPage) ? "bookmark.fill" : "bookmark"
        bookmarkButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    // MARK: - Text Selection
    
    private func checkTextSelectionAt(_ location: CGPoint) {
        // Get selected text from WebView
        webView.evaluateJavaScript("window.getSelection().toString()") { [weak self] result, error in
            guard let self = self,
                  let text = result as? String,
                  !text.isEmpty else {
                return
            }
            
            self.selectedText = text
            self.showTextSelectionMenu(at: location)
        }
    }
    
    private func showTextSelectionMenu(at location: CGPoint) {
        let alert = UIAlertController(title: "Text Selection", message: nil, preferredStyle: .actionSheet)
        
        // Highlight action
        alert.addAction(UIAlertAction(title: "Highlight", style: .default) { [weak self] _ in
            self?.showHighlightColorPicker()
        })
        
        // Add note action
        alert.addAction(UIAlertAction(title: "Add Note", style: .default) { [weak self] _ in
            self?.showAddNoteDialog()
        })
        
        // Copy action
        alert.addAction(UIAlertAction(title: "Copy", style: .default) { [weak self] _ in
            self?.copySelectedText()
        })
        
        // Share action
        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            self?.shareSelectedText()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = webView
            popover.sourceRect = CGRect(origin: location, size: .zero)
        }
        
        present(alert, animated: true)
    }
    
    private func showHighlightColorPicker() {
        let alert = UIAlertController(title: "Choose Highlight Color", message: nil, preferredStyle: .actionSheet)
        
        let colors: [(String, String)] = [
            ("Yellow", "#FFFF00"),
            ("Green", "#00FF00"),
            ("Blue", "#00BFFF"),
            ("Pink", "#FFB6C1"),
            ("Orange", "#FFA500")
        ]
        
        for (name, hex) in colors {
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.addHighlight(color: hex)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func addHighlight(color: String) {
        guard let text = selectedText else { return }
        
        // Apply highlight in WebView
        let script = """
        (function() {
            var selection = window.getSelection();
            if (selection.rangeCount > 0) {
                var range = selection.getRangeAt(0);
                var span = document.createElement('span');
                span.style.backgroundColor = '\(color)';
                span.className = 'knowvas-highlight';
                range.surroundContents(span);
                selection.removeAllRanges();
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { [weak self] _, error in
            if error == nil {
                self?.emitHighlightEvent(text: text, color: color)
                self?.showToast(message: "Highlight added")
            }
        }
        
        selectedText = nil
    }
    
    private func showAddNoteDialog() {
        let alert = UIAlertController(title: "Add Note", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter your note"
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let noteText = alert.textFields?.first?.text, !noteText.isEmpty {
                self?.addNote(noteText)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func addNote(_ noteText: String) {
        guard let selectedText = selectedText else { return }
        
        emitNoteEvent(text: selectedText, note: noteText)
        showToast(message: "Note added")
        
        self.selectedText = nil
    }
    
    private func copySelectedText() {
        guard let text = selectedText else { return }
        
        UIPasteboard.general.string = text
        showToast(message: "Text copied")
        
        selectedText = nil
    }
    
    private func shareSelectedText() {
        guard let text = selectedText else { return }
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(activityVC, animated: true)
        
        selectedText = nil
    }
    
    // MARK: - Settings Panel
    
    private func showSettingsPanel() {
        let settingsVC = EpubSettingsViewController(epubReader: epubReader)
        settingsVC.delegate = self
        
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .pageSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    // MARK: - Event Emission
    
    private func emitBookmarkEvent(added: Bool) {
        epubReader.emitBookmarkEvent(pageNumber: currentPage, added: added)
    }
    
    private func emitHighlightEvent(text: String, color: String) {
        epubReader.emitHighlightEvent(pageNumber: currentPage, text: text, color: color)
    }
    
    private func emitNoteEvent(text: String, note: String) {
        epubReader.emitNoteEvent(pageNumber: currentPage, text: text, note: note)
    }
    
    // MARK: - UI Helpers
    
    private func showToast(message: String) {
        let toast = UILabel()
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toast.textColor = .white
        toast.textAlignment = .center
        toast.font = UIFont.systemFont(ofSize: 14)
        toast.text = message
        toast.alpha = 0
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true
        
        view.addSubview(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            toast.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            toast.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension EpubReaderViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Page loaded
        print("EPUB page loaded")
    }
}

// MARK: - UIScrollViewDelegate

extension EpubReaderViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Track scroll position for page calculation
        // This is a simplified implementation
    }
}

// MARK: - UIGestureRecognizerDelegate

extension EpubReaderViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - EpubSettingsDelegate

extension EpubReaderViewController: EpubSettingsViewControllerDelegate {
    func settingsDidChange() {
        applyTheme()
    }
}
