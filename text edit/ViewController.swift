// Custom Rotor movement based on air gestures done!
// Custom Rotor selection based granularity - In Progress

import UIKit
import CoreMotion

class ViewController: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    private let motionManager = CMMotionManager()
    
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var recordSwitch: UISwitch!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var userInputTextField: UITextField!
    @IBOutlet weak var optionSlider: UISlider!
    @IBOutlet weak var sliderValueLabel: UILabel!
    @IBOutlet weak var currentRotorLabel: UILabel!
    @IBOutlet weak var customView: UIView!
    @IBOutlet weak var accessibilitySwitch: UISwitch!

    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    
    var isRecording = false
    var touchCoordinates = [String]()
    var selectedOption = 1 // Default to option 1
    var accessibilitySelectedOption = 0 // Default to option 1
    var activeRotorName: String? // Store the name of the currently active rotor
    var customRotors: [UIAccessibilityCustomRotor] = []
    var activeRotor: UIAccessibilityCustomRotor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setupUI()
        
        // Create swipe gesture recognizers
        
        self.view.isUserInteractionEnabled = true

        print("Before SwipeUp")
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeUp.numberOfTouchesRequired = 1
        swipeUp.direction = .up
        
        print("Before SwipeDown")
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeDown.numberOfTouchesRequired = 1
        swipeDown.direction = .down
        
        // Add gesture recognizers to the view
        self.view.addGestureRecognizer(swipeUp)
        self.view.addGestureRecognizer(swipeDown)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleVoiceOverFocusChanged(notification:)),
                                               name: UIAccessibility.elementFocusedNotification,
                                               object: nil)
        setupHideKeyboardOnTap()
        
        // Define custom rotors
        let customWord = UIAccessibilityCustomRotor(name: "Custom Word") { predicate in
            self.updateActiveRotor(name: "Custom Word")
            print("Rotor selected: \(self.activeRotorName!)")
            return self.handleRotorSearchWord(predicate: predicate)
        }
        
        let customChar = UIAccessibilityCustomRotor(name: "Custom Character") { predicate in
            self.updateActiveRotor(name: "Custom Character")
            print("Rotor selected: \(self.activeRotorName!)")
            return self.handleRotorSearchChar(predicate: predicate)
        }
        
        let customLine = UIAccessibilityCustomRotor(name: "Custom Line") { predicate in
            self.updateActiveRotor(name: "Custom Line")
            print("Rotor selected: \(self.activeRotorName!)")
            return self.handleRotorSearchLine(predicate: predicate)
        }
        
        // Assign the custom rotors to the view
        customRotors = [customWord, customChar, customLine]
        activeRotor = customRotors.first
        view.accessibilityCustomRotors = customRotors
        
        // Start monitoring device motion for tap detection
        startDeviceMotionUpdates()
        self.view.accessibilityTraits = UIAccessibilityTraits.allowsDirectInteraction
    }
    
    private func updateActiveRotor(name: String) {
        guard activeRotorName != name else { return } // Avoid redundant updates
        activeRotorName = name
        //currentRotorLabel.text = name
      //  print("Active rotor updated to: \(name)")
    }
    
    private func handleRotorSearchWord(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        print("---------------------Inside handleRotorSearchWord function -------------------------------")
        
        //Remove existing swipe gestures if needed
        //view.gestureRecognizers?.forEach(view.removeGestureRecognizer)
        
        view.isUserInteractionEnabled = true

        self.customView.isUserInteractionEnabled = true
        
        if predicate.searchDirection == .next {
            let next = UISwipeGestureRecognizer.init()
            next.direction = .up
            handleSwipe(next)
        } else {
            let next = UISwipeGestureRecognizer.init()
            next.direction = .down
            handleSwipe(next)
        }
     
//        
//        // Create swipe gesture recognizers
//        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
//        print("Before SwipeUp")
//        swipeUp.direction = .up
//        
//        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
//        print("before SwipeDown")
//        swipeDown.direction = .down
//        
//        // Add gesture recognizers to the view
//        self.customView.addGestureRecognizer(swipeUp)
//        self.customView.addGestureRecognizer(swipeDown)
//        
        self.updateActiveRotor(name: "Custom Word")
        
        
        return nil
    }
    
    private func handleRotorSearchChar(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        print("------------------Inside handleRotorSearchChar function -------------------------------")
        
        // Remove existing swipe gestures if needed
        //view.gestureRecognizers?.forEach(view.removeGestureRecognizer)
        
        view.isUserInteractionEnabled = true
        self.customView.isUserInteractionEnabled = true
        
        if predicate.searchDirection == .next {
            let next = UISwipeGestureRecognizer.init()
            next.direction = .up
            handleSwipe(next)
        } else {
            let next = UISwipeGestureRecognizer.init()
            next.direction = .down
            handleSwipe(next)
        }

       
        self.updateActiveRotor(name: "Custom Character")
        return nil // No more elements found in the direction
        //            }
    }
    
    
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        print("Inside SwipeGestureRecignizer")
        guard let activeRotorName = activeRotorName else { return }
        
        if let userInput = userInputTextField.text, !userInput.isEmpty  {
            
            currentRotorLabel.text = activeRotorName
            switch gesture.direction {
                case .up:
                    if activeRotorName == "Custom Line" {
                        readLineBackward()
                    } else if activeRotorName == "Custom Character" {
                        previousCharacter()
                    }  else if activeRotorName == "Custom Word" {
                        previousWord()
                    } else {
                        previousWord()
                    }
                case .down:
                    if activeRotorName == "Custom Line" {
                        readLineForward()
                    } else if activeRotorName == "Custom Character" {
                        nextCharacter()
                    } else if activeRotorName == "Custom Word" {
                        nextWord()
                    } else {
                        nextWord()
                    }
                default:
                    break
            }
        } else {
            UIAccessibility.post(notification: .announcement, argument: "No text found.")
        }
    }
    
    private func handleRotorSearchLine(predicate: UIAccessibilityCustomRotorSearchPredicate) -> UIAccessibilityCustomRotorItemResult? {
        print("------------------Inside handleRotorSearchLine function -------------------------------")
        // Remove existing swipe gestures if needed
       // view.gestureRecognizers?.forEach(view.removeGestureRecognizer)
        
        view.isUserInteractionEnabled = true
        
        if predicate.searchDirection == .next {
            let next = UISwipeGestureRecognizer.init()
            next.direction = .up
            handleSwipe(next)
        } else {
            let next = UISwipeGestureRecognizer.init()
            next.direction = .down
            handleSwipe(next)
        }
        // Create swipe gesture recognizers
//        print("Before SwipeUp")
//        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
//        swipeUp.direction = .up
//        
//        print("Before SwipeDown")
//        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
//        swipeDown.direction = .down
//        
//        // Add gesture recognizers to the view
//        view.addGestureRecognizer(swipeUp)
//        view.addGestureRecognizer(swipeDown)
        
        self.updateActiveRotor(name: "Custom Line")
        return nil // No more elements found in the direction
        //            }
        
        //            direction = predicate.searchDirection
        //
        //            var nextElement: UITextRange?
        //
        //            if direction == .next {
        //                print("Next")
        //                nextElement = nextLine()
        //            } else if direction == .previous {
        //                print("Previous")
        //                nextElement = previousLine()
        //            }
        //            if let nextElement = nextElement {
        //                return UIAccessibilityCustomRotorItemResult(targetElement: userInputTextField, targetRange: nextElement)
        //            } else {
       // return nil // No more elements found in the direction
        //            }
    }
    
    private func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available.")
            return
        }
        
        print("Starting device motion updates...")
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else {
                print("Failed to get device motion.")
                return
            }
            self.detectTap(motion: motion)
        }
    }
    
    private func detectTap(motion: CMDeviceMotion) {
        // Simple tap detection logic based on acceleration
        //print("Inside detect tap")
        let acceleration = motion.userAcceleration
        let threshold: Double = 0.2 // Set a suitable threshold
        let threshold1: Double = 0.3
        let threshold2: Double = 0.8
        
        //print("Acceleration detected: x=\(acceleration.x), y=\(acceleration.y), z=\(acceleration.z)")
        
        if let activeRotor = activeRotor {
           // print("Active Rotor: \(activeRotor.name)")
        }
        
        if (abs(acceleration.x) > threshold && abs(acceleration.x) <= threshold1) ||
            (abs(acceleration.y) > threshold && abs(acceleration.y) <= threshold1) ||
            (abs(acceleration.z) > threshold && abs(acceleration.z) <= threshold1) {
            
            print("Detected tap within thresholds, moving to previous rotor")
            moveToPreviousRotor()
        } else if (abs(acceleration.x) > threshold1 && abs(acceleration.x) <= threshold2) ||
                    (abs(acceleration.y) > threshold1 && abs(acceleration.y) <= threshold2) ||
                    (abs(acceleration.z) > threshold1 && abs(acceleration.z) <= threshold2) {
            print("Detected tap outside thresholds, moving to next rotor")
            moveToNextRotor()
        }
    }
    
    private func readLineForward() {
        
        userInputTextField.selectedTextRange = userInputTextField.textRange(from: userInputTextField.beginningOfDocument, to: userInputTextField.endOfDocument)
        
        guard let textRange = userInputTextField.selectedTextRange else { return }


        // Schedule VoiceOver announcement asynchronously
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Get the text in the new selected range and make VoiceOver read it
            if let selectedText = self.userInputTextField.text(in: textRange) {

                UIAccessibility.post(notification: .announcement, argument: selectedText)
            } else {
                print("No next word found.")
                UIAccessibility.post(notification: .announcement, argument: "No next word found.")
            }
        }
    }
    
    private func readLineBackward() {
        let newPosition = userInputTextField.endOfDocument
        userInputTextField.selectedTextRange = userInputTextField.textRange(from: newPosition, to: userInputTextField.beginningOfDocument)

        
        guard let textRange = userInputTextField.selectedTextRange else { return }


        // Schedule VoiceOver announcement asynchronously
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Get the text in the new selected range and make VoiceOver read it
            if let selectedText = self.userInputTextField.text(in: textRange) {

                if let userString = self.userInputTextField.text {
                    let reversedStringArray = userString.components(separatedBy: CharacterSet(charactersIn: " ")).reversed()
                    let finalString = reversedStringArray.joined(separator: " ")

                    UIAccessibility.post(notification: .announcement, argument: String(finalString))
                }
            } else {
                print("No next word found.")
                UIAccessibility.post(notification: .announcement, argument: "No next word found.")
            }
        }
    }
    
    private func nextWord(){
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
        if let currentWordRange = userInputTextField.tokenizer.rangeEnclosingPosition(textRange.end, with: .word, inDirection: UITextDirection.storage(.backward)) {
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
        } else {
            print("Unable to content")
            UIAccessibility.post(notification: .announcement, argument: "Unable to content")
        }
    }
    
    private func nextCharacter() {
        print("Inside Next Character")
        
        guard let textRange = userInputTextField.selectedTextRange else { return  }
        
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
    
    private func previousCharacter() {
        print("Inside Previous Character")
        
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
    
    
    func moveToNextRotor() {
        print("Inside moveToNextRotor")
        if let currentIndex = customRotors.firstIndex(of: activeRotor!) {
            let nextIndex = currentIndex + 1
            if nextIndex < customRotors.count {
                activeRotor = customRotors[nextIndex]
              //  print("Active Rotor: \(activeRotor!.name)")
                if let rotor = activeRotor {
                    currentRotorLabel.text = rotor.name
                }
                
                if (activeRotor!.name) == "Custom Word" {
                    handleWordsFunction()
                } else if (activeRotor!.name) == "Custom Character" {
                    handleCharactersFunction()
                } else if (activeRotor!.name) == "Custom Line" {
                    handleLineFunction()
                }
                print("After if")
                
                UIAccessibility.post(notification: .announcement, argument: "Active Rotor: \(activeRotor!.name)")
            } else {
                print("No more rotors in the forward direction.")
            }
        }
    }
    func handleWordsFunction() {
        print("Handling Custom Word Rotor")
        _ = handleRotorSearchWord(predicate: UIAccessibilityCustomRotorSearchPredicate())
    }
    
    func handleCharactersFunction() {
        print("Handling Custom Character Rotor")
        _ = handleRotorSearchChar(predicate: UIAccessibilityCustomRotorSearchPredicate())
    }
    
    func handleLineFunction() {
        // Your logic for handling lines
        print("Handling Custom Line Rotor")
        _ = handleRotorSearchLine(predicate: UIAccessibilityCustomRotorSearchPredicate())
        
    }
    func moveToPreviousRotor() {
        print("Inside moveToPreviousRotor")
        if let currentIndex = customRotors.firstIndex(of: activeRotor!) {
            let previousIndex = currentIndex - 1
            if previousIndex >= 0 {
                activeRotor = customRotors[previousIndex]
                //print("Active Rotor: \(activeRotor!.name)")
                if let rotor = activeRotor {
                    currentRotorLabel.text = rotor.name
                }

                if (activeRotor!.name) == "Custom Word" {
                    handleWordsFunction()
                } else if (activeRotor!.name) == "Custom Character" {
                    handleCharactersFunction()
                } else if (activeRotor!.name) == "Custom Line" {
                    handleLineFunction()
                }
                UIAccessibility.post(notification: .announcement, argument: "Active Rotor: \(activeRotor!.name)")
            } else {
                print("No more rotors in the backward direction.")
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
        //userInputTextField.becomeFirstResponder()
        setupSlider()
    }
    
    func setupSlider() {
        optionSlider.minimumValue = 1
        optionSlider.maximumValue = 5
        optionSlider.value = 1 // Start with the first option selected
        optionSlider.isContinuous = true // Update value continuously as the user slides
        updateSliderValueLabel() // Initial update for the label
    }
    
    @IBAction func accessbilityChang(_ sender: UISwitch) {
        
        if sender.isOn {
            self.view.isAccessibilityElement = true
        } else {
            self.view.isAccessibilityElement = false
        }
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
        motionManager.stopDeviceMotionUpdates() // Stop motion updates when the view controller is deallocated
    }
}
