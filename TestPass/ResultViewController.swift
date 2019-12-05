//
//  ResultViewController.swift
//  TestPass
//
//  Created by Jan Moritz on 22.06.19.
//  Copyright © 2019 Bondi. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var containerScrollView: UIScrollView!
    
    @IBAction func savePassportImage(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(extractedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: NSLocalizedString("Save error", comment:""), message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: NSLocalizedString("Saved!", comment:""), message: NSLocalizedString("Your passport image has been saved to your photos", comment: ""), preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mrzData!.count - 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.value2, reuseIdentifier: "cell")
        
        let (label, data) = self.mrzData![indexPath.row]
        cell.textLabel?.text = label
        cell.detailTextLabel?.text = data
        return cell
    }
    
    @IBOutlet weak var facialUIImageView: UIImageView!
    
    @IBOutlet weak var tableView1: UITableView!
    var dg1: Data?
    var dg2: Data?
    var sod: Data?
    var isTest: Bool?
    var mrzData: [(String, String)]?
    var extractedImage: UIImage
    
    required init?(coder aDecoder: NSCoder) {
        extractedImage = UIImage()
        super.init(coder: aDecoder)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isTest! == false {
            if(self.dg1 == nil) {
                let ac = UIAlertController(title: NSLocalizedString("Error", comment:""), message: NSLocalizedString("Failed to parse DG1, it is nil", comment: ""), preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
                
                return
            }
            
            if(self.dg2 == nil) {
                let ac = UIAlertController(title: NSLocalizedString("Error", comment:""), message: NSLocalizedString("Failed to parse DG2, it is nil", comment: ""), preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
                
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        var localeCode = "DE"
        if let currentLocaleCode = Locale.current.regionCode {
            localeCode = currentLocaleCode
            
            print("localeCode:" + localeCode)
        }
        
        if self.isTest! {

            self.mrzData = [(String, String)]()
            self.mrzData?.append((NSLocalizedString("Name", comment:""), "MUSTERMANN  ERIKA"))
            self.mrzData?.append((NSLocalizedString("Gender", comment:""), NSLocalizedString("F", comment:"")))
            self.mrzData?.append((NSLocalizedString("Date of birth", comment:""), PassportDataFormatter.formatPassportDateToReadableDate(dateString: "12.08.64", locale: localeCode.lowercased())))
            self.mrzData?.append((NSLocalizedString("Date of expiry", comment:""), PassportDataFormatter.formatPassportDateToReadableDate(dateString: "31.10.20", locale: "de")))
            self.mrzData?.append((NSLocalizedString("Passport Nb.", comment:""), "T01000322"))
            self.mrzData?.append((NSLocalizedString("Country", comment:""), "D"))
            
            self.tableView1.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            self.tableView1.dataSource = self
            self.tableView1.delegate = self
            
            self.extractedImage = UIImage(named: "musterfrau-1") ?? UIImage()
            facialUIImageView.image = self.extractedImage
            
            self.tableView1.layoutIfNeeded()
            self.containerScrollView.contentSize = CGSize(width: self.view.frame.size.width, height: 400 + 500 /*+ self.tableView1.contentSize.height*/)
            
            return
        }
        
        if(self.dg1 != nil) {
            
            let dg1LDS = LDSParser(lds: self.dg1!)
            let tag61 = dg1LDS.getTag("61")
            let tag5F1F = tag61.getTag("5F1F")
            
            let parsedMRZ = MRZParser.parse(mrz: String(data: tag5F1F.getContent(), encoding: .ascii)!)
            
            self.mrzData = [(String, String)]()
            self.mrzData?.append((NSLocalizedString("Name", comment:""), parsedMRZ.getName()))
            self.mrzData?.append((NSLocalizedString("Gender", comment:""), (NSLocalizedString(parsedMRZ.getGender(), comment:""))))
            self.mrzData?.append((NSLocalizedString("Date of birth", comment:""), PassportDataFormatter.formatPassportDateToReadableDate(dateString: parsedMRZ.getDateOfBirth(), locale: localeCode.lowercased())))
            self.mrzData?.append((NSLocalizedString("Date of expiry", comment:""), PassportDataFormatter.formatPassportDateToReadableDate(dateString: parsedMRZ.getDateOfExpiry(), locale: "de")))
            self.mrzData?.append((NSLocalizedString("Passport Nb.", comment:""), parsedMRZ.getPassportNumber()))
            self.mrzData?.append((NSLocalizedString("Country", comment:""), parsedMRZ.getIso2CountryCode()))
            
            self.tableView1.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            self.tableView1.dataSource = self
            self.tableView1.delegate = self
        }
        
        if(self.dg2 != nil) {
            let dg2LDS = LDSParser(lds: self.dg2!)
            let tag75 = dg2LDS.getTag("75")
            if(tag75.getContent().count == 0) {
                print("empty tag75")
                return
            }
            
            let tag7F61 = tag75.getTag("7F61")
            if(tag7F61.getContent().count == 0) {
                print("empty tag7F61")
                return
            }
            
            let tag7F60 = tag7F61.getTag("7F60");
            if(tag7F60.getContent().count == 0) {
                print("empty tag7F60")
                return
            }
            
            var iso19794Bytes = Data()
            
            if(tag7F60.getTag("7F2E").getContent().count != 0) {
                iso19794Bytes = tag7F60.getTag("7F2E").getContent()
            } else if(tag7F60.getTag("5F2E").getContent().count != 0) {
                iso19794Bytes = tag7F60.getTag("5F2E").getContent()
            }
            
            let iso19794Parser = Iso19794Parser(payload: iso19794Bytes)
            let parsedDG2 = iso19794Parser.parse()
            self.extractedImage = UIImage(data:parsedDG2.getImage(),scale:1.0) ?? UIImage()
            facialUIImageView.image = self.extractedImage
            
            self.tableView1.layoutIfNeeded()
            self.containerScrollView.contentSize = CGSize(width: self.view.frame.size.width, height: 400 + 500 /*+ self.tableView1.contentSize.height*/)
        }
        
        if self.sod != nil {
            let sodLDS = LDSParser(lds: self.sod!)
            let tag77 = sodLDS.getTag("77")
            print("tag77.getContent().count:" + String(tag77.getContent().count))
            if tag77.getContent().count > 0 {
                print("getMdAlg:")
                print(String(data: PassportCryptoWrapper.getMdAlg(sod: tag77.getContent()), encoding: .ascii) as Any)
                
                print("getSigAlg:")
                print(String(data: PassportCryptoWrapper.getSigAlg(sod: tag77.getContent()), encoding: .ascii) as Any)
                
                print("getIssuer:")
                print(String(data: PassportCryptoWrapper.getIssuer(sod: tag77.getContent()), encoding: .utf8) as Any)
            } else {
                print("failed to parse SOD")
            }
            
        }
    }
}
