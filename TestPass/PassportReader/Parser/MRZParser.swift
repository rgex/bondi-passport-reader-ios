//
//  MRZParser.swift
//  TestPass
//
//  Created by Jan Moritz on 21.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation

class MRZResponseObject {

    var success: Bool
    var name: String
    var dateOfBirth: String
    var dateOfExpiry: String
    var passportNumber: String
    var gender: String
    var iso2CountryCode: String
    
    init() {
        self.success = false
        self.name = ""
        self.dateOfBirth = ""
        self.dateOfExpiry = ""
        self.passportNumber = ""
        self.gender = ""
        self.iso2CountryCode = ""
    }

    func isSuccess() -> Bool {
        return success
    }
    
    func setSuccess(_ success: Bool) {
        self.success = success
    }
    
    func getName() -> String {
        return name
    }
    
    func setName(_ name: String) {
        self.name = name
    }
    
    func getDateOfBirth() -> String {
        return dateOfBirth
    }
    
    func setDateOfBirth(_ dateOfBirth: String) {
        self.dateOfBirth = dateOfBirth
    }
    
    func getDateOfExpiry() -> String {
        return dateOfExpiry
    }
    
    func setDateOfExpiry(_ dateOfExpiry: String) {
        self.dateOfExpiry = dateOfExpiry
    }
    
    func getPassportNumber() -> String {
        return passportNumber
    }
    
    func setPassportNumber(_ passportNumber: String) {
        self.passportNumber = passportNumber
    }
    
    func getGender() -> String {
        return gender
    }
    
    func setGender(_ gender: String) {
        self.gender = gender
    }
    
    func getIso2CountryCode() -> String {
        return iso2CountryCode
    }
    
    func setIso2CountryCode(_ iso2CountryCode: String) {
        self.iso2CountryCode = iso2CountryCode
    }
}

class MRZParser {
    
    static func rtrim(_ s: String) -> String {
        return s.trimmingCharacters(in: .whitespaces)
    }
    
    static func formatClean(_ s: String) -> String {
        return rtrim(s.replacingOccurrences(of: "<", with: " ", options: .literal, range: nil))
    }
    
    static func parseTD1(mrz: String) -> MRZResponseObject {
        let kycResponseObject = MRZResponseObject()
    
        var cursor = 2 //skip Document code
        kycResponseObject.setIso2CountryCode(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 3))
        )
        cursor += 3 //skip Issuing State or organization
    
        kycResponseObject.setPassportNumber(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 9))
        )
        
        cursor += 1 //skip check digit
        cursor += 15 //skip optional parameters
    
        kycResponseObject.setDateOfBirth(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 6))
        )
        cursor += 6 //skip date of birth
        cursor += 1 //skip check digit
    
        kycResponseObject.setGender(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 1))
        )
        cursor += 1 //skip gender
    
        kycResponseObject.setDateOfExpiry(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 6))
        );
        cursor += 6 //skip date of expiry
        cursor += 1 //skip check digit
    
        cursor += 3; //skip nationality
        cursor += 11; //skip Optional data elements
        cursor += 1 //skipcComposite check digit
    
        kycResponseObject.setName(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 30))
        )
        
        cursor += 30 //skip name
    
        kycResponseObject.setSuccess(true)
        return kycResponseObject
    }
    
    static func parseTD2(mrz: String) -> MRZResponseObject {
        let kycResponseObject = MRZResponseObject()
    
        var cursor = 2 //skip Document code
        kycResponseObject.setIso2CountryCode(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 3))
        );
        cursor += 3 //skip Issuing State or organization
    
        kycResponseObject.setName(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 31))
        );
        cursor += 31 //skip name
    
        kycResponseObject.setPassportNumber(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 9))
        )
        cursor += 9 //skip passport number
        cursor += 1 //skip check digit
        cursor += 3 //skip nationality
    
        kycResponseObject.setDateOfBirth(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 6))
        )
        cursor += 6 //skip date of birth
        cursor += 1 //skip check digit
    
        kycResponseObject.setGender(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 1))
        )
        cursor += 1 //skip gender
    
        kycResponseObject.setDateOfExpiry(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 6))
        )
        cursor += 6 //skip date of expiry
        cursor += 1 //skip check digit
    
        //ignore the rest
    
        kycResponseObject.setSuccess(true)
        return kycResponseObject
    }
    
    static func parseTD3(mrz: String) -> MRZResponseObject {
        let kycResponseObject = MRZResponseObject()
    
        var cursor = 2 //skip Document code
        kycResponseObject.setIso2CountryCode(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 3))
        )
        cursor += 3 //skip Issuing State or organization
    
        kycResponseObject.setName(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 39))
        )
        cursor += 39 //skip name
    
        kycResponseObject.setPassportNumber(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 9))
        )
        cursor += 9 //skip passport number
        cursor += 1 //skip check digit
        cursor += 3 //skip nationality
    
        kycResponseObject.setDateOfBirth(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 6))
        )
        cursor += 6; //skip date of birth
        cursor += 1 //skip check digit
    
        kycResponseObject.setGender(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 1))
        )
        cursor += 1 //skip gender
    
        kycResponseObject.setDateOfExpiry(
            formatClean(Tools.substr(string: mrz, from: cursor, size: 6))
        )
        cursor += 6; //skip date of expiry
        cursor += 1 //skip check digit
    
        //ignore the rest
    
        kycResponseObject.setSuccess(true);
        return kycResponseObject;
    }
    
    static func parse(mrz: String) -> MRZResponseObject {
        if mrz.count == 72 {
            return self.parseTD3(mrz: mrz)
        } else if mrz.count == 90 {
            return self.parseTD1(mrz: mrz)
        } else if mrz.count == 88 {
            return self.parseTD3(mrz: mrz)
        }
    
        let kycResponseObject = MRZResponseObject()
        kycResponseObject.setSuccess(false)
    
        return kycResponseObject
    }

}
