//
//  EditScanCornerView.swift
//  WeScan
//
//  Created by Boris Emorine on 3/5/18.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import UIKit

/// A UIView used by corners of a quadrilateral that is aware of its position.
final public class EditScanCornerView: UIView {
    
    let position: CornerPosition
    
    /// The image to display when the corner view is highlighted.
    private var image: UIImage?
    private(set) var isHighlighted = false
    
    lazy private var circleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.lineWidth = 1.0
        return layer
    }()
    
//    lazy private var circleLayer2: CAShapeLayer = {
//        let layer = CAShapeLayer()
//        layer.fillColor = UIColor.clear.cgColor
//        layer.strokeColor = UIColor.white.cgColor
//        layer.lineWidth = 1.0
//        return layer
//    }()
    
    init(frame: CGRect, position: CornerPosition) {
        self.position = position
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        clipsToBounds = true
        layer.addSublayer(circleLayer)
//        layer.addSublayer(circleLayer2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2.0
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let bezierPath = UIBezierPath(ovalIn: rect.insetBy(dx: circleLayer.lineWidth, dy: circleLayer.lineWidth))
        circleLayer.frame = rect
        circleLayer.path = bezierPath.cgPath
        
//        var rect2 = rect
//        rect2.size.width *= 0.5
//        rect2.size.height *= 0.5
//        let bezierPath2 = UIBezierPath(ovalIn: rect2.insetBy(dx: circleLayer2.lineWidth, dy: circleLayer2.lineWidth))
//        circleLayer2.frame = rect.scaleAndCenter(withRatio: 0.5)
//        circleLayer2.path = bezierPath2.cgPath

        image?.draw(in: rect)
    }
    
    func highlightWithImage(_ image: UIImage) {
        isHighlighted = true
        self.image = image
        self.setNeedsDisplay()
    }
    
    func reset() {
        isHighlighted = false
        image = nil
        setNeedsDisplay()
    }
    
}
