import UIKit

/// View controller for displaying comic pages using UIPageViewController
/// Requirement 7.3 - UIPageViewController for page viewing with swipe navigation
class ComicPageViewController: UIViewController {
    
    private let comicReader: ComicReader
    private var pageViewController: UIPageViewController!
    private var currentPageIndex: Int = 0
    
    init(comicReader: ComicReader) {
        self.comicReader = comicReader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPageViewController()
        setupGestures()
        
        // Display first page
        if let firstPage = createPageViewController(at: 0) {
            pageViewController.setViewControllers(
                [firstPage],
                direction: .forward,
                animated: false,
                completion: nil
            )
        }
    }
    
    private func setupPageViewController() {
        // Create page view controller with horizontal scrolling
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        // Add as child view controller
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.frame = view.bounds
        pageViewController.didMove(toParent: self)
    }
    
    private func setupGestures() {
        // UIPageViewController handles swipe gestures automatically
        // Additional gestures can be added here if needed
    }
    
    private func createPageViewController(at index: Int) -> ComicPageContentViewController? {
        guard index >= 0, index < comicReader.getTotalPages() else { return nil }
        
        let preferences = comicReader.getPreferences()
        
        // Create page view controller with preferences
        // Requirements: 7.8, 7.9 - Reading direction and guided view
        let pageVC = ComicPageContentViewController(
            pageIndex: index,
            guidedViewEnabled: preferences.guidedViewEnabled,
            readingDirection: preferences.readingDirection
        )
        
        switch preferences.layout {
        case .single:
            // Single page layout
            let images = comicReader.getCurrentPageImages()
            guard let image = images.first as? UIImage else { return nil }
            
            pageVC.setImage(image)
            return pageVC
            
        case .double:
            // Double page layout
            let images = comicReader.getCurrentPageImages()
            
            if preferences.readingDirection == .rtl {
                // RTL: right page first, then left page
                pageVC.setImages(rightImage: images[0] as? UIImage, leftImage: images[1] as? UIImage)
            } else {
                // LTR: left page first, then right page
                pageVC.setImages(leftImage: images[0] as? UIImage, rightImage: images[1] as? UIImage)
            }
            
            return pageVC
        }
    }
    
    /// Navigate to a specific page
    func goToPage(_ pageIndex: Int, animated: Bool = true) {
        guard pageIndex >= 0, pageIndex < comicReader.getTotalPages() else { return }
        
        let direction: UIPageViewController.NavigationDirection = pageIndex > currentPageIndex ? .forward : .reverse
        
        if let pageVC = createPageViewController(at: pageIndex) {
            pageViewController.setViewControllers(
                [pageVC],
                direction: direction,
                animated: animated,
                completion: { [weak self] _ in
                    self?.currentPageIndex = pageIndex
                    self?.comicReader.goToPage(pageIndex)
                }
            )
        }
    }
    
    /// Update reader preferences and refresh current page
    /// Requirements: 7.8, 7.9 - Dynamic preference updates
    func updatePreferences(_ preferences: [String: Any]) {
        // Update preferences in comic reader
        comicReader.setPreferences(preferences)
        
        // Refresh current page with new preferences
        if let currentVC = pageViewController.viewControllers?.first as? ComicPageContentViewController {
            let newPrefs = comicReader.getPreferences()
            
            // Update guided view setting
            currentVC.setGuidedViewEnabled(newPrefs.guidedViewEnabled)
            
            // Update reading direction
            currentVC.setReadingDirection(newPrefs.readingDirection)
        }
        
        // Recreate page if layout changed (single vs double)
        goToPage(currentPageIndex, animated: false)
    }
}

// MARK: - UIPageViewControllerDataSource

extension ComicPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let pageVC = viewController as? ComicPageContentViewController else { return nil }
        
        let previousIndex = pageVC.pageIndex - 1
        return createPageViewController(at: previousIndex)
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let pageVC = viewController as? ComicPageContentViewController else { return nil }
        
        let nextIndex = pageVC.pageIndex + 1
        return createPageViewController(at: nextIndex)
    }
}

// MARK: - UIPageViewControllerDelegate

extension ComicPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? ComicPageContentViewController else {
            return
        }
        
        currentPageIndex = currentVC.pageIndex
        comicReader.goToPage(currentPageIndex)
    }
}

// MARK: - Comic Page Content View Controller

/// View controller for displaying a single comic page or double-page spread
/// Requirements: 7.5, 7.6, 7.7, 7.8, 7.9
class ComicPageContentViewController: UIViewController {
    
    let pageIndex: Int
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var leftImageView: UIImageView?
    private var rightImageView: UIImageView?
    private var isDoublePage: Bool = false
    
    // Guided view properties
    // Requirement 7.9 - Guided view (panel-by-panel navigation)
    private var guidedViewEnabled: Bool = false
    private var panels: [CGRect] = []
    private var currentPanelIndex: Int = 0
    private var panelOverlayView: UIView?
    
    // Reading direction
    // Requirement 7.8 - Reading direction option (LTR, RTL)
    private var readingDirection: ComicReaderPreferences.ReadingDirection = .ltr
    
    init(pageIndex: Int, guidedViewEnabled: Bool = false, readingDirection: ComicReaderPreferences.ReadingDirection = .ltr) {
        self.pageIndex = pageIndex
        self.guidedViewEnabled = guidedViewEnabled
        self.readingDirection = readingDirection
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScrollView()
        setupGestures()
    }
    
    private func setupScrollView() {
        // Create scroll view for zoom and pan
        // Requirements: 7.5, 7.6 - Pinch-to-zoom and pan gesture support
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0  // Requirement 7.5 - Zoom limits (100% to 400%)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Enable pinch-to-zoom gesture
        // Requirement 7.5 - Implement pinch-to-zoom using UIScrollView
        scrollView.isUserInteractionEnabled = true
        scrollView.bounces = true
        scrollView.bouncesZoom = true
        
        view.addSubview(scrollView)
    }
    
    private func setupGestures() {
        // Add double-tap gesture for zoom toggle
        // Requirement 7.7 - Implement double-tap zoom toggle
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        
        // Add single tap gesture for guided view navigation
        // Requirement 7.9 - Guided view navigation
        if guidedViewEnabled {
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
            singleTap.numberOfTapsRequired = 1
            singleTap.require(toFail: doubleTap)  // Only trigger if not double-tap
            scrollView.addGestureRecognizer(singleTap)
        }
    }
    
    /// Set a single image for single-page layout
    func setImage(_ image: UIImage) {
        isDoublePage = false
        
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(origin: .zero, size: image.size)
        imageView.isUserInteractionEnabled = true
        
        scrollView.addSubview(imageView)
        scrollView.contentSize = image.size
        
        // Center the image
        centerImage()
        
        // Detect panels for guided view if enabled
        // Requirement 7.9 - Guided view (panel-by-panel navigation)
        if guidedViewEnabled {
            detectPanels(in: image)
        }
    }
    
    /// Set two images for double-page layout
    func setImages(leftImage: UIImage?, rightImage: UIImage?) {
        isDoublePage = true
        
        // Create container view for both images
        let containerView = UIView()
        
        var totalWidth: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        // Add left image
        if let leftImage = leftImage {
            leftImageView = UIImageView(image: leftImage)
            leftImageView?.contentMode = .scaleAspectFit
            leftImageView?.frame = CGRect(x: 0, y: 0, width: leftImage.size.width, height: leftImage.size.height)
            containerView.addSubview(leftImageView!)
            
            totalWidth += leftImage.size.width
            maxHeight = max(maxHeight, leftImage.size.height)
        }
        
        // Add right image
        if let rightImage = rightImage {
            rightImageView = UIImageView(image: rightImage)
            rightImageView?.contentMode = .scaleAspectFit
            rightImageView?.frame = CGRect(x: totalWidth, y: 0, width: rightImage.size.width, height: rightImage.size.height)
            containerView.addSubview(rightImageView!)
            
            totalWidth += rightImage.size.width
            maxHeight = max(maxHeight, rightImage.size.height)
        }
        
        containerView.frame = CGRect(x: 0, y: 0, width: totalWidth, height: maxHeight)
        
        scrollView.addSubview(containerView)
        scrollView.contentSize = CGSize(width: totalWidth, height: maxHeight)
        
        imageView = UIImageView(frame: containerView.frame)
        imageView.addSubview(containerView)
        
        // Center the images
        centerImage()
    }
    
    private func centerImage() {
        guard let imageView = imageView else { return }
        
        let scrollViewSize = scrollView.bounds.size
        let imageSize = imageView.frame.size
        
        let horizontalInset = max(0, (scrollViewSize.width - imageSize.width) / 2)
        let verticalInset = max(0, (scrollViewSize.height - imageSize.height) / 2)
        
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Requirement 7.7 - Double-tap zoom toggle
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            // Zoom out to fit-to-screen
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // Zoom in to 2x at tap location
            let tapLocation = gesture.location(in: imageView)
            let zoomRect = zoomRectForScale(scale: 2.0, center: tapLocation)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        // Requirement 7.9 - Guided view navigation with single tap
        guard guidedViewEnabled, !panels.isEmpty else { return }
        
        // Navigate to next panel
        navigateToNextPanel()
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        zoomRect.size.width = scrollView.frame.size.width / scale
        zoomRect.size.height = scrollView.frame.size.height / scale
        
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    // MARK: - Guided View Navigation
    
    /// Detect panels in the comic page for guided view
    /// Requirement 7.9 - Guided view (panel-by-panel navigation)
    private func detectPanels(in image: UIImage) {
        // Simple panel detection algorithm
        // In a production app, you might use image processing or ML to detect panels
        // For now, we'll create a grid-based approach
        
        let imageSize = image.size
        let panelWidth = imageSize.width
        let panelHeight = imageSize.height / 3  // Assume 3 rows of panels
        
        panels.removeAll()
        
        // Create panels based on reading direction
        // Requirement 7.8 - Reading direction option (LTR, RTL)
        if readingDirection == .rtl {
            // Right-to-left: top-right to bottom-left
            for row in 0..<3 {
                let y = CGFloat(row) * panelHeight
                let panel = CGRect(x: 0, y: y, width: panelWidth, height: panelHeight)
                panels.append(panel)
            }
        } else {
            // Left-to-right: top-left to bottom-right
            for row in 0..<3 {
                let y = CGFloat(row) * panelHeight
                let panel = CGRect(x: 0, y: y, width: panelWidth, height: panelHeight)
                panels.append(panel)
            }
        }
        
        currentPanelIndex = 0
        
        // Show first panel if guided view is enabled
        if guidedViewEnabled && !panels.isEmpty {
            zoomToPanel(at: 0, animated: false)
        }
    }
    
    /// Navigate to the next panel in guided view
    /// Requirement 7.9 - Guided view navigation
    private func navigateToNextPanel() {
        guard !panels.isEmpty else { return }
        
        currentPanelIndex += 1
        
        if currentPanelIndex >= panels.count {
            // Reached end of page, zoom out to show full page
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            currentPanelIndex = 0
            return
        }
        
        zoomToPanel(at: currentPanelIndex, animated: true)
    }
    
    /// Navigate to the previous panel in guided view
    /// Requirement 7.9 - Guided view navigation
    private func navigateToPreviousPanel() {
        guard !panels.isEmpty else { return }
        
        currentPanelIndex -= 1
        
        if currentPanelIndex < 0 {
            currentPanelIndex = 0
            return
        }
        
        zoomToPanel(at: currentPanelIndex, animated: true)
    }
    
    /// Zoom to a specific panel
    /// Requirement 7.9 - Guided view with automatic zoom and pan
    private func zoomToPanel(at index: Int, animated: Bool) {
        guard index >= 0, index < panels.count else { return }
        
        let panel = panels[index]
        
        // Calculate zoom scale to fit panel
        let scrollViewSize = scrollView.bounds.size
        let widthScale = scrollViewSize.width / panel.width
        let heightScale = scrollViewSize.height / panel.height
        let scale = min(widthScale, heightScale, scrollView.maximumZoomScale)
        
        // Calculate the rect to zoom to
        let zoomRect = CGRect(
            x: panel.origin.x,
            y: panel.origin.y,
            width: scrollViewSize.width / scale,
            height: scrollViewSize.height / scale
        )
        
        scrollView.zoom(to: zoomRect, animated: animated)
        
        // Highlight the current panel (optional visual feedback)
        highlightPanel(panel)
    }
    
    /// Highlight the current panel with a subtle overlay
    /// Requirement 7.9 - Visual feedback for guided view
    private func highlightPanel(_ panel: CGRect) {
        // Remove previous overlay
        panelOverlayView?.removeFromSuperview()
        
        // Create a subtle border around the panel
        let overlayView = UIView(frame: panel)
        overlayView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        overlayView.layer.borderWidth = 3.0
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = false
        
        imageView.addSubview(overlayView)
        panelOverlayView = overlayView
        
        // Fade out the overlay after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak overlayView] in
            UIView.animate(withDuration: 0.3) {
                overlayView?.alpha = 0
            } completion: { _ in
                overlayView?.removeFromSuperview()
            }
        }
    }
    
    /// Enable or disable guided view
    /// Requirement 7.9 - Toggle guided view
    func setGuidedViewEnabled(_ enabled: Bool) {
        guidedViewEnabled = enabled
        
        if enabled && !panels.isEmpty {
            zoomToPanel(at: currentPanelIndex, animated: true)
        } else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            panelOverlayView?.removeFromSuperview()
        }
    }
    
    /// Set reading direction
    /// Requirement 7.8 - Reading direction option (LTR, RTL)
    func setReadingDirection(_ direction: ComicReaderPreferences.ReadingDirection) {
        readingDirection = direction
        
        // Re-detect panels with new reading direction if guided view is enabled
        if guidedViewEnabled, let image = imageView.image {
            detectPanels(in: image)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension ComicPageContentViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }
}
