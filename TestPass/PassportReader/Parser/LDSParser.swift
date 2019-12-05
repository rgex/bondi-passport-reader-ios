//
//  LDSParser.swift
//  TestPass
//
//  Created by Jan Moritz on 21.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation

class LDSParser {
    
    var cursor: UInt
    var lds: Data
    
    init(lds: Data)
    {
        self.lds = lds
        self.cursor = 0
    }

    func getSequence() -> [LDSParser] {
        if Tools.split(data: self.lds, from: Int(self.cursor), size: 1) != Tools.dataWithHexString(hex: "30")
            && Tools.split(data: self.lds, from: Int(self.cursor), size: 1) != Tools.dataWithHexString(hex: "31") {
            // isn't a sequence
            return []
        }
        self.cursor += 1 //skip tag
        
        var currentTagContentLength = PassportCryptoWrapper.asn1ToInt(asn1: Tools.split(data: self.lds, from: Int(self.cursor), size: 3))
        
        if Tools.split(data: self.lds, from: Int(self.cursor), size: 3) == Tools.dataWithHexString(hex: "82") {
            cursor += 2
        } else if Tools.split(data: self.lds, from: Int(self.cursor), size: 3) == Tools.dataWithHexString(hex: "81") {
            cursor += 1
        }
        cursor += 1
        
        
        let sequenceEnd = cursor + currentTagContentLength
        
        var sequence = [LDSParser]()
        
        while cursor < sequenceEnd {
            let cursorSeqStart = cursor
            cursor += 1 //skip tag
            
            let currentTagContentAsn1Length = Tools.split(data: self.lds, from: Int(cursor), size: 3)
            
            currentTagContentLength = PassportCryptoWrapper.asn1ToInt(
                asn1: currentTagContentAsn1Length
            )
            
            cursor += 1
            if Tools.split(data: currentTagContentAsn1Length, from: 0, size: 1)
                == Tools.dataWithHexString(hex: "82") {
                cursor += 2
            } else if Tools.split(data: currentTagContentAsn1Length, from: 0, size: 1) == Tools.dataWithHexString(hex: "81") {
                cursor += 1
            }
            
            sequence.append(
                LDSParser(lds: Tools.split(data: lds, from: Int(cursorSeqStart), size: Int(currentTagContentLength)))
            )
            
            cursor += currentTagContentLength
        }
        
        return sequence;
    }
    
    func getTag(_ tag: String) -> LDSParser {
        var cursor = 0
        var currentTag = Data()
        let tagData = Tools.dataWithHexString(hex: tag)
    
        while cursor < self.lds.count {
    
            if(Tools.split(data: self.lds, from: cursor, size: 1) == Tools.dataWithHexString(hex: "7F") || Tools.split(data: self.lds, from: cursor, size: 1) == Tools.dataWithHexString(hex: "5F")) {
                currentTag = Tools.split(data: self.lds, from: cursor, size: 2)
                cursor += 2
            } else {
                currentTag = Tools.split(data: self.lds, from: cursor, size: 1)
                cursor += 1
            }
            print("currentTag:" + Tools.hexDump(data: currentTag as NSData))
    
            let currentTagContentAsn1Length = Tools.split(data: self.lds, from: cursor, size: 3)
    
            let currentTagContentLength = PassportCryptoWrapper.asn1ToInt(asn1: currentTagContentAsn1Length)
            print("currentTagContentAsn1Length: " + Tools.hexDump(data: currentTagContentAsn1Length as NSData))
            cursor += 1
            if Tools.split(data: currentTagContentAsn1Length, from: 0, size: 1) == Tools.dataWithHexString(hex: "82") {
                print("82")
                cursor += 2
            } else if Tools.split(data: currentTagContentAsn1Length, from: 0, size: 1) == Tools.dataWithHexString(hex: "81"){
                cursor += 1
                print("81")
            }
    
            if (Tools.split(data: currentTag, from: 0, size: 1) != Tools.dataWithHexString(hex: "7F")
                && Tools.split(data: currentTag, from: 0, size: 1) != Tools.dataWithHexString(hex: "5F")
                && Tools.split(data: currentTag, from: 0, size: 1) == Tools.split(data: tagData, from: 0, size: 1)
                )
            || (tagData == currentTag) {
                    
                let currentTagContent = Tools.split(data: self.lds, from: cursor, size: Int(currentTagContentLength))
    
                print("currentTagContent:" + Tools.hexDump(data: currentTagContent as NSData))
                return LDSParser(lds: currentTagContent)
            }
    
            cursor += Int(currentTagContentLength)
        }
    
        return LDSParser(lds: Data())
    }
    
    func getContent() -> Data {
        return lds
    }
}
