//
//  Reader.swift
//  TestPass
//
//  Created by Jan Moritz on 10.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation
import CoreNFC

enum ReaderSteps {
    case getAID
    case getRND
    case initSession
    case readDG1
    case readDG2
    case readSOD
    case done
}

class Reader {
    
    var currentStep = ReaderSteps.getAID
    var tag: NFCISO7816Tag
    var rndic: Data
    var rndifd: Data
    var kifd: Data
    var bacKeys: BacKeys
    var sequenceCounter: Data
    var bacEncKey1: Data
    var bacEncKey2: Data
    var bacMacKey1: Data
    var bacMacKey2: Data
    var isFileSelected: Bool
    var cursor: UInt
    var fileSize: UInt
    var progress: UInt
    var progressDG1: UInt
    var progressDG2: UInt
    var progressSOD: UInt
    var dg1: Data
    var dg2: Data
    var sod: Data
    var completionHandler: (Bool, Data, Data, Data) -> Void
    var progressHandler: (UInt) -> Void
    
    init(
        tag: NFCISO7816Tag,
        completionHandler: @escaping (Bool, Data, Data, Data) -> Void,
        progressHandler: @escaping (UInt) -> Void
    ) {
        self.tag = tag
        self.rndic = Data()
        self.rndifd = Data()
        self.kifd = Data()
        self.bacKeys = BacKeys(documentNumber: "OOOOOOOOO", dateOfBirth: "000101", dateOfExpiry:"000101")
        self.bacKeys.setSeed(newSeed: self.bacKeys.calculateKSeed())
        self.sequenceCounter = Data()
        self.sequenceCounter.reserveCapacity(8)
        
        self.bacEncKey1 = Data()
        self.bacEncKey2 = Data()
        
        self.bacMacKey1 = Data()
        self.bacMacKey1.reserveCapacity(128)
        self.bacMacKey2 = Data()
        self.bacMacKey2.reserveCapacity(128)
        
        self.isFileSelected = false
        self.cursor = 0
        self.fileSize = 0
        self.progress = 0
        self.progressDG1 = 0
        self.progressDG2 = 0
        self.progressSOD = 0
        
        self.dg1 = Data()
        self.dg2 = Data()
        self.sod = Data()
        
        self.completionHandler = completionHandler
        self.progressHandler = progressHandler
    }
    
    func getSessionKeys() -> (Data, Data) {
        
        rndifd = PassportCryptoWrapper.generateRandom(length: 8);
        kifd = PassportCryptoWrapper.generateRandom(length: 16);
        rndifd = Tools.dataWithHexString(hex: "781723860C06C226")
        kifd = Tools.dataWithHexString(hex: "0B795240CB7049B01C19B33E32804F0B")
        
        var s = Data()
        
        s.append(rndifd)
        s.append(rndic)
        s.append(kifd)
        
        (bacEncKey1, bacEncKey2) = self.bacKeys.getKEnc()
        print("bacEncKey1: " + Tools.hexDump(data: bacEncKey1 as NSData))
        print("bacEncKey2: " + Tools.hexDump(data: bacEncKey2 as NSData))
        
        var encryptedMessage = Data()
        
        print("s: " + Tools.hexDump(data: s as NSData))
        
        encryptedMessage = PassportCryptoWrapper.encryptWith3DES(message: s, key1: bacEncKey1, key2: bacEncKey2)
        
        print("encryptedMessage: \(encryptedMessage)")
        print("encryptedMessage: " + Tools.hexDump(data: encryptedMessage as NSData))
        
        (bacMacKey1, bacMacKey2) = self.bacKeys.getKMac()
        print("bacMacKey1: " + Tools.hexDump(data: bacMacKey1 as NSData))
        print("bacMacKey2: " + Tools.hexDump(data: bacMacKey2 as NSData))
        
        let mac = PassportCryptoWrapper.calculate3DESMAC(message: encryptedMessage, key1: bacMacKey1, key2: bacMacKey2)
        
        print("mac: " + Tools.hexDump(data: mac as NSData))
        
        return (encryptedMessage, mac)
    }
    
    func handleSessionKeysResponse(encryptedResponse: Data) -> Bool {
        
        if encryptedResponse.count <= 8 {
            return false
        }
        
        print("encryptedResponse: " + Tools.hexDump(data: encryptedResponse as NSData))
        
        print("rndifd: " + Tools.hexDump(data: rndifd as NSData))
        print("kifd: " + Tools.hexDump(data: kifd as NSData))
        
        let encryptedResponse2 = Tools.split(data: encryptedResponse, from: 0, size: (encryptedResponse.count - 8))
        
        print("encryptedResponse2: " + Tools.hexDump(data: encryptedResponse2 as NSData))
        
        let decryptedResponse = PassportCryptoWrapper.decryptWith3DES(encryptedMessage: encryptedResponse2, key1: bacEncKey1, key2: bacEncKey2)
        
        print("decryptedResponse: " + Tools.hexDump(data: decryptedResponse as NSData))
        
        let kic = Tools.split(data: decryptedResponse, from: 16, size: 16)
        
        self.sequenceCounter = Tools.split(data: decryptedResponse, from: 4, size: 4)
        self.sequenceCounter.append(Tools.split(data: decryptedResponse, from: 12, size: 4))
        
        print("Sequence counter: " + Tools.hexDump(data: self.sequenceCounter as NSData))
        
        print("kic: " + Tools.hexDump(data: kic as NSData))
        let kSeed = PassportCryptoWrapper.calculateXor(c1: kic, c2: kifd)
        print("kSeed: " + Tools.hexDump(data: kSeed as NSData))
        self.bacKeys.setSeed(newSeed: kSeed)
        
        (bacEncKey1, bacEncKey2) = bacKeys.getKEnc()
        (bacMacKey1, bacMacKey2) = bacKeys.getKMac()
        
        print("bacEncKey1: " + Tools.hexDump(data: self.bacEncKey1 as NSData))
        print("bacEncKey2: " + Tools.hexDump(data: self.bacEncKey2 as NSData))
        
        return true;
    }
    
    func handleReadFilePartResponse(encryptedResponse: Data) -> Bool {
        if encryptedResponse.count <= 8 {
            return false
        }
        
        let responseLenght = PassportCryptoWrapper.asn1ToInt(asn1: Tools.split(data: encryptedResponse, from: 1, size: 3))
        let encryptedMessage = Tools.split(data: encryptedResponse, from: 3, size: Int(responseLenght))
        print("responseLenght: \(responseLenght)")
        
        let decryptedResponse = PassportCryptoWrapper.decryptWith3DES(encryptedMessage: encryptedMessage, key1: bacEncKey1, key2: bacEncKey2)
        
        print("decryptedResponse: " + Tools.hexDump(data: decryptedResponse as NSData))
        let unpaddedResponse = PassportCryptoWrapper.unpad(message: decryptedResponse)
        print("unpaddedResponse: " + Tools.hexDump(data: unpaddedResponse as NSData))
        if self.fileSize  == 0 {
            self.fileSize = PassportCryptoWrapper.asn1ToInt(asn1:
                Tools.split(data: unpaddedResponse, from: 1, size: 3)
            )
            let asn1Length = UInt(PassportCryptoWrapper.calculateAsn1Length(intVal: UInt32(fileSize)))
            fileSize = asn1Length + fileSize + 1
            print("fileSize: \(fileSize)")
        }
        
        self.cursor = self.cursor + UInt(unpaddedResponse.count)
        
        if currentStep == .readDG1 {
            self.dg1.append(unpaddedResponse)
        } else if currentStep == .readDG2 {
            self.dg2.append(unpaddedResponse)
        } else if currentStep == .readSOD {
           self.sod.append(unpaddedResponse)
       }
        
        return true;
    }
    
    func selectFile(fileID: Data) -> Data {
        print("MacKey:" + Tools.hexDump(data: bacMacKey1 as NSData) + Tools.hexDump(data: bacMacKey2 as NSData))
        
        var commandHeader = Data()
        
        commandHeader.append(0x0C)
        commandHeader.append(0xA4)
        commandHeader.append(0x02)
        commandHeader.append(0x0C)
        
        let paddedCommandHeader = PassportCryptoWrapper.paddMessage(message: commandHeader)
        print("paddedCommandHeader:" + Tools.hexDump(data: paddedCommandHeader as NSData))
        
        let paddedCommand = PassportCryptoWrapper.paddMessage(message: fileID)
        print("paddedCommand:" + Tools.hexDump(data: paddedCommand as NSData))
        
        let encryptedCommand = PassportCryptoWrapper.encryptWith3DES(message: paddedCommand, key1: bacEncKey1, key2: bacEncKey2)
        print("encryptedCommand:" + Tools.hexDump(data: encryptedCommand as NSData))
        
        let do87 = PassportCryptoWrapper.buildDO87(command: encryptedCommand)
        print("do87:" + Tools.hexDump(data: do87 as NSData))
        
        var m = Data()
        m.append(paddedCommandHeader)
        m.append(do87)
        
        var n = Data()
        n.append(self.sequenceCounter)
        n.append(m)
        
        print("n:" + Tools.hexDump(data: n as NSData))
        
        let mac = PassportCryptoWrapper.calculate3DESMAC(message: n, key1: bacMacKey1, key2: bacMacKey2)
        print("mac:" + Tools.hexDump(data: mac as NSData))
        
        let do8e = PassportCryptoWrapper.buildDO8E(mac: mac)
        print("do8e:" + Tools.hexDump(data: do8e as NSData))
        
        var commandData = Data()
        commandData.append(do87)
        commandData.append(do8e)
        
        return commandData
    }
    
    func readFilePart(from: UInt, size: UInt8) -> NFCISO7816APDU {
        
        var commandHeader = Data()
        
        commandHeader.append(0x0C)
        commandHeader.append(0xB0)
        
        let headerOffset = PassportCryptoWrapper.intTo16bitsChar(intVal: UInt32(from))
        
        commandHeader.append(Tools.split(data: headerOffset, from: 0, size: 1))
        commandHeader.append(Tools.split(data: headerOffset, from: 1, size: 1))
        
        let paddedCommandHeader = PassportCryptoWrapper.paddMessage(message: commandHeader)
        
        let do97 = PassportCryptoWrapper.buildDO97(length: size)
        
        var m = Data()
        m.append(paddedCommandHeader)
        m.append(do97)
        
        var n = Data()
        n.append(sequenceCounter)
        n.append(m)
        
        let mac = PassportCryptoWrapper.calculate3DESMAC(message: n, key1: bacMacKey1, key2: bacMacKey2)
        
        let do8e = PassportCryptoWrapper.buildDO8E(mac: mac)
        
        var commandData = Data()
        commandData.append(do97)
        commandData.append(do8e)
        
        var commandWithHeader = Data()
        commandWithHeader.append(0x0C)
        commandWithHeader.append(0xB0)
        commandWithHeader.append(Tools.split(data: headerOffset, from: 0, size: 1))
        commandWithHeader.append(Tools.split(data: headerOffset, from: 1, size: 1))
        commandWithHeader.append(UInt8(commandData.count))
        commandWithHeader.append(commandData)
        commandWithHeader.append(0x00)
        return NFCISO7816APDU(data: commandWithHeader)!
    }
    
    func read() {
        
        if progress == 100 {
            self.progressHandler(100)
        } else {
            let calculatedProgress = Double(progress) + (Double(progressDG1) * 0.1) + (Double(progressDG2) * 0.7) + (Double(progressSOD) * 0.1)
            self.progressHandler(UInt(calculatedProgress.rounded()))
        }
        
        switch currentStep {
            case .getAID:
                let aid = Tools.dataWithHexString(hex: "A0000002471001")
                let myAPDU = NFCISO7816APDU(instructionClass: 0, instructionCode: 0xA4, p1Parameter: 0x04, p2Parameter: 0x0c, data: aid, expectedResponseLength: -1)
                self.tag.sendCommand(apdu: myAPDU, completionHandler:self.callback)
                break
            case .getRND:
                let myAPDU = NFCISO7816APDU(instructionClass: 0, instructionCode: 0x84, p1Parameter: 0, p2Parameter: 0, data: Data(), expectedResponseLength: 8)
                self.tag.sendCommand(apdu: myAPDU, completionHandler:self.callback)
                break
            case .initSession:
                var encryptedMessage: Data
                var mac: Data
                (encryptedMessage, mac) = getSessionKeys()
                encryptedMessage.append(mac)
                
                print("initSession command: " + Tools.hexDump(data: encryptedMessage as NSData))
                
                let myAPDU = NFCISO7816APDU(instructionClass: 0, instructionCode: 0x82, p1Parameter: 0, p2Parameter: 0, data: encryptedMessage, expectedResponseLength: 40)
                self.tag.sendCommand(apdu: myAPDU, completionHandler:self.callback)
                break
        case .readDG1, .readDG2, .readSOD:
                self.sequenceCounter = PassportCryptoWrapper.incrementSequenceCounter(sequenceCounter: sequenceCounter)
                if !isFileSelected {
                    print("Sequence counter: " + Tools.hexDump(data: self.sequenceCounter as NSData))
                    print("New sequence counter: " + Tools.hexDump(data: self.sequenceCounter as NSData))
                    var fileId = Data()
                    
                    fileId.append(0x01)
                    
                    if currentStep == .readDG1 {
                        fileId.append(0x01)
                    } else if currentStep == .readDG2 {
                        fileId.append(0x02)
                    } else if currentStep == .readSOD {
                        fileId.append(0x1D)
                    }
                    
                    let selectFileCommand = self.selectFile(fileID: fileId)
                    print("SelectFile cmd:" + Tools.hexDump(data:selectFileCommand as NSData))
                    
                    let selectFileAPDU = Tools.constructAPDU(instructionClass: 0x0C, instructionCode: 0xA4, p1Parameter: 0x02, p2Parameter: 0x0C, data: selectFileCommand, expectedResponseLength: 0)
                    
                    self.tag.sendCommand(apdu: selectFileAPDU, completionHandler:self.callback)
                } else {
                    self.sequenceCounter = PassportCryptoWrapper.incrementSequenceCounter(sequenceCounter: sequenceCounter)
                    
                    if self.fileSize == 0 {
                        let readFirstBytesAPDU = readFilePart(from: 0, size: 4)
                        self.tag.sendCommand(apdu: readFirstBytesAPDU, completionHandler:self.callback)
                        return
                    } else {
                        var chunckSize = 112
                        if chunckSize > (self.fileSize - self.cursor) {
                            chunckSize = Int(self.fileSize - self.cursor)
                        }
                        let readFilePartAPDU = readFilePart(from: cursor, size: UInt8(chunckSize))
                        self.tag.sendCommand(apdu: readFilePartAPDU, completionHandler:self.callback)
                    }
                }
                
                break
            case .done:
                self.completionHandler(true, self.dg1, self.dg2, self.sod)
                break
        }
    }
    
    func abort() {
        self.completionHandler(false, Data(), Data(), Data())
    }
    
    func callback(data: Data, sw1: UInt8, sw2: UInt8, error: Error?) {
        switch currentStep {
        case .getAID:
            progress = 1
            if error == nil && sw1 == 0x90 && sw2 == 0x00 {
                currentStep = .getRND
                print("Selected AID -> success")
                read()
            } else {
                print("Selected AID -> failed")
                print("sw1:" + String(sw1) + " sw2:" + String(sw2))
                print("Error: " + error.debugDescription)
                abort()
            }
            break
        case .getRND:
            progress = 5
            if error == nil && sw1 == 0x90 && sw2 == 0x00 {
                currentStep = .initSession
                print("Get RND -> success")
                print("RND:" + Tools.hexDump(data: data as NSData))
                self.rndic = data
                read()
            } else {
                print("Get RND -> failed")
                print("sw1:" + String(sw1) + " sw2:" + String(sw2))
                print("Error: " + error.debugDescription)
                abort()
            }
            break
        case .initSession:
            progress = 10
            if error == nil && sw1 == 0x90 && sw2 == 0x00 {
                print("Init session response:" + Tools.hexDump(data: data as NSData))
                _ = handleSessionKeysResponse(encryptedResponse: data)
                currentStep = .readDG1
                print("Init session -> success")
                read()
            } else {
                print("Init session -> failed")
                print("sw1:" + String(sw1) + " sw2:" + String(sw2))
                print("Error: " + error.debugDescription)
                abort()
            }
            break
        case .readDG1, .readDG2, .readSOD:
            print("readDG1/readDG2/readSOD callback")
            if !self.isFileSelected {
                if error == nil && sw1 == 0x90 && sw2 == 0x00 {
                    self.isFileSelected = true
                    print("Select file -> success")
                    read()
                } else {
                    print("Select file -> failed")
                    print("sw1:" + String(sw1) + " sw2:" + String(sw2))
                    print("resp data:" + Tools.hexDump(data:data as NSData))
                    print("Error: " + error.debugDescription)
                    abort()
                }
            } else {
                if error == nil && sw1 == 0x90 && sw2 == 0x00 {
                    self.isFileSelected = true
                    print("Read first bytes -> success")
                    print("resp data:" + Tools.hexDump(data:data as NSData))
                    _ = handleReadFilePartResponse(encryptedResponse: data)
                    
                    
                    let calculatedProgress = Double(self.cursor)/Double(self.fileSize) * 100.0
                    if currentStep == .readDG1 {
                        self.progressDG1 = UInt(calculatedProgress.rounded())
                    } else if currentStep == .readDG2 {
                        self.progressDG2 = UInt(calculatedProgress.rounded())
                    } else if currentStep == .readSOD {
                        self.progressSOD = UInt(calculatedProgress.rounded())
                    }
                    
                    if self.cursor < self.fileSize {
                        read()
                    } else {
                        if currentStep == .readDG1 {
                            print("DG1:" + Tools.hexDump(data:self.dg1 as NSData))
                            currentStep = .readDG2
                            self.isFileSelected = false
                            self.cursor = 0
                            self.fileSize = 0
                            self.sequenceCounter = PassportCryptoWrapper.incrementSequenceCounter(sequenceCounter: sequenceCounter)
                            read()
                        } else if currentStep == .readDG2 {
                            print("DG2:" + Tools.hexDump(data:self.dg2 as NSData))
                            currentStep = .readSOD
                            self.isFileSelected = false
                            self.cursor = 0
                            self.fileSize = 0
                            self.sequenceCounter = PassportCryptoWrapper.incrementSequenceCounter(sequenceCounter: sequenceCounter)
                            read()
                        } else if currentStep == .readSOD {
                            print("SOD:" + Tools.hexDump(data:self.sod as NSData))
                            currentStep = .done
                            read()
                        }
                    }
                } else {
                    print("Read first bytes -> failed")
                    print("sw1:" + String(sw1) + " sw2:" + String(sw2))
                    print("resp data:" + Tools.hexDump(data:data as NSData))
                    print("Error: " + error.debugDescription)
                    abort()
                }
            }
            break
        case .done:
            progress = 100
            break
        }
    }
    
    func setBacKeys(_ bacKeys: BacKeys) {
        self.bacKeys = bacKeys
        self.bacKeys.setSeed(newSeed: self.bacKeys.calculateKSeed())
    }

}
