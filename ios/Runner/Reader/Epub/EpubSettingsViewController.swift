import UIKit

protocol EpubSettingsViewControllerDelegate: AnyObject {
    func settingsDidChange()
}

/// Settings panel for EPUB reader customization
class EpubSettingsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let epubReader: EpubReader
    weak var delegate: EpubSettingsViewControllerDelegate?
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    // Font size controls
    private var fontSizeLabel: UILabel!
    private var fontSizeSlider: UISlider!
    private var fontSizeValueLabel: UILabel!
    
    // Font family controls
    private var fontFamilyLabel: UILabel!
    private var fontFamilySegmentedControl: UISegmentedControl!
    
    // Theme controls
    private var themeLabel: UILabel!
    private var themeSegmentedControl: UISegmentedControl!
    
    // Line height controls
    private var lineHeightLabel: UILabel!
    private var lineHeightSlider: UISlider!
    private var lineHeightValueLabel: UILabel!
    
    // Margin controls
    private var marginLabel: UILabel!
    private var marginSlider: UISlider!
    private var marginValueLabel: UILabel!
    
    // MARK: - Initialization
    
    init(epubReader: EpubReader) {
        self.epubReader = epubReader
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Reader Settings"
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupScrollView()
        setupControls()
        loadCurrentSettings()
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupControls() {
        var lastView: UIView?
        let padding: CGFloat = 20
        let spacing: CGFloat = 24
        
        // Font Size Section
        fontSizeLabel = createSectionLabel(text: "Font Size")
        contentView.addSubview(fontSizeLabel)
        
        fontSizeSlider = UISlider()
        fontSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        fontSizeSlider.minimumValue = Float(EpubSettings.Constants.minFontSize)
        fontSizeSlider.maximumValue = Float(EpubSettings.Constants.maxFontSize)
        fontSizeSlider.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
        contentView.addSubview(fontSizeSlider)
        
        fontSizeValueLabel = createValueLabel()
        contentView.addSubview(fontSizeValueLabel)
        
        NSLayoutConstraint.activate([
            fontSizeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            fontSizeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            
            fontSizeValueLabel.centerYAnchor.constraint(equalTo: fontSizeLabel.centerYAnchor),
            fontSizeValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            fontSizeSlider.topAnchor.constraint(equalTo: fontSizeLabel.bottomAnchor, constant: 8),
            fontSizeSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            fontSizeSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        
        lastView = fontSizeSlider
        
        // Font Family Section
        fontFamilyLabel = createSectionLabel(text: "Font Family")
        contentView.addSubview(fontFamilyLabel)
        
        fontFamilySegmentedControl = UISegmentedControl(items: ["Serif", "Sans Serif", "Monospace"])
        fontFamilySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        fontFamilySegmentedControl.addTarget(self, action: #selector(fontFamilyChanged), for: .valueChanged)
        contentView.addSubview(fontFamilySegmentedControl)
        
        NSLayoutConstraint.activate([
            fontFamilyLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: spacing),
            fontFamilyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            fontFamilyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            fontFamilySegmentedControl.topAnchor.constraint(equalTo: fontFamilyLabel.bottomAnchor, constant: 8),
            fontFamilySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            fontFamilySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        
        lastView = fontFamilySegmentedControl
        
        // Theme Section
        themeLabel = createSectionLabel(text: "Theme")
        contentView.addSubview(themeLabel)
        
        themeSegmentedControl = UISegmentedControl(items: ["Light", "Sepia", "Dark"])
        themeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        themeSegmentedControl.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
        contentView.addSubview(themeSegmentedControl)
        
        NSLayoutConstraint.activate([
            themeLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: spacing),
            themeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            themeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            themeSegmentedControl.topAnchor.constraint(equalTo: themeLabel.bottomAnchor, constant: 8),
            themeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            themeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        
        lastView = themeSegmentedControl
        
        // Line Height Section
        lineHeightLabel = createSectionLabel(text: "Line Height")
        contentView.addSubview(lineHeightLabel)
        
        lineHeightSlider = UISlider()
        lineHeightSlider.translatesAutoresizingMaskIntoConstraints = false
        lineHeightSlider.minimumValue = Float(EpubSettings.Constants.minLineHeight)
        lineHeightSlider.maximumValue = Float(EpubSettings.Constants.maxLineHeight)
        lineHeightSlider.addTarget(self, action: #selector(lineHeightChanged), for: .valueChanged)
        contentView.addSubview(lineHeightSlider)
        
        lineHeightValueLabel = createValueLabel()
        contentView.addSubview(lineHeightValueLabel)
        
        NSLayoutConstraint.activate([
            lineHeightLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: spacing),
            lineHeightLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            
            lineHeightValueLabel.centerYAnchor.constraint(equalTo: lineHeightLabel.centerYAnchor),
            lineHeightValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            lineHeightSlider.topAnchor.constraint(equalTo: lineHeightLabel.bottomAnchor, constant: 8),
            lineHeightSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            lineHeightSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding)
        ])
        
        lastView = lineHeightSlider
        
        // Margin Section
        marginLabel = createSectionLabel(text: "Margin")
        contentView.addSubview(marginLabel)
        
        marginSlider = UISlider()
        marginSlider.translatesAutoresizingMaskIntoConstraints = false
        marginSlider.minimumValue = Float(EpubSettings.Constants.minMargin)
        marginSlider.maximumValue = Float(EpubSettings.Constants.maxMargin)
        marginSlider.addTarget(self, action: #selector(marginChanged), for: .valueChanged)
        contentView.addSubview(marginSlider)
        
        marginValueLabel = createValueLabel()
        contentView.addSubview(marginValueLabel)
        
        NSLayoutConstraint.activate([
            marginLabel.topAnchor.constraint(equalTo: lastView!.bottomAnchor, constant: spacing),
            marginLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            
            marginValueLabel.centerYAnchor.constraint(equalTo: marginLabel.centerYAnchor),
            marginValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            marginSlider.topAnchor.constraint(equalTo: marginLabel.bottomAnchor, constant: 8),
            marginSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            marginSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            marginSlider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
    }
    
    private func createSectionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        return label
    }
    
    private func createValueLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }
    
    // MARK: - Load Settings
    
    private func loadCurrentSettings() {
        let settings = epubReader.getSettings()
        
        // Font size
        fontSizeSlider.value = Float(settings.fontSize)
        fontSizeValueLabel.text = "\(settings.fontSize)px"
        
        // Font family
        switch settings.fontFamily {
        case .serif:
            fontFamilySegmentedControl.selectedSegmentIndex = 0
        case .sansSerif:
            fontFamilySegmentedControl.selectedSegmentIndex = 1
        case .monospace:
            fontFamilySegmentedControl.selectedSegmentIndex = 2
        }
        
        // Theme
        switch settings.theme {
        case .light:
            themeSegmentedControl.selectedSegmentIndex = 0
        case .sepia:
            themeSegmentedControl.selectedSegmentIndex = 1
        case .dark:
            themeSegmentedControl.selectedSegmentIndex = 2
        }
        
        // Line height
        lineHeightSlider.value = Float(settings.lineHeight)
        lineHeightValueLabel.text = String(format: "%.1f", settings.lineHeight)
        
        // Margin
        marginSlider.value = Float(settings.margin)
        marginValueLabel.text = String(format: "%.1f", settings.margin)
    }
    
    // MARK: - Actions
    
    @objc private func fontSizeChanged(_ sender: UISlider) {
        let size = Int(sender.value)
        fontSizeValueLabel.text = "\(size)px"
        
        let preferences = ReaderPreferences(from: [
            "font_size": size
        ])
        epubReader.setPreferences(preferences)
        delegate?.settingsDidChange()
    }
    
    @objc private func fontFamilyChanged(_ sender: UISegmentedControl) {
        let families: [EpubSettings.FontFamily] = [.serif, .sansSerif, .monospace]
        let family = families[sender.selectedSegmentIndex]
        
        let preferences = ReaderPreferences(from: [
            "font_family": family.rawValue
        ])
        epubReader.setPreferences(preferences)
        delegate?.settingsDidChange()
    }
    
    @objc private func themeChanged(_ sender: UISegmentedControl) {
        let themes: [EpubSettings.Theme] = [.light, .sepia, .dark]
        let theme = themes[sender.selectedSegmentIndex]
        
        let preferences = ReaderPreferences(from: [
            "theme": theme.rawValue
        ])
        epubReader.setPreferences(preferences)
        delegate?.settingsDidChange()
    }
    
    @objc private func lineHeightChanged(_ sender: UISlider) {
        let height = Double(sender.value)
        lineHeightValueLabel.text = String(format: "%.1f", height)
        
        let preferences = ReaderPreferences(from: [
            "line_height": height
        ])
        epubReader.setPreferences(preferences)
        delegate?.settingsDidChange()
    }
    
    @objc private func marginChanged(_ sender: UISlider) {
        let margin = Double(sender.value)
        marginValueLabel.text = String(format: "%.1f", margin)
        
        let preferences = ReaderPreferences(from: [
            "margin": margin
        ])
        epubReader.setPreferences(preferences)
        delegate?.settingsDidChange()
    }
    
    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
}
