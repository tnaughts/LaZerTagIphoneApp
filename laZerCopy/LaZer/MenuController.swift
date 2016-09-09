//
//  MenuController.swift
//  LaZer
//
//  Created by Timothy Naughton on 9/5/16.
//  Copyright © 2016 Timothy Naughton. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Alamofire

class MenuController: UIViewController {
    
    

    @IBAction func resetGame(sender: UIButton) {
        Alamofire.request(.GET, "https://blooming-brook-68896.herokuapp.com/teams/1/win")
    }
    
    
    override func viewDidLoad(){
        
        
        
        
        super.viewDidLoad()
    }

    
   
    
    
    
    
}
