//
//  ViewController.swift
//  text edit
//
//  Created by Prerna Khanna on 5/22/24.
//

import UIKit
import CoreMotion

class ViewController: UIViewController, UITextFieldDelegate {
    
    private let motionManager = CMMotionManager()

    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var recordSwitch: UISwitch!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var userInputTextField: UITextField!
    @IBOutlet weak var optionSlider: UISlider!
    @IBOutlet weak var sliderValueLabel: UILabel!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!

    var isRecording = false
    var touchCoordinates = [String]()
    var selectedOption = 1 // Default to option 1

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleVoiceOverFocusChanged(notification:)),
                                               name: UIAccessibility.elementFocusedNotification,
                                               object: nil)
        setupHideKeyboardOnTap()
        
        // Define a custom rotor for navigating between custom elements
        let customRotor = UIAccessibilityCustomRotor(name: "Custom Navigation") { predicate in
            return self.handleRotorSearch(predicate: predicate)
        }
        
        // Assign the custom rotor to the view
        view.accessibilityCustomRotors = [customRotor]
        
        // Start monitoring device motion for tap detection
        startDeviceMotionUpdates()
    }
    
    private func handleRotorSearch(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
            guard let currentElement = predicate.currentItem.targetElement as? UIView else {
                print("Current element is not a UIView.")
                return nil
            }
            let direction = predicate.searchDirection
            
            // Find the next or previous element based on the direction
            guard let nextElement = findNextElement(from: currentElement, direction: direction) else {
                print("Next element not found.")
                return nil
            }
            
            print("Navigating to next element: \(String(describing: nextElement.accessibilityLabel))")
            return UIAccessibilityCustomRotorItemResult(targetElement: nextElement, targetRange: nil)
        }
        
        private func findNextElement(from currentElement: UIView, direction: UIAccessibilityCustomRotor.Direction) -> UIView? {
            let elements: [UIView] = [label1, label2, label3] //  actual UI elements
            guard let currentIndex = elements.firstIndex(of: currentElement) else {
                print("Current element not found in elements array.")
                return nil
            }
            
            let nextIndex: Int
            if direction == .next {
                nextIndex = (currentIndex + 1) % elements.count
            } else {
                nextIndex = (currentIndex - 1 + elements.count) % elements.count
            }
            
            return elements[nextIndex]
        }

    
    private func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        print("motion working!!!")
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            self.detectTap(motion: motion)
        }
    }
    
    private func detectTap(motion: CMDeviceMotion) {
        // Simple tap detection logic based on acceleration
        let acceleration = motion.userAcceleration
        let threshold: Double = 0.2 // Set a suitable threshold
    
        
        if abs(acceleration.x) > threshold || abs(acceleration.y) > threshold || abs(acceleration.z) > threshold {
            // Detected a tap-like motion, trigger the rotor
            print("Tap detected with acceleration: \(acceleration)")
            UIAccessibility.post(notification: .pageScrolled, argument: nil)
        }
    }
    
    func setupHideKeyboardOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc func hideKeyboard() {
        view.endEditing(true)
    }

    func setupUI() {
        recordSwitch.isOn = false
        userIdTextField.delegate = self
        userInputTextField.delegate = self
        setupSlider()
    }

    func setupSlider() {
        optionSlider.minimumValue = 1
        optionSlider.maximumValue = 5
        optionSlider.value = 1 // Start with the first option selected
        optionSlider.isContinuous = true // Update value continuously as the user slides
        updateSliderValueLabel() // Initial update for the label
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let roundedValue = round(sender.value)
        sender.value = roundedValue // Snap to integer values
        selectedOption = Int(roundedValue)
        updateOptionDisplay()
        updateSliderValueLabel() // Update the label whenever the slider value changes
        userInputTextField.text = "" // Clear the text field when option changes
    }

    func updateSliderValueLabel() {
        sliderValueLabel.text = "Option \(Int(optionSlider.value))"
    }

    func updateOptionDisplay() {
        let options = ["See what concerts we have for you in your city.",
           "The injury is more serious than the Panthers first expected.",
           "History repeated itself last season when Barcelona beat Madrid.",
           "The law enforcement has a responsibility for the safety of the public.",
           "He pleaded guilty in February under an agreement with the government."
        ]
        messageLabel.text = options[selectedOption - 1]
    }

    @IBAction func toggleRecording(_ sender: UISwitch) {
        isRecording = sender.isOn
        if !isRecording {
            saveCoordinatesToFile()
        }
    }

    @objc func handleVoiceOverFocusChanged(notification: Notification) {
        guard isRecording,
              let userInfo = notification.userInfo,
              let focusedElement = userInfo[UIAccessibility.focusedElementUserInfoKey] as? UIView else {
            return
        }
        let point = focusedElement.accessibilityActivationPoint
        let coordinate = "VoiceOver Focus X: \(point.x), Y: \(point.y)"
        touchCoordinates.append(coordinate)
        print(coordinate)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        recordTouches(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        recordTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        recordTouches(touches)
    }

    func recordTouches(_ touches: Set<UITouch>) {
        guard isRecording, let touch = touches.first else { return }
        let position = touch.location(in: view)
        let coordinate = "Touch X: \(position.x), Y: \(position.y)"
        touchCoordinates.append(coordinate)
        print(coordinate)
    }

    func saveCoordinatesToFile() {
        guard let userId = userIdTextField.text, !userId.isEmpty else {
            print("User ID is empty")
            return
        }
        if touchCoordinates.isEmpty {
            print("No coordinates to save")
            return
        }

        let fileName = "User_\(userId)_Option\(selectedOption).txt"
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Failed to find document directory")
            return
        }
        let filePath = directory.appendingPathComponent(fileName)

        do {
            try touchCoordinates.joined(separator: "\n").write(to: filePath, atomically: true, encoding: .utf8)
            print("Coordinates saved to: \(filePath)")
            touchCoordinates.removeAll()
        } catch {
            print("Failed to save coordinates: \(error)")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
