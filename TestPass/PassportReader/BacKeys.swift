//
//  BacKeys.swift
//  TestPass
//
//  Created by Jan Moritz on 09.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation
import OpenSSL

class BacKeys {
    var documentNumber :String
    var dateOfBirth :String
    var dateOfExpiry :String
    var seed: Data
    
    init(documentNumber: String, dateOfBirth: String, dateOfExpiry: String) {
        self.documentNumber = documentNumber
        self.dateOfBirth = dateOfBirth
        self.dateOfExpiry = dateOfExpiry
        self.seed = Data()
    }
    
    func calculateKey(cType: Int) -> (Data, Data) {
        var d = Data()
        var ka = Data()
        var kb = Data()
        
        d.append(self.seed)
        d.append(0x00)
        d.append(0x00)
        d.append(0x00)
        
        if cType == 1 {
            d.append(0x01)
        } else {
            d.append(0x02)
        }
        
        print("D: " + Tools.hexDump(data: d as NSData))
        
        let md = PassportCryptoWrapper.sha1(payload: d);
        print("sha1(D): " + Tools.hexDump(data: md as NSData))

        let mdPointer = UnsafeMutableRawPointer(mutating: [UInt8](md))
        ka.append(Data(bytesNoCopy: mdPointer, count: 8, deallocator: Data.Deallocator.none))
        kb.append(Data(bytesNoCopy: mdPointer + 8, count: 8, deallocator: Data.Deallocator.none))
        
        return (ka, kb)
    }
    
    func calculateKSeed() -> Data {
        var mrzInfo: String
        let documentNumberCS = calculateChecksumDigit(digits: documentNumber, length: documentNumber.count)
        let dateOfBirthCS = calculateChecksumDigit(digits: dateOfBirth, length: 6)
        let dateOfExpiryCS = calculateChecksumDigit(digits: dateOfExpiry, length: 6)
        
        print("documentNumber:" + documentNumber)
        print("documentNumberCS:" + String(documentNumberCS))
        
        print("dateOfBirth:" + dateOfBirth)
        print("dateOfBirthCS:" + String(dateOfBirthCS))
        
        print("dateOfExpiry:" + dateOfExpiry)
        print("dateOfExpiryCS:" + String(dateOfExpiryCS))
        
        mrzInfo = documentNumber + String(documentNumberCS) + dateOfBirth + String(dateOfBirthCS) + dateOfExpiry + String(dateOfExpiryCS)
        
        print("mrzInfo: " + mrzInfo)
        
        guard let mrzData = mrzInfo.data(using: .ascii) else { return Data() }
        let md = PassportCryptoWrapper.sha1(payload:mrzData)
        
        let mdPointer = UnsafeMutableRawPointer(mutating: [UInt8](md))
        let cSeed = Data(bytesNoCopy: mdPointer, count: 16, deallocator: Data.Deallocator.none)
        
        return cSeed
    }
    
    func calculateChecksumDigit(digits: String, length : Int) -> Int {
        var sum = 0
        var weight = 0
        for i in 0..<length {
            var value = 0
            let digitIndex = digits.index(digits.startIndex, offsetBy: i)
            let currentDigit = digits[digitIndex]
            if let currentDigitCode = currentDigit.asciiValue as UInt8? {
                
                if(currentDigitCode > UInt8(64) && currentDigitCode < UInt8(91)) {
                    value = Int(currentDigitCode - UInt8(65) + UInt8(10))
                }
                
                if(currentDigitCode > UInt8(47) && currentDigitCode < UInt8(58)) {
                    value = Int(currentDigitCode - UInt8(48))
                }
                
                switch (i % 3) {
                    case 0:
                        weight = 7
                    break;
                    case 1:
                        weight = 3
                    break;
                    case 2:
                        weight = 1
                    break;
                    default:
                        weight = 0
                }
                
                sum += weight * value
            }
        }
        
        return (sum % 10);
    }
    
    func getKEnc() -> (Data, Data) {
        return calculateKey(cType: 1);
    }
    
    func getKMac() -> (Data, Data) {
        return calculateKey(cType: 2);
    }
    
    func setSeed(newSeed: Data) {
        self.seed = Data(newSeed)
        print("Set new seed : \(seed) -> " + Tools.hexDump(data: seed as NSData))
    }
    
}
