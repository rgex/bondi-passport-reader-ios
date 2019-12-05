//
//  Iso19794Parser.swift
//  TestPass
//
//  Created by Jan Moritz on 21.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation

class Iso19794Response {
    var image: Data
    var imageType: Data
    var gender: Data
    var eyeColour: Data
    var hairColour: Data

    init() {
        self.image = Data()
        self.imageType = Data()
        self.gender = Data()
        self.eyeColour = Data()
        self.hairColour = Data()
    }
    
    func setImage(_ image: Data) {
        self.image = image
    }
    
    func getImage() -> Data {
        return self.image
    }
    
    func setImageType(_ type: Data) {
        self.imageType = type
    }
    
    func getImageType() -> Data {
        return self.imageType
    }
    
    func setGender(_ gender: Data) {
        self.gender = gender
    }
    
    func getGender() -> Data {
        return gender
    }
    
    func setEyeColour(_ eyeColour: Data) {
        self.eyeColour = eyeColour
    }
    
    func getEyeColour() -> Data {
        return self.eyeColour
    }
    
    func setHairColour(_ hairColour: Data) {
        self.hairColour = hairColour
    }
    
    func getHairColour() -> Data {
        return self.hairColour
    }
}

class Iso19794Parser {
    
    var payload: Data
    
    init(payload: Data) {
        self.payload = payload
    }
    
    func parse() -> Iso19794Response{
        var cursor = 0
        let iso19794Response = Iso19794Response()
    
        /**
         * Facial record header
         */
        cursor += 4 //skip Format Identifier
        cursor += 4 //skip Version Number
    
        cursor += 4 //skip Length of Record
        cursor += 2 //skip number of facial images
    
        /**
         * Facial record data
         */
        cursor += 4 //skip Facial Record Data Length
    
        if cursor > self.payload.count {
            return iso19794Response
        }
    
        let numberOfFeaturePoints = OCPCWrapper.from16bitsChar(toInt:
            Tools.split(data: self.payload, from: cursor, size: 2)
        )
        
        cursor += 2
        iso19794Response.setGender(
            Tools.split(data: self.payload, from: cursor, size: 1)
        )
        cursor += 1 //skip Gender
        
        iso19794Response.setEyeColour(
            Tools.split(data: self.payload, from: cursor, size: 1)
        )
        cursor += 1 //skip Eye Colour
        
        iso19794Response.setHairColour(
            Tools.split(data: self.payload, from: cursor, size: 1)
        )
        cursor += 1 //skip Hair Colour
        cursor += 3 //skip Property Mask
        cursor += 2 //skip Expression
        cursor += 3 //skip Pose Angle
        cursor += 3 //skip Pose Angle Uncertainty
    
        print("numberOfFeaturePoints: \(numberOfFeaturePoints)")
        /**
         * Feature point(s)
         */
        if numberOfFeaturePoints > 0 {
            for _ in [0..<numberOfFeaturePoints] {
                print("numberOfFeaturePoints: \(numberOfFeaturePoints)")
                cursor += 8 //skip Feature Point
            }
        }
    
        /**
         * Image Information
         */
        cursor += 1 //skip Face Image Type
        iso19794Response.setImage(
            Tools.split(data: self.payload, from: cursor, size: 1)
        )
        cursor += 1 //skip Image Data Type
        cursor += 2 //skip Width
        cursor += 2 //skip Height
        cursor += 1 //skip Image Colour Space
        cursor += 1 //skip Source Type
        cursor += 2 //skip Device Type
        cursor += 2 //skip Quality
    
        if cursor > self.payload.count {
            return iso19794Response
        }
    
        iso19794Response.setImage(
            Tools.split(data: self.payload, from: cursor, size: self.payload.count - cursor)
        )
        
        return iso19794Response
    }
}
