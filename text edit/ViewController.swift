// control going into handleRotorSearch function - obtaining directions but the Control not going to the UI Elements label1, label2, lable3

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
//    var direction: UIAccessibilityCustomRotor.Direction?
    var direction: UIAccessibilityCustomRotor.Direction = .next
    var currentMode = "words"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleVoiceOverFocusChanged(notification:)),
                                               name: UIAccessibility.elementFocusedNotification,
                                               object: nil)
        setupHideKeyboardOnTap()
        
        // Define a custom rotor for navigating between custom elements
        label1.accessibilityIdentifier = "label1"
        label2.accessibilityIdentifier = "label2"
        label3.accessibilityIdentifier = "label3"
        
        print("Label1 type: \(type(of: label1))")
        print("Label2 type: \(type(of: label2))")
        print("Label3 type: \(type(of: label3))")
        
        let customRotor = UIAccessibilityCustomRotor(name: "Custom Navigation") { predicate in
            return self.handleRotorSearch(predicate: predicate)
        }
        
        // Assign the custom rotor to the view
        view.accessibilityCustomRotors = [customRotor]
        
        // Start monitoring device motion for tap detection
        startDeviceMotionUpdates()
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        
        print("Inside Handle Swipe")
        guard let swipedLabel = gesture.view as? UILabel else { return }
        print(swipedLabel)
        switch swipedLabel {
            case label1:
                switch gesture.direction {
                case .up:
                    previousWord()
                case .down:
                    nextWord()
                default:
                    break
                }
            case label2:
                // You can implement different logic for label2 if needed
                print("Swiped on label2, implement relevant functionality here.")
            default:
                break
            }
    }

//    private func handleRotorSearch(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
//            // Shows the label info when swipped up - correct one
//            print("Inside handleRotorSearch function ")
//            print(predicate.currentItem.targetElement)
//            direction = predicate.searchDirection
//            if direction == .next {
//                print("Next")
//            } else if direction == .previous{
//                print("Previous")
//            } else {
//                print("God knows")
//            }
//        
//            guard let currentElement = predicate.currentItem.targetElement as? UIView else {
//                print("Current element is not a UIView. Defaulting to label1.")
//                return UIAccessibilityCustomRotorItemResult(targetElement: label1, targetRange: nil)
//            }
//    
//            print("Current element: \(String(describing: currentElement.accessibilityIdentifier))")
//    
//            if ![label1, label2, label3].contains(currentElement) {
//                print("Current element is not a target label. Defaulting to label1.")
//                return UIAccessibilityCustomRotorItemResult(targetElement: label1, targetRange: nil)
//            }
//    
//            guard let nextElement = findNextElement(from: currentElement, direction: direction) else {
//                print("Next element not found.")
//                return nil
//            }
//    
//            print("Next element: \(String(describing: nextElement.accessibilityIdentifier))")
//    
//            if nextElement.accessibilityIdentifier == "label1" {
//                wordsFunction()  // Call Word() function if label1 is focused
//            } else if nextElement.accessibilityIdentifier == "label2" {
//                charactersFunction()  // Call Character() function if label2 is focused
//            }
//            else if nextElement.accessibilityIdentifier == "label3" {
//                LinesFunction()  // Call LinesFunction() function if label3 is focused
//            }
//            return UIAccessibilityCustomRotorItemResult(targetElement: nextElement, targetRange: nil)
//        }
//    private func triggerRotorUpdate(using direction: UIAccessibilityCustomRotor.Direction) {
//            //guard let focusedElement = UIAccessibility.focusedElement() as? UIView else { return }
//            print("Inside triggerRotorUpdate")
//            
//            let predicate = UIAccessibilityCustomRotorSearchPredicate()
//            predicate.searchDirection = direction
//            // Manually trigger the rotor search logic
//            _ = handleRotorSearch(predicate: predicate)
//        }
    
    private func handleRotorSearch(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
            print("Inside handleRotorSearch function -------------------------------")
            direction = predicate.searchDirection

            // Log direction for debugging
            if direction == .next {
                print("Next")
            } else if direction == .previous {
                print("Previous")
            }

            let elements: [UILabel] = [label1, label2, label3]
        
            // This gives the next labels, but then it does not go inside the text box
            guard let currentElement = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? UILabel else {
                        return nil
            }
//            // Get the currently focused element, if any
//            guard let currentElement = predicate.currentItem.targetElement as? UILabel else {
//                print("No current focus found. Defaulting to label1.")
//                print("targetElement type: \(type(of: predicate.currentItem.targetElement))")
//                if predicate.currentItem.targetElement == nil {
//                    print("predicate.currentItem.targetElement is nil")
//                } else {
//                    print("predicate.currentItem.targetElement is not nil")
//                }
//                setFocus(to: label1)
//                return UIAccessibilityCustomRotorItemResult(targetElement: label1, targetRange: nil)
//            }
//
//            print("Current element: \(String(describing: currentElement.accessibilityIdentifier))")
//
//            // Check if the current element is one of the target labels
            guard let currentIndex = elements.firstIndex(of: currentElement) else {
                print("Current element is not a target label. Defaulting to label1.")
                setFocus(to: label1)
                return UIAccessibilityCustomRotorItemResult(targetElement: label1, targetRange: nil)
            }

            // Determine the next element based on direction
            let nextIndex: Int
            if direction == .next {
                nextIndex = (currentIndex + 1) % elements.count
            } else {
                nextIndex = (currentIndex - 1 + elements.count) % elements.count
            }
            
            let nextElement = elements[nextIndex]

            print("Next element: \(String(describing: nextElement.accessibilityIdentifier))")
        
            let currentElement1 = nextElement

            // Set focus to the determined next element
            setFocus(to: currentElement1)

            // Perform associated actions
            if currentElement1.accessibilityIdentifier == "label1" {
                wordsFunction()
            } else if currentElement1.accessibilityIdentifier == "label2" {
                charactersFunction()
            } else if currentElement1.accessibilityIdentifier == "label3" {
                LinesFunction()
            }

            return UIAccessibilityCustomRotorItemResult(targetElement: currentElement1, targetRange: nil)
        }

        private func setFocus(to element: UIView) {
            UIAccessibility.post(notification: .layoutChanged, argument: element)
            element.becomeFirstResponder()
            print("Current focus is on element: \(String(describing: element.accessibilityIdentifier))")

        }

        private func wordsFunction() {
            print("Words function called.")
            currentMode = "Words"
        }

        private func charactersFunction() {
            print("Characters function called.")
            currentMode = "Characters"
        }
    
        private func LinesFunction() {
            print("Lines function called.")
            currentMode = "Lines"
        }
        
        private func findNextElement(from currentElement: UIView, direction: UIAccessibilityCustomRotor.Direction) -> UIView? {
            let elements: [UIView] = [label1, label2, label3] //  actual UI elements
            guard let currentIndex = elements.firstIndex(of: currentElement) else {
                print("Current element not found in elements array.")
                return nil
            }
            
            let nextIndex: Int
            if direction == .next {
                print("Next")
                nextIndex = (currentIndex + 1) % elements.count
            } else {
                print("Previous")
                nextIndex = (currentIndex - 1 + elements.count) % elements.count
            }
            
            return elements[nextIndex]
        }
    
    private func nextWord() {
            print("Inside Next Word")

            guard let textRange = userInputTextField.selectedTextRange else { return }

            // Get the current word range
            if let currentWordRange = userInputTextField.tokenizer.rangeEnclosingPosition(textRange.start, with: .word, inDirection: UITextDirection.storage(.forward)) {
                let currentWord = userInputTextField.text(in: currentWordRange) ?? ""
                print("Current word: \(currentWord)")

                // Find the next word range
                if let positionAfterCurrentWord = userInputTextField.position(from: currentWordRange.end, offset: 1),
                    let nextWordRange = userInputTextField.tokenizer.rangeEnclosingPosition(positionAfterCurrentWord, with: .word, inDirection: UITextDirection.storage(.forward)) {
                    // Move the cursor to the next word
                    userInputTextField.selectedTextRange = nextWordRange

                    // Allow some time for the text range to update before announcing
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
                } else {
                    print("No next word found.")
                    UIAccessibility.post(notification: .announcement, argument: "No next word found.")
                }
            }
        }

        private func previousWord() {
            print("Inside Previous Word")

            guard let textRange = userInputTextField.selectedTextRange else { return }

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
                } else {
                    print("No previous word found.")
                    UIAccessibility.post(notification: .announcement, argument: "No previous word found.")
                }
            }
        }

    private func nextCharacter() {
           print("Inside Next Character (with delay)")

           guard let textRange = userInputTextField.selectedTextRange else { return }

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
               } else {
                   print("No next character found.")
                   UIAccessibility.post(notification: .announcement, argument: "No next character found.")
               }
           }
       }

       // By - Monalika Padma Reddy (Aug 08, 2024)
       //  previousCharacter() - Identifies the current Character, then moves the cursor to the previous Character, and announces the Character through VoiceOver, cursor is there on the Character that it announces.

       private func previousCharacter() {
           print("Inside Previous Character (with delay)")

           guard let textRange = userInputTextField.selectedTextRange else { return }

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
               } else {
                   print("No previous character found.")
                   UIAccessibility.post(notification: .announcement, argument: "No previous character found.")
               }
           }
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
        
        if (abs(acceleration.x) > threshold && abs(acceleration.x) <= threshold1) ||
                    (abs(acceleration.y) > threshold && abs(acceleration.y) <= threshold1) ||
                    (abs(acceleration.z) > threshold && abs(acceleration.z) <= threshold1) {
                    print("Detected next tap, moving to next element")
                    direction = .next
            
        } else if (abs(acceleration.x) > threshold1 && abs(acceleration.x) <= threshold2) ||
                        (abs(acceleration.y) > threshold1 && abs(acceleration.y) <= threshold2) ||
                        (abs(acceleration.z) > threshold1 && abs(acceleration.z) <= threshold2) {
                print("Detected previous tap, moving to previous element")
                direction = .previous
        }
        triggerRotorUpdate(using: direction)
    }
    
    private func triggerRotorUpdate(using direction: UIAccessibilityCustomRotor.Direction) {
        //guard let focusedElement = UIAccessibility.focusedElement() as? UIView else { return }
        print("Inside triggerRotorUpdate--------------------------------------")
//        if let focusedElement = UIAccessibility.focusedElement(using: UIAccessibility.AssistiveTechnologyIdentifier.notificationVoiceOver) as? UIView {

//        if let currentElement = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? UIView {
//                // Print the element's accessibilityIdentifier if available
//                if let identifier = currentElement.accessibilityIdentifier {
//                    print("Currently focused element: \(identifier)")
//                } else {
//                    print("Currently focused element: \(currentElement) (No accessibilityIdentifier set)")
//                }
//            } else {
//                print("No currently focused element found for VoiceOver.")
//            }
//            
//            // Proceed with rotor logic only if currentElement is available
//            guard let currentElement = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? UIView else {
//                return
//            }
            let predicate = UIAccessibilityCustomRotorSearchPredicate()
            predicate.searchDirection = direction
            // Manually trigger the rotor search logic
            _ = handleRotorSearch(predicate: predicate)
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







