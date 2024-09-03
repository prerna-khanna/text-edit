//
//  CustomSwipeGestureRecognizer.swift
//  text edit
//
//  Created by Prerna Khanna on 9/1/24.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class CustomSwipeGestureRecognizer: UIGestureRecognizer {
    enum SwipeDirection {
        case up, down, unknown
    }
    
    private let requiredMovement: CGFloat = 30
    private var initialTouchPoint: CGPoint?
    private var swipeDirection: SwipeDirection = .unknown
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first {
            initialTouchPoint = touch.location(in: self.view)
            swipeDirection = .unknown
        }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first, let initialPoint = initialTouchPoint {
            let currentPoint = touch.location(in: self.view)
            let verticalMovement = currentPoint.y - initialPoint.y
            
            if abs(verticalMovement) >= requiredMovement {
                swipeDirection = verticalMovement > 0 ? .down : .up
                state = .recognized
            }
        }
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if swipeDirection == .unknown {
            state = .failed
        }
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
        super.touchesCancelled(touches, with: event)
    }
    
    override func reset() {
        initialTouchPoint = nil
        swipeDirection = .unknown
        super.reset()
    }
    
    func direction() -> SwipeDirection {
        return swipeDirection
    }
}
