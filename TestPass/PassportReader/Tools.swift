//
//  Tools.swift
//  TestPass
//
//  Created by Jan Moritz on 10.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation
import CoreNFC

class Tools {
    static func hexDump(data: NSData) -> String {
        return UnsafeBufferPointer<UInt8>(start: data.bytes.assumingMemoryBound(to: UInt8.self), count: data.count)
            .reduce("") { $0 + String(format: "%02x", $1) }
    }
    
    static func dataWithHexString(hex: String) -> Data {
        var hex = hex
        var data = Data()
        while(hex.count > 0) {
            let subIndex = hex.index(hex.startIndex, offsetBy: 2)
            let c = String(hex[..<subIndex])
            hex = String(hex[subIndex...])
            var ch: UInt32 = 0
            Scanner(string: c).scanHexInt32(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        return data
    }
    
    static func fillData(size: Int) -> Data {
        var data = Data()
        for _ in 1...size {
            data.append(0x00)
        }
        return data
    }
    
    static func split(data: Data, from:Int, size: Int) -> Data {
        return data.subdata(in: Range(from...(from+size-1)))
    }
    
    static func constructAPDU(instructionClass: UInt8, instructionCode: UInt8, p1Parameter: UInt8, p2Parameter: UInt8, data: Data, expectedResponseLength: UInt8) -> NFCISO7816APDU {
        var commandWithHeader = Data()
         commandWithHeader.append(instructionClass)
         commandWithHeader.append(instructionCode)
         commandWithHeader.append(p1Parameter)
         commandWithHeader.append(p2Parameter)
         commandWithHeader.append(UInt8(data.count))
         commandWithHeader.append(data)
         commandWithHeader.append(expectedResponseLength)
         return NFCISO7816APDU(data: commandWithHeader)!
    }
    
    static func substr(string: String, from: Int, size: Int) -> String {
        let start = String.Index(utf16Offset: from, in: string)
        let end = String.Index(utf16Offset: from + size, in: string)
        
        return String(string[start..<end])
    }
}
