//
//  StartController.swift
//  LaZer
//
//  Created by Apprentice on 9/8/16.
//  Copyright © 2016 Timothy Naughton. All rights reserved.
//

import Foundation

import UIKit
import AVFoundation
import Alamofire

var themeSong = AVAudioPlayer()

class StartController: UIViewController {
    
    
    
    @IBAction func ResetGameButton(sender: AnyObject) {
    
    
       Alamofire.request(.GET, "https://blooming-brook-68896.herokuapp.com/teams/1/win")
    }
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
    
        let themePath = NSBundle.mainBundle().pathForResource("Recognize", ofType: "mp3")
        let themeURL = NSURL(fileURLWithPath: themePath!)
        do{
            try themeSong = AVAudioPlayer(contentsOfURL: themeURL)
            themeSong.prepareToPlay()
            themeSong.play()
            
        }
        catch let err as NSError
        {
            print(err.debugDescription)
        }
        
        
    }
    
    
    
    
    
    
    
}
