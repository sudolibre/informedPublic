//
//  LegislationStatusView.swift
//  informedPublic
//
//  Created by Jonathon Day on 2/17/17.
//  Copyright © 2017 dayj. All rights reserved.
//

import Foundation
import UIKit

class LegislationStatusView: UIView {
    var statusCircles: [CAShapeLayer] = []
    
    var status: Status = .introduced {
        didSet {
            let circlePairs = zip(statusCircles, statusCircles.dropFirst())
            for (index, (circle, nextCircle)) in circlePairs.enumerated() {
                let count = index + 1
                if count < status.rawValue {
                    animateStatusCircleForStatus(count: Double(count), circle: circle, nextCircle: nextCircle)
                } else if count == status.rawValue {
                    animateStatusCircleForStatus(count: Double(count), circle: circle, nextCircle: nil)
                } else {
                    break
                }
            }
        }
    }
    
    enum Status: Int {
        case introduced = 1
        case house = 2
        case senate = 3
        case law = 4
        
        static var count: Int {
            return 4
        }
        
        static var descriptions: [String] {
            return ["Introduced", "House", "Senate", "Law"]
        }
    }
    
    func drawStatusCircles() {
        func centerPointForIndex(_ index: Int) -> CGPoint {
            let centerY = bounds.midY
            let centerX = CGFloat(index) * (bounds.width / CGFloat(Status.count)) - bounds.width / CGFloat(Status.count * 2)
            return CGPoint(x: centerX , y: centerY)
        }
        
        func getCircle(index: Int) -> CAShapeLayer {
            let centerPoint = centerPointForIndex(index)
            let radius = CGFloat(20)
            
            let circleLayer: CAShapeLayer = {
                let circlePath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: CGFloat(0), endAngle:CGFloat(M_PI * 2), clockwise: true)
                let layer = CAShapeLayer()
                layer.path = circlePath.cgPath
                layer.fillColor = UIColor.lightGray.cgColor
                layer.strokeColor = UIColor.lightGray.cgColor
                layer.lineWidth = 2.0
                layer.strokeEnd = 0.0
                return layer
            }()
            
            return circleLayer
        }
        
        for i in 1...Status.count {
            let circle = getCircle(index: i)
            layer.addSublayer(circle)
            statusCircles.append(circle)
            let descriptionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 15))
            descriptionLabel.center = CGPoint(x: (circle.path?.boundingBoxOfPath.midX)!, y: ((circle.path?.boundingBoxOfPath.minY)! - 10 - descriptionLabel.bounds.midY))
            print(descriptionLabel.center)
            descriptionLabel.text = Status.descriptions[i - 1]
            descriptionLabel.textColor = UIColor.black
            descriptionLabel.font = UIFont.systemFont(ofSize: 12.0)
            self.addSubview(descriptionLabel)
        }
        
    }
    
    
    func animateStatusCircleForStatus(count: Double, circle: CAShapeLayer, nextCircle: CAShapeLayer?) {
        let fillAnimation: CABasicAnimation = {
            let animation = CABasicAnimation(keyPath: "fillColor")
            animation.fromValue = UIColor.gray.cgColor
            animation.toValue = UIColor.green.cgColor
            animation.duration = 0.5
            animation.fillMode = kCAFillModeForwards
            animation.isRemovedOnCompletion = false
            return animation
        }()
        
        let strokeAnimation: CABasicAnimation = {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = CGFloat(0)
            animation.toValue = CGFloat(1)
            animation.duration = 0.5
            animation.fillMode = kCAFillModeForwards
            animation.isRemovedOnCompletion = false
            return animation
        }()
        
        var checkStrokeAnimation: CABasicAnimation = {
            let checkAnimation = CABasicAnimation(keyPath: "strokeEnd")
            checkAnimation.fromValue = CGFloat(0.1)
            checkAnimation.toValue = CGFloat(0.9)
            checkAnimation.duration = 0.70
            checkAnimation.fillMode = kCAFillModeForwards
            checkAnimation.isRemovedOnCompletion = false
            return checkAnimation
        }()
        
        let radius = circle.path!.boundingBoxOfPath.width / 2
        let centerPoint = CGPoint(x: (circle.path?.boundingBoxOfPath.midX)!, y: (circle.path?.boundingBoxOfPath.midY)!)
        print(centerPoint)
        let checkLayer: CAShapeLayer  = {
            let path = UIBezierPath()
            let halfRadius = radius / 2
            path.move(to: CGPoint(x: centerPoint.x - halfRadius, y: centerPoint.y))
            path.addLine(to: CGPoint(x: centerPoint.x, y: centerPoint.y + halfRadius))
            path.move(to: CGPoint(x: centerPoint.x, y: centerPoint.y + halfRadius))
            path.addLine(to: CGPoint(x: centerPoint.x + halfRadius, y: centerPoint.y - halfRadius))
            let layer = CAShapeLayer()
            layer.path = path.cgPath
            layer.strokeStart = 0.1
            layer.strokeEnd = CGFloat(0)
            layer.lineWidth = 2
            layer.strokeColor = UIColor.white.cgColor
            return layer
        }()
        
        
        
        checkStrokeAnimation.beginTime = CACurrentMediaTime() + checkStrokeAnimation.duration * count
        strokeAnimation.beginTime = CACurrentMediaTime() + strokeAnimation.duration * count
        fillAnimation.beginTime = CACurrentMediaTime() + fillAnimation.duration * count
        
        circle.addSublayer(checkLayer)
        checkLayer.add(checkStrokeAnimation, forKey: "strokeEnd")
        circle.add(strokeAnimation, forKey: "strokeEnd")
        circle.add(fillAnimation, forKey: "fillColor")
        
        //Line layer to connect active circles
        if let nextCircle = nextCircle {
            let lineLayer: CAShapeLayer = {
                let nextCircleCenterPoint = CGPoint(x: (nextCircle.path?.boundingBoxOfPath.midX)!, y: (nextCircle.path?.boundingBoxOfPath.midY)!)
                let circleRightEdge = centerPoint.applying(CGAffineTransform(translationX: radius, y: 0))
                let nextCircleLeftEdge = nextCircleCenterPoint.applying(CGAffineTransform(translationX: -radius, y: 0))
                let path = UIBezierPath()
                path.move(to: circleRightEdge)
                path.addLine(to: nextCircleLeftEdge)
                let layer = CAShapeLayer()
                layer.path = path.cgPath
                layer.lineWidth = 2
                layer.strokeEnd = CGFloat(0)
                layer.strokeColor = UIColor.lightGray.cgColor
                return layer
            }()
            //Base animations for active circles
            
            lineLayer.add(strokeAnimation, forKey: "strokeEnd")
            layer.addSublayer(lineLayer)
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        drawStatusCircles()
    }
}
