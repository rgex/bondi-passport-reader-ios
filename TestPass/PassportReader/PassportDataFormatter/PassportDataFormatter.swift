//
//  PassportDataFormatter.swift
//  TestPass
//
//  Created by Jan Moritz on 23.09.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import Foundation

class PassportDataFormatter {
    func formateGender(input: String, locale: String) {
        
    }
    
    static func formatPassportDateToReadableDate(dateString: String, locale: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYMMdd"
        if let date = dateFormatter.date(from: dateString) {
            switch locale {
            case "us":
                let dateFormatterOutput = DateFormatter()
                dateFormatterOutput.dateFormat = "MM/dd/YY"
                
                return dateFormatterOutput.string(from:date)
            default:
                let dateFormatterOutput = DateFormatter()
                dateFormatterOutput.dateFormat = "dd.MM.YY"
                
                return dateFormatterOutput.string(from:date)
            }
        }
        return dateString
    }
}
