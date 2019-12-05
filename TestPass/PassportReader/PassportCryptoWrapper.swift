//
//  PassportCrypto.swift
//  TestPass
//
//  Created by Jan Moritz on 10.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation
import OpenSSL

class PassportCryptoWrapper {
    static func sha1(payload :Data) -> Data {
        
        var c = SHA_CTX()
        
        let data = payload as NSData
        
        let firstByte: UnsafePointer? = data.bytes.assumingMemoryBound(to: UInt8.self)
        var computedHash = Array<UInt8>(repeating: 0, count: 20)
        
        SHA1_Init(&c)
        SHA1_Update(&c, firstByte, payload.count)
        SHA1_Final(&computedHash, &c)
        
        return NSData(bytes: computedHash, length: 20) as Data
    }
    
    static func generateRandom(length: Int) -> Data {
        var rnd = Data(count: length)
        _ = rnd.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        
        return rnd
    }
    
    static func encryptWith3DES(message: Data, key1: Data, key2: Data) -> Data {
        
        guard let encryptedMessage = OCPCWrapper.encryptWith3DESX(message, key1: key1, key2: key2) else { return Data() }
        
        return encryptedMessage
    }
    
    static func decryptWith3DES(encryptedMessage: Data, key1:Data, key2:Data) -> Data {
        return OCPCWrapper.decryptWith3DES(encryptedMessage, key1: key1, ke2: key2)
    }
    
    static func calculateXor(c1: Data, c2:(Data)) -> Data {
        var result = Tools.fillData(size: c1.count)
        result.reserveCapacity(c1.count)
        return OCPCWrapper.calculateXor(result, c1: c1, c2: c2)
    }
    
    static func calculate3DESMAC(message: Data, key1:Data, key2: Data) -> Data {
        var mac = Tools.fillData(size: 8)
        mac.reserveCapacity(8)
        return OCPCWrapper.calculate3DESMAC(mac, message: message, key1: key1, key2: key2)
    }
    
    static func incrementSequenceCounter(sequenceCounter: Data) -> Data {
        return OCPCWrapper.incrementSequenceCounter(sequenceCounter)
    }
    
    static func calculateAsn1Length(intVal: UInt32) -> Int{
        var asn1Length = 1
        if(intVal <= 127) {
            asn1Length = 1
        } else if(intVal <= 255) {
            asn1Length = 2
        } else if(intVal <= 65535) {
            asn1Length = 3
        }
        
        return asn1Length
    }
    
    static func intToAsn1(intVal: UInt32) -> Data {
        var asn1 = Tools.fillData(size: 4)
        asn1.reserveCapacity(4)
        asn1 = OCPCWrapper.int(toAsn1: intVal, asn1:asn1)
        
        
        return Tools.split(data: asn1, from:0, size: calculateAsn1Length(intVal: intVal))
    }
    
    static func buildDO87(command: Data) -> Data {
        let DOLength = PassportCryptoWrapper.intToAsn1(intVal: (UInt32(command.count + 1)))
        
        var do87 = Data()
        do87.append(0x87)
        do87.append(DOLength)
        do87.append(0x01)
        do87.append(command)
        
        return do87
    }
    
    static func buildDO8E(mac: Data) -> Data {
        var do8e = Data()
        
        do8e.append(0x8E)
        do8e.append(0x08)
        do8e.append(mac)
        
        return do8e
    }
    
    static func buildDO97(length: UInt8) -> Data {
        var do97 = Data()
        
        do97.append(0x97)
        do97.append(0x01)
        do97.append(length)
        
        return do97
    }
    
    static func paddMessage(message: Data) -> Data {
        var paddedMessageLength = message.count + 1;
    
        if paddedMessageLength % 8 != 0 {
            paddedMessageLength += 8 - (paddedMessageLength % 8);
        }
    
        var paddedMessage = Data()
        paddedMessage.append(message)
        paddedMessage.append(0x80)
    
        for _ in 1...(paddedMessageLength - (message.count + 1)) {
            paddedMessage.append(0x00)
        }
        
        return paddedMessage
    }
    
    static func unpad(message: Data) -> Data
    {
        var unPaddedLength = message.count
        while(Tools.hexDump(data: Tools.split(data: message, from:(unPaddedLength - 2), size:1) as NSData) != "80") {
            unPaddedLength -= 1
            if unPaddedLength == 2 {
                return Data()
            }
        }
        
        return Tools.split(data: message, from: 0, size: (unPaddedLength - 2))
    }
    
    static func intTo16bitsChar(intVal: UInt32) -> Data {
        let intChar = Tools.fillData(size: 2)
        return OCPCWrapper.intTo16bitsChar(intVal, intChar: intChar)
    }
    
    static func asn1ToInt(asn1: Data) -> UInt {
        return UInt(OCPCWrapper.asn1(toInt: asn1))
    }
    
    static func getMdAlg(sod: Data) -> Data {
        return OCPCWrapper.getMdAlg(sod)
    }
    
    static func getSigAlg(sod: Data) -> Data {
        return OCPCWrapper.getSigAlg(sod)
    }
    
    static func getIssuer(sod: Data) -> Data {
           return OCPCWrapper.getIssuer(sod)
       }
    
}
