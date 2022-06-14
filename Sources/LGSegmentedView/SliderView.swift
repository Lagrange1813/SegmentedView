//
//  SliderView.swift
//  LGSegmentedView
//
//  Created by 张维熙 on 2022/6/8.
//

import UIKit

class SliderView: UIView {
    let sliderMaskView = UIView()
    
    var style: LGSegmentedViewStyle
    var border: CGFloat = 2

    var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            
            switch style {
            case .modern:
                sliderMaskView.layer.cornerRadius = cornerRadius
            case .classical:
                sliderMaskView.layer.cornerRadius = cornerRadius
            case .imprint:
                break
            }
        }
    }
    
//    var borderWidth: CGFloat = 0 {
//        didSet {
//            layer.borderWidth = borderWidth
//            sliderMaskView.layer.borderWidth = borderWidth
//        }
//    }
//
//    var borderColor: UIColor = .clear {
//        didSet {
//            layer.borderColor = borderColor.cgColor
//            sliderMaskView.layer.borderColor = borderColor.cgColor
//        }
//    }
    
    override var frame: CGRect {
        didSet {
            switch style {
            case .modern:
                sliderMaskView.frame = frame
            case .classical:
                sliderMaskView.frame = CGRect(x: frame.origin.x + border,
                                              y: frame.origin.y + border,
                                              width: frame.width - 2*border,
                                              height: frame.height - 2*border)
            case .imprint:
                break
            }
        }
    }

    override var center: CGPoint {
        didSet {
            sliderMaskView.center = center
        }
    }

    init(_ style: LGSegmentedViewStyle = .modern) {
        self.style = style
        super.init(frame: .zero)
        
        sliderMaskView.backgroundColor = .white
        
        switch style {
        case .modern:
            sliderMaskView.addShadow(.black)
        case .classical:
            sliderMaskView.addShadow(.black, style: .classical)
        case .imprint:
            break
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
