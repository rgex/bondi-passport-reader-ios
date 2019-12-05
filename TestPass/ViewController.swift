//
//  ViewController.swift
//  TestPass
//
//  Created by Jan Moritz on 09.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import UIKit
import CoreNFC

class ViewController: UIViewController, NFCTagReaderSessionDelegate {
    
    @IBOutlet weak var passportNbrTextField: UITextField!
    @IBOutlet weak var dateOfBirthTextField: UITextField!
    @IBOutlet weak var dateOfExpiryTextField: UITextField!
    @IBOutlet weak var startScanButton: UIButton!
    
    var nfcTagReaderSession: NFCTagReaderSession?
    var dg1: Data?
    var dg2: Data?
    var sod: Data?
    var isTest: Bool
    var dateOfBirthDatePicker = UIDatePicker()
    var dateOfExpiryDatePicker = UIDatePicker()
    let userDefaults = UserDefaults.standard
    
    let dateFormatterText = DateFormatter()
    let dateFormatterValue = DateFormatter()
    
    required init?(coder: NSCoder) {
        self.isTest = false
        super.init(coder: coder)
    }
    
    @objc func cancelDOBPicker() {
        self.view.endEditing(true)
        dateOfBirthDatePicker.resignFirstResponder()
    }
    
    @objc func doneDOBPicker() {
        dateOfBirthTextField.text = dateFormatterText.string(from: dateOfBirthDatePicker.date)
        userDefaults.set(dateOfBirthTextField.text, forKey: "dobText")
        userDefaults.set(dateFormatterValue.string(from: dateOfBirthDatePicker.date), forKey: "dobValue")
        print("dobValue:" + dateFormatterValue.string(from: dateOfBirthDatePicker.date))
        
        self.view.endEditing(true)
        dateOfBirthDatePicker.resignFirstResponder()
    }
    
    @objc func cancelDOEPicker() {
        self.view.endEditing(true)
        dateOfExpiryDatePicker.resignFirstResponder()
    }
    
    @objc func doneDOEPicker() {
        dateOfExpiryTextField.text = dateFormatterText.string(from: dateOfExpiryDatePicker.date)
        userDefaults.set(dateOfExpiryTextField.text, forKey: "doeText")
        userDefaults.set(dateFormatterValue.string(from: dateOfExpiryDatePicker.date), forKey: "doeValue")
        
        self.view.endEditing(true)
        dateOfExpiryDatePicker.resignFirstResponder()
    }
    
    func prepareDOBpicker() {
        //dateOfBirthDatePicker = UIDatePicker(frame:CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216))
        //dateOfBirthDatePicker.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216)
        
        // Do any additional setup after loading the view.
        dateOfBirthDatePicker.datePickerMode = UIDatePicker.Mode.date
        dateOfBirthTextField.inputView = dateOfBirthDatePicker
        dateOfBirthTextField.placeholder = "01/09/1985"
        
        // UIPickerView
        if self.traitCollection.userInterfaceStyle == .dark {
            dateOfBirthDatePicker.backgroundColor = UIColor.black
        } else {
            dateOfBirthDatePicker.backgroundColor = UIColor.white
        }
        dateOfBirthTextField.inputView = dateOfBirthDatePicker
        
        // ToolBar
        let dobToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 35))
        dobToolBar.barStyle = .default
        dobToolBar.isTranslucent = false
        //dobToolBar.sizeToFit()
    
        
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment:""), style: .done, target: self, action: #selector(ViewController.doneDOBPicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment:""), style: .plain, target: self, action: #selector(ViewController.cancelDOBPicker))
        dobToolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        dobToolBar.isUserInteractionEnabled = true
        dateOfBirthTextField.inputAccessoryView = dobToolBar
    }
    
    func prepareDOEpicker() {
        dateOfExpiryDatePicker = UIDatePicker(frame:CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216))
        
        // Do any additional setup after loading the view.
        dateOfExpiryDatePicker.datePickerMode = UIDatePicker.Mode.date
        dateOfExpiryTextField.inputView = dateOfExpiryDatePicker
        dateOfExpiryTextField.placeholder = "01/09/2023"
        
        // UIPickerView
        if self.traitCollection.userInterfaceStyle == .dark {
            dateOfExpiryDatePicker.backgroundColor = UIColor.black
        } else {
            dateOfExpiryDatePicker.backgroundColor = UIColor.white
        }
        
        dateOfExpiryTextField.inputView = dateOfExpiryDatePicker
        
        // ToolBar
        let doeToolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 35))
        doeToolBar.barStyle = .default
        doeToolBar.isTranslucent = false
        //doeToolBar.tintColor = UIColor(red: 92/255, green: 216/255, blue: 255/255, alpha: 1)
        //doeToolBar.sizeToFit()
        
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem(title: NSLocalizedString("Done", comment:""), style: .done, target: self, action: #selector(ViewController.doneDOEPicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment:""), style: .plain, target: self, action: #selector(ViewController.cancelDOEPicker))
        doeToolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        doeToolBar.isUserInteractionEnabled = true
        dateOfExpiryTextField.inputAccessoryView = doeToolBar
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        self.startScanButton.isHidden = true
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        self.startScanButton.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var localeCode = "DE"
        if let currentLocaleCode = Locale.current.regionCode {
            localeCode = currentLocaleCode
            
            print("localeCode:" + localeCode)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        
        self.passportNbrTextField.autocapitalizationType = .allCharacters
        
        dateFormatterText.dateFormat = "yyyy-MM-dd"
        dateFormatterValue.dateFormat = "YYMMdd"
        
        passportNbrTextField.placeholder = "ADO123456"
        
        prepareDOBpicker()
        prepareDOEpicker()
        
        if let dobText = userDefaults.string(forKey: "dobText") {
            dateOfBirthTextField.text = dobText
            
            if let recoveredDate = dateFormatterText.date(from: dobText) {
                dateOfBirthDatePicker.setDate(recoveredDate, animated: false)
            }
        }
        
        if let doeText = userDefaults.string(forKey: "doeText") {
            dateOfExpiryTextField.text = doeText
            
            if let recoveredDate = dateFormatterText.date(from: doeText) {
                dateOfExpiryDatePicker.setDate(recoveredDate, animated: false)
            }
        }
        
        if let passportNbr = userDefaults.string(forKey: "passportNbr") {
            passportNbrTextField.text = passportNbr
        }
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueResultViewController" {
            if let resultViewController = segue.destination as? ResultViewController {
                resultViewController.dg1 = dg1
                resultViewController.dg2 = dg2
                resultViewController.sod = sod
                resultViewController.isTest = self.isTest
            }
        }
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("Tag reader did become active")
        print("isReady: \(nfcTagReaderSession?.isReady)")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("\(error)")
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        
        print("got a Tag!")
        print("\(tags)")
        
        let tag = tags.first!
        
        nfcTagReaderSession?.connect(to: tag) { (error: Error?) in
                if case let .iso7816(iso7816Tag) = tag {
                    let reader = Reader(tag: iso7816Tag, completionHandler: self.nfcReadingCompleted, progressHandler: self.progressHandler)
                    
                    if let doeValue = self.userDefaults.string(forKey: "doeValue") {
                        if let dobValue = self.userDefaults.string(forKey: "dobValue") {
                            if var passportNbr = self.userDefaults.string(forKey: "passportNbr") {
                                if passportNbr.count == 8 {
                                    passportNbr.append("<")
                                }
                                reader.setBacKeys(BacKeys(documentNumber: passportNbr, dateOfBirth: dobValue, dateOfExpiry:doeValue))
                            }
                        }
                    }
                    
                    reader.read()
                 }
         }
    }
    
    func progressHandler(progress: UInt) {
        nfcTagReaderSession?.alertMessage =  NSLocalizedString("Reading", comment:"") + " (" + String(progress) + " %)"
    }
    
    func nfcReadingCompleted(success: Bool, dg1: Data, dg2: Data, sod: Data) {
        
        if success {
            self.dg1 = dg1
            self.dg2 = dg2
            self.sod = sod
            
            nfcTagReaderSession?.invalidate()
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "segueResultViewController", sender: self)
            }
        } else {

            nfcTagReaderSession?.invalidate(errorMessage: NSLocalizedString("Reading failed, check the passport number, date of birth and date of expiry", comment:""))
            
        }
    }

    @IBAction func clickedNFC(_ sender: Any) {
        
        if let passportNbr = self.userDefaults.string(forKey: "passportNbr") {
            
            if passportNbr == "T01000322" { // Then it is for test purposes
                self.isTest = true
                self.performSegue(withIdentifier: "segueResultViewController", sender: self)
                return
            } else {
                self.isTest = false
            }
            
            if passportNbr.count < 8 {
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Passport number is too short", comment:""), preferredStyle: UIAlertController.Style.alert)
                self.present(alert, animated: true, completion: nil)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                return
            }
            if passportNbr.count > 9 {
                let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Passport number is too long", comment: ""), preferredStyle: UIAlertController.Style.alert)
                self.present(alert, animated: true, completion: nil)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                return
            }
        } else {
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message:  NSLocalizedString("Please provide a passport number", comment: ""), preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if self.userDefaults.string(forKey: "doeValue") == nil {
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Please provide a date of expiry", comment:""), preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        } else if self.userDefaults.string(forKey: "dobValue") == nil {
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Please provide a date of birth", comment:""), preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

            self.present(alert, animated: true, completion: nil)
            return
        } else {
            
            print("nfcTagReaderSession")
            nfcTagReaderSession = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)

            nfcTagReaderSession?.alertMessage = NSLocalizedString("Place the device on the innercover of the passport", comment: "")
            nfcTagReaderSession?.begin()
            print("isReady: \(nfcTagReaderSession?.isReady)")
        }
    }
    
    
    @IBAction func passportNbrTextChanged(_ sender: Any) {
        userDefaults.set(passportNbrTextField.text, forKey: "passportNbr")
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
}

