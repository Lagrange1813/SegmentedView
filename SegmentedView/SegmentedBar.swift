//
//  SegmentedBar.swift
//  SegmentedView
//
//  Created by 张维熙 on 2022/6/6.
//

import UIKit

@objc protocol SegmentedBarDelegate {
    func sliderViewDidMove(_ segmentedBar: SegmentedBar)
    func segmentedBarWillStartScroll(_ segmentedBar: SegmentedBar)
    func segmentedBarDidEndScroll(_ segmentedBar: SegmentedBar)
}

fileprivate enum SegmentedBarState {
    case move
    case still
}

class SegmentedBar: UIControl {
    private var height: CGFloat

    override var bounds: CGRect {
        didSet {
            updateSliderView(with: bounds.width)
        }
    }

    init(frame: CGRect = .zero, barHeight: CGFloat) {
        self.height = barHeight
        super.init(frame: frame)
        configureLayout()
        configureView()
        
        velocityLoop = CADisplayLink(target: self, selector: #selector(listen))
        velocityLoop?.add(to: RunLoop.current, forMode: RunLoop.Mode(rawValue: RunLoop.Mode.common.rawValue))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var defaultTextColor: UIColor = Palette.defaultTextColor {
        didSet {
            updateLabelsColor(with: defaultTextColor, selected: false)
        }
    }

    var highlightTextColor: UIColor = Palette.highlightTextColor {
        didSet {
            updateLabelsColor(with: highlightTextColor, selected: true)
        }
    }

    var segmentsBackgroundColor: UIColor = Palette.segmentedControlBackgroundColor {
        didSet {
            backgroundView.backgroundColor = segmentsBackgroundColor
        }
    }

    var sliderBackgroundColor: UIColor = Palette.sliderColor {
        didSet {
            selectedView.backgroundColor = sliderBackgroundColor
            if !isSliderShadowHidden { selectedView.addShadow(with: sliderBackgroundColor) }
        }
    }

    var font: UIFont = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium) {
        didSet {
            updateLabelsFont(with: font)
        }
    }

    var isSliderShadowHidden: Bool = false {
        didSet {
            updateShadow(with: sliderBackgroundColor, hidden: isSliderShadowHidden)
        }
    }

    private var barState: SegmentedBarState = .still {
        didSet {
            if oldValue == .still && barState == .move {
                delegate?.segmentedBarWillStartScroll(self)
                pursuing = true
            }
            
            if barState == .still {
                pursuing = false
            }
        }
    }
    
    private var selectedIndex: Int = 0

    private var segmentTitles: [String] = []
    private var segmentIcons: [UIImage] = []

    private var countOfSegments: Int {
        segmentTitles.isEmpty ? 1 : segmentTitles.count
    }

    private var segmentWidth: CGFloat {
        return bounds.width / CGFloat(countOfSegments)
    }

    private var correction: CGFloat = 0

    private lazy var containerView = UIView()
    private lazy var backgroundView = UIView()
    private lazy var selectedView = UIView()
    lazy var sliderView = SliderView()

    weak var delegate: SegmentedBarDelegate?
    
    var velocityLoop: CADisplayLink?
    var pursuing: Bool = false

    private func configureLayout() {
        addSubview(containerView)
        containerView.addSubview(backgroundView)
        containerView.addSubview(selectedView)
        containerView.addSubview(sliderView)

        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        backgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        selectedView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    func updateSliderView(with width: CGFloat) {
        let sliderWidth = width / CGFloat(countOfSegments)
        sliderView.frame = CGRect(x: CGFloat(selectedIndex) * sliderWidth,
                                  y: 0, width: sliderWidth, height: height)
    }

    private func configureView() {
        backgroundColor = .clear
        backgroundView.backgroundColor = segmentsBackgroundColor
        selectedView.backgroundColor = sliderBackgroundColor

        let cornerRadius = height / 2
        backgroundView.layer.cornerRadius = cornerRadius
        selectedView.layer.cornerRadius = cornerRadius
        sliderView.cornerRadius = cornerRadius

        selectedView.layer.mask = sliderView.sliderMaskView.layer

        if !isSliderShadowHidden {
            selectedView.addShadow(with: sliderBackgroundColor)
        }

        addTapGesture()
        addDragGesture()
    }

    func setSegmentItems(_ segmentTitles: [String]) {
        guard !segmentTitles.isEmpty else { return }

        self.segmentTitles = segmentTitles

        removeLabels()

        var backgroundLabels: [UILabel] = []
        var selectedLabels: [UILabel] = []

        let firstBackgroundLabel = createLabel(with: segmentTitles[0], selected: false)
        backgroundView.addSubview(firstBackgroundLabel)
        firstBackgroundLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalToSuperview().dividedBy(CGFloat(countOfSegments))
        }

        let firstSelectedLabel = createLabel(with: segmentTitles[0], selected: true)
        selectedView.addSubview(firstSelectedLabel)
        firstSelectedLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalToSuperview().dividedBy(CGFloat(countOfSegments))
        }

        backgroundLabels.append(firstBackgroundLabel)
        selectedLabels.append(firstSelectedLabel)

        for (index, title) in segmentTitles.enumerated().dropFirst() {
            let backgroundLabel = createLabel(with: title, selected: false)
            backgroundView.addSubview(backgroundLabel)
            backgroundLabel.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.leading.equalTo(backgroundLabels[index - 1].snp.trailing)
                make.width.equalToSuperview().dividedBy(CGFloat(countOfSegments))
            }

            backgroundLabels.append(backgroundLabel)

            let selectedLabel = createLabel(with: title, selected: true)
            selectedView.addSubview(selectedLabel)
            selectedLabel.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
                make.leading.equalTo(backgroundLabels[index - 1].snp.trailing)
                make.width.equalToSuperview().dividedBy(CGFloat(countOfSegments))
            }

            selectedLabels.append(selectedLabel)
        }
    }

    private func updateShadow(with color: UIColor, hidden: Bool) {
        if hidden {
            selectedView.removeShadow()
            sliderView.sliderMaskView.removeShadow()
        } else {
            selectedView.addShadow(with: sliderBackgroundColor)
            sliderView.sliderMaskView.addShadow(with: .black)
        }
    }

    // MARK: Configure Labels

    private func removeLabels() {
        backgroundView.subviews.forEach { $0.removeFromSuperview() }
        selectedView.subviews.forEach { $0.removeFromSuperview() }
    }

    private func createLabel(with text: String, selected: Bool) -> UILabel {
        let label = UILabel()

        label.text = text
        label.textAlignment = .center
        label.textColor = selected ? highlightTextColor : defaultTextColor
        label.font = font

        return label
    }

    private func updateLabelsColor(with color: UIColor, selected: Bool) {
        let containerView = selected ? selectedView : backgroundView
        containerView.subviews.forEach { ($0 as? UILabel)?.textColor = color }
    }

    private func updateLabelsFont(with font: UIFont) {
        selectedView.subviews.forEach { ($0 as? UILabel)?.font = font }
        backgroundView.subviews.forEach { ($0 as? UILabel)?.font = font }
    }

    // MARK: Tap gestures

    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    private func addDragGesture() {
        let drag = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        sliderView.addGestureRecognizer(drag)
    }

    @objc private func didTap(tapGesture: UITapGestureRecognizer) {
        moveToNearestSegment(on: tapGesture)
        switch tapGesture.state {
        case .ended,.cancelled, .failed:
            barState = .move
            break
        default:
            break
        }
    }

    @objc private func didPan(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .cancelled, .ended, .failed:
            moveToNearestSegment(on: panGesture)
        case .began:
            barState = .move
            correction = panGesture.location(in: sliderView).x - sliderView.frame.width / 2
        case .changed:
            let location = panGesture.location(in: self)
            sliderView.center.x = location.x - correction
        default:
            break
        }
    }

    // MARK: Slider position
    
    func setSliderView(at location: CGFloat) {
        sliderView.frame.origin.x = location
    }
    
    private func moveToNearestSegment(on gesture: UIGestureRecognizer) {        
        let location = gesture.location(in: self)
        let index = index(at: location)
        move(to: index)
    }

    open func move(to index: Int) {
        animate(to: index)
        selectedIndex = index
    }

    private func index(at point: CGPoint) -> Int {
        var index = Int(point.x / sliderView.frame.width)
        if index < 0 { index = 0 }
        else if index > countOfSegments - 1 { index = countOfSegments - 1 }
        return index
    }

    private func center(at index: Int) -> CGFloat {
        CGFloat(index) * sliderView.frame.width + sliderView.frame.width / 2
    }
    
    private func leftBoundary(at index: Int) -> CGFloat {
        CGFloat(index) * sliderView.frame.width
    }
    
    private func animate(to index: Int) {
        UIView.animate(withDuration: 0.2, animations: {
            self.sliderView.center.x = self.center(at: index)
//            self.sliderView.frame.origin.x = self.leftBoundary(at: index)
        }, completion: { _ in
            self.delegate?.segmentedBarDidEndScroll(self)
            self.barState = .still
        })
        
//        let queue = DispatchQueue.main
//
//        let item = DispatchWorkItem {
//
//            UIView.animate(withDuration: 0.2, animations: {
//                self.sliderView.center.x = self.center(at: index)
//            }, completion: { _ in
//                self.delegate?.segmentedBarDidEndScroll()
//                self.barState = .still
//            })
//        }
//
//        queue.async(execute: item)
    }
    
    // MARK: Monitoring Method
    
    @objc func listen() {
        if pursuing {
//            print(Date())
            delegate?.sliderViewDidMove(self)
        }
    }
}

enum Palette {
    static let defaultTextColor = Palette.colorFromRGB(9, green: 26, blue: 51, alpha: 0.4)
    static let highlightTextColor = UIColor.white
    static let segmentedControlBackgroundColor = Palette.colorFromRGB(237, green: 242, blue: 247, alpha: 0.7)
    static let sliderColor = Palette.colorFromRGB(44, green: 131, blue: 255)

    static func colorFromRGB(_ red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> UIColor {
        func amount(_ amount: CGFloat, with alpha: CGFloat) -> CGFloat {
            return (1 - alpha) * 255 + alpha * amount
        }

        let red = amount(red, with: alpha) / 255
        let green = amount(green, with: alpha) / 255
        let blue = amount(blue, with: alpha) / 255
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
}
