//
//  APDUTranscripter.swift
//  TestPass
//
//  Created by Jan Moritz on 09.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation
import CoreNFC

class APDUTranscripter {
    let tag :NFCISO7816Tag
    var status :String
    var message :String
    var data :Data
    var completed: Bool
    
    init(tag :NFCISO7816Tag) {
        self.tag = tag
        self.status = ""
        self.message = ""
        self.data = Data()
        self.completed = false
    }
    
    func sendCommand(instructionClass: UInt8, instructionCode: UInt8, p1Parameter: UInt8, p2Parameter: UInt8, data: Data, expectedResponseLength: Int) -> (String, String, Data) {
        
        self.completed = false
        let myAPDU = NFCISO7816APDU(instructionClass: instructionClass, instructionCode: instructionCode, p1Parameter: p1Parameter, p2Parameter: p2Parameter, data: data, expectedResponseLength: expectedResponseLength)
        
        tag.sendCommand(apdu: myAPDU) {
            (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
            guard error != nil && !(sw1 == 0x90 && sw2 == 0x00) else {
                self.status = "error"
                self.message = "Application failure"
                self.data = response
                return
            }
            self.status = "success"
            self.message = "Application success"
            self.data = response
            return
        }
        return (status, message, data)
    }
    
    private func completitionHandler(data :Data, sw1 :UInt8, sw2 :UInt8, error :Error?) {
        
        self.completed = true
    }
}
