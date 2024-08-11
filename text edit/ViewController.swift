//
//  ViewController.swift
//  text edit
//
//  By Monalika P
//

// Control going into handleRotorSearch function - Done
// Direction info relayed to handleRotorSerach function - Done
// Custom Words, Custom Char and Custom Lines - Done
// nextWord, NextChar, PreviousWord, PreviousChar - Done

// To Do - Update the corresponding rotor option based on the rotor option selected by the user

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
    var direction: UIAccessibilityCustomRotor.Direction = .next
    var activeRotorName: String? // Store the name of the currently active rotor

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleVoiceOverFocusChanged(notification:)),
                                               name: UIAccessibility.elementFocusedNotification,
                                               object: nil)
        setupHideKeyboardOnTap()

        let customWord = UIAccessibilityCustomRotor(name: "Custom Word") { predicate in
            self.activeRotorName = "Custom Word"  // Set when this rotor is selected
            print("Rotor selected: \(self.activeRotorName!)")
            return self.handleRotorSearchWord(predicate: predicate)
        }

        let customChar = UIAccessibilityCustomRotor(name: "Custom Character") { predicate in
            self.activeRotorName = "Custom Character"  // Set when this rotor is selected
            print("Rotor selected: \(self.activeRotorName!)")
            return self.handleRotorSearchChar(predicate: predicate)
        }
        
        let customLine = UIAccessibilityCustomRotor(name: "Custom Line") { predicate in
            self.activeRotorName = "Custom Line"  // Set when this rotor is selected
            print("Rotor selected: \(self.activeRotorName!)")
            return self.handleRotorSearchWord(predicate: predicate)
        }


        // Assign the custom rotor to the view
        view.accessibilityCustomRotors = [customWord, customChar, customLine]

        // Start monitoring device motion for tap detection
        startDeviceMotionUpdates()
    }

    private func handleRotorSearchWord(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        print("---------------------Inside handleRotorSearchWord function -------------------------------")
        direction = predicate.searchDirection

        var nextElement: UITextRange?

        if direction == .next {
            print("Next")
            nextElement = nextWord()
        } else if direction == .previous {
            print("Previous")
            nextElement = previousWord()
        }

        if let nextElement = nextElement {
            return UIAccessibilityCustomRotorItemResult(targetElement: userInputTextField, targetRange: nextElement)
        } else {
            return nil // No more elements found in the direction
        }
    }

    private func handleRotorSearchChar(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        print("------------------Inside handleRotorSearchChar function -------------------------------")
        direction = predicate.searchDirection

        var nextElement: UITextRange?

        if direction == .next {
            print("Next")
            nextElement = nextCharacter()
        } else if direction == .previous {
            print("Previous")
            nextElement = previousCharacter()
        }
        if let nextElement = nextElement {
            return UIAccessibilityCustomRotorItemResult(targetElement: userInputTextField, targetRange: nextElement)
        } else {
            return nil // No more elements found in the direction
        }
    }
    
    private func handleRotorSearchLine(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        print("------------------Inside handleRotorSearchLine function -------------------------------")
        direction = predicate.searchDirection

        var nextElement: UITextRange?

        if direction == .next {
            print("Next")
            nextElement = nextLine()
        } else if direction == .previous {
            print("Previous")
            nextElement = previousLine()
        }
        if let nextElement = nextElement {
            return UIAccessibilityCustomRotorItemResult(targetElement: userInputTextField, targetRange: nextElement)
        } else {
            return nil // No more elements found in the direction
        }
    }
    
    private func nextLine() -> UITextRange? {
        print("Inside Next Line")
        return nil
    }
    
    private func previousLine() -> UITextRange? {
        print("Inside Previous Line")
        return nil
    }

    private func nextWord() -> UITextRange? {
        print("Inside Next Word")

        guard let textRange = userInputTextField.selectedTextRange else { return nil }

        // Get the current word range
        if let currentWordRange = userInputTextField.tokenizer.rangeEnclosingPosition(textRange.start, with: .word, inDirection: UITextDirection.storage(.forward)) {
            let currentWord = userInputTextField.text(in: currentWordRange) ?? ""
            print("Current word: \(currentWord)")

            // Find the next word range
            if let positionAfterCurrentWord = userInputTextField.position(from: currentWordRange.end, offset: 1),
               let nextWordRange = userInputTextField.tokenizer.rangeEnclosingPosition(positionAfterCurrentWord, with: .word, inDirection: UITextDirection.storage(.forward)) {

                // Move the cursor to the next word
                userInputTextField.selectedTextRange = nextWordRange

                // Schedule VoiceOver announcement asynchronously
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Get the text in the new selected range and make VoiceOver read it
                    if let selectedText = self.userInputTextField.text(in: nextWordRange) {
                        print("Next word: \(selectedText)")
                        UIAccessibility.post(notification: .announcement, argument: selectedText)
                    } else {
                        print("No next word found.")
                        UIAccessibility.post(notification: .announcement, argument: "No next word found.")
                    }
                }

                return nextWordRange
            } else {
                print("No next word found.")
                UIAccessibility.post(notification: .announcement, argument: "No next word found.")
            }
        }
        return nil
    }

    private func previousWord() -> UITextRange? {
        print("Inside Previous Word")

        guard let textRange = userInputTextField.selectedTextRange else { return nil }

        // Get the current word range
        if let currentWordRange = userInputTextField.tokenizer.rangeEnclosingPosition(textRange.start, with: .word, inDirection: UITextDirection.storage(.backward)) {
            let currentWord = userInputTextField.text(in: currentWordRange) ?? ""
            print("Current word: \(currentWord)")

            // Find the previous word range
            if let positionBeforeCurrentWord = userInputTextField.position(from: currentWordRange.start, offset: -1),
               let previousWordRange = userInputTextField.tokenizer.rangeEnclosingPosition(positionBeforeCurrentWord, with: .word, inDirection: UITextDirection.storage(.backward)) {
                // Move the cursor to the previous word
                userInputTextField.selectedTextRange = previousWordRange

                // Allow some time for the text range to update before announcing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Get the text in the new selected range and make VoiceOver read it
                    if let selectedText = self.userInputTextField.text(in: previousWordRange) {
                        print("Previous word: \(selectedText)")
                        UIAccessibility.post(notification: .announcement, argument: selectedText)
                    } else {
                        print("No previous word found.")
                        UIAccessibility.post(notification: .announcement, argument: "No previous word found.")
                    }
                }
                return previousWordRange
            } else {
                print("No previous word found.")
                UIAccessibility.post(notification: .announcement, argument: "No previous word found.")
            }
        }
        return nil
    }

    private func nextCharacter() -> UITextRange?  {
        print("Inside Next Character")

        guard let textRange = userInputTextField.selectedTextRange else { return nil }

        // Get the current character
        if let currentPosition = userInputTextField.position(from: textRange.start, offset: 0),
           let nextPosition = userInputTextField.position(from: currentPosition, offset: 1),
           let currentCharRange = userInputTextField.textRange(from: currentPosition, to: nextPosition) {
            let currentCharacter = userInputTextField.text(in: currentCharRange) ?? ""
            print("Current character: \(currentCharacter)")

            // Find the next character range
            if let positionAfterCurrentChar = userInputTextField.position(from: currentPosition, offset: 1),
               let nextCharPosition = userInputTextField.position(from: positionAfterCurrentChar, offset: 1),
               let nextCharRange = userInputTextField.textRange(from: positionAfterCurrentChar, to: nextCharPosition) {
                let nextCharacter = userInputTextField.text(in: nextCharRange) ?? ""
                print("Next character: \(nextCharacter)")

                // Move the cursor to the next character
                userInputTextField.selectedTextRange = nextCharRange

                // Allow some time for the text range to update before announcing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Get the text in the new selected range and make VoiceOver read it
                    if let selectedText = self.userInputTextField.text(in: nextCharRange) {
                        print("Selected character: \(selectedText)")
                        UIAccessibility.post(notification: .announcement, argument: selectedText)
                    } else {
                        print("No next character found.")
                        UIAccessibility.post(notification: .announcement, argument: "No next character found.")
                    }
                }
                return nextCharRange
            } else {
                print("No next character found.")
                UIAccessibility.post(notification: .announcement, argument: "No next character found.")
            }
        }
        return nil
    }

    private func previousCharacter() -> UITextRange? {
        print("Inside Previous Character")

        guard let textRange = userInputTextField.selectedTextRange else { return nil }

        // Get the current character
        if let currentPosition = userInputTextField.position(from: textRange.start, offset: 0),
           let previousPosition = userInputTextField.position(from: currentPosition, offset: -1),
           let currentCharRange = userInputTextField.textRange(from: previousPosition, to: currentPosition) {
            let currentCharacter = userInputTextField.text(in: currentCharRange) ?? ""
            print("Current character: \(currentCharacter)")

            // Find the previous character range
            if let positionBeforeCurrentChar = userInputTextField.position(from: currentPosition, offset: -1),
               let previousCharRange = userInputTextField.textRange(from: positionBeforeCurrentChar, to: currentPosition) {
                let previousCharacter = userInputTextField.text(in: previousCharRange) ?? ""
                print("Previous character: \(previousCharacter)")

                // Move the cursor to the previous character
                userInputTextField.selectedTextRange = previousCharRange

                // Allow some time for the text range to update before announcing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Get the text in the new selected range and make VoiceOver read it
                    if let selectedText = self.userInputTextField.text(in: previousCharRange) {
                        print("Selected character: \(selectedText)")
                        UIAccessibility.post(notification: .announcement, argument: selectedText)
                    } else {
                        print("No previous character found.")
                        UIAccessibility.post(notification: .announcement, argument: "No previous character found.")
                    }
                }
                return previousCharRange
            } else {
                print("No previous character found.")
                UIAccessibility.post(notification: .announcement, argument: "No previous character found.")
            }
        }
        return nil
    }

    private func startDeviceMotionUpdates() {
            guard motionManager.isDeviceMotionAvailable else { return }
            print("motion working!!!")
            
            motionManager.deviceMotionUpdateInterval = 0.5
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion else { return }
                self.detectTap(motion: motion)
            }
        }
        
    private func detectTap(motion: CMDeviceMotion) {
        // Simple tap detection logic based on acceleration
        let acceleration = motion.userAcceleration
        let threshold: Double = 0.2 // Set a suitable threshold
        let threshold1: Double = 0.3
        let threshold2: Double = 0.8
        
        if let activeRotor = activeRotorName {
            switch activeRotor {
            case "Custom Word":
                if (abs(acceleration.x) > threshold && abs(acceleration.x) <= threshold1) ||
                    (abs(acceleration.y) > threshold && abs(acceleration.y) <= threshold1) ||
                    (abs(acceleration.z) > threshold && abs(acceleration.z) <= threshold1) {
                    print("Detected next tap, moving to next word")
                    direction = .next
                    
                } else if (abs(acceleration.x) > threshold1 && abs(acceleration.x) <= threshold2) ||
                            (abs(acceleration.y) > threshold1 && abs(acceleration.y) <= threshold2) ||
                            (abs(acceleration.z) > threshold1 && abs(acceleration.z) <= threshold2) {
                    print("Detected previous tap, moving to previous word")
                    direction = .previous
                }
                let predicate = UIAccessibilityCustomRotorSearchPredicate()
                predicate.searchDirection = direction
                _ = handleRotorSearchWord(predicate: predicate)

            case "Custom Character":
                if (abs(acceleration.x) > threshold && abs(acceleration.x) <= threshold1) ||
                    (abs(acceleration.y) > threshold && abs(acceleration.y) <= threshold1) ||
                    (abs(acceleration.z) > threshold && abs(acceleration.z) <= threshold1) {
                    print("Detected next tap, moving to next character")
                    direction = .next
                    
                } else if (abs(acceleration.x) > threshold1 && abs(acceleration.x) <= threshold2) ||
                            (abs(acceleration.y) > threshold1 && abs(acceleration.y) <= threshold2) ||
                            (abs(acceleration.z) > threshold1 && abs(acceleration.z) <= threshold2) {
                    print("Detected previous tap, moving to previous character")
                    direction = .previous
                }
                let predicate = UIAccessibilityCustomRotorSearchPredicate()
                predicate.searchDirection = direction
                _ = handleRotorSearchChar(predicate: predicate)
                
            case "Custom Line":
                if (abs(acceleration.x) > threshold && abs(acceleration.x) <= threshold1) ||
                    (abs(acceleration.y) > threshold && abs(acceleration.y) <= threshold1) ||
                    (abs(acceleration.z) > threshold && abs(acceleration.z) <= threshold1) {
                    print("Detected next tap, moving to next character")
                    direction = .next
                    
                } else if (abs(acceleration.x) > threshold1 && abs(acceleration.x) <= threshold2) ||
                            (abs(acceleration.y) > threshold1 && abs(acceleration.y) <= threshold2) ||
                            (abs(acceleration.z) > threshold1 && abs(acceleration.z) <= threshold2) {
                    print("Detected previous tap, moving to previous character")
                    direction = .previous
                }
                let predicate = UIAccessibilityCustomRotorSearchPredicate()
                predicate.searchDirection = direction
                _ = handleRotorSearchLine(predicate: predicate)


            default:
                print("No action for the active rotor: \(activeRotor)")
            }
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
        print("Inside handleVoiceOverFocusChanged")
        guard isRecording,
              let userInfo = notification.userInfo,
              let focusedElement = userInfo[UIAccessibility.focusedElementUserInfoKey] as? UIView else {
            return
        }
        print("before customRotor")
        if let customRotors = view.accessibilityCustomRotors {
                for rotor in customRotors {
                    print(focusedElement.accessibilityLabel)
                    print(rotor.name)
                    if focusedElement.accessibilityLabel == rotor.name {
                        activeRotorName = rotor.name
                        print("Rotor focus changed to: \(rotor.name)")
                        break
                    }
                }
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
