//
//  ViewController.swift
//  text edit
//
//  Created by Prerna Khanna on 5/22/24.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var recordSwitch: UISwitch!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var userInputTextField: UITextField!
    @IBOutlet weak var optionSlider: UISlider!
    @IBOutlet weak var sliderValueLabel: UILabel!

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
