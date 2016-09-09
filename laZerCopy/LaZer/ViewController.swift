//
//  ViewController.swift
//  LaZer
//
//  Created by Timothy Naughton on 9/2/16.
//  Copyright © 2016 Timothy Naughton. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

class ViewController: UIViewController {
    
    var captureSession = AVCaptureSession()
    var sessionOutput = AVCaptureStillImageOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
//    var kranz = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Din Daa Daa ; George Kranz", ofType: "mp3")!)
    var audioPlayer = AVAudioPlayer()
   
    var hitNoise = AVAudioPlayer()
    var reloadNoise = AVAudioPlayer()
    var tags = 0
    var redTeamScore = 0
    var blueTeamScore = 0
    var amo = 5
    
    
    
 
    @IBOutlet weak var tagCount: UILabel!

    @IBOutlet weak var homeButton: UIButton!
    
    @IBOutlet weak var gameWinner: UILabel!
    @IBOutlet weak var blueTeamLabel: UILabel!
    @IBOutlet weak var laser1: UILabel!
    @IBOutlet weak var laser2: UILabel!
    @IBOutlet weak var laser3: UILabel!
    @IBOutlet weak var crossHair: UIButton!
    
    
    

    
    func redTeamInfo() {
          Alamofire.request(.GET, "https://blooming-brook-68896.herokuapp.com/teams/1.json").responseJSON{(response) -> Void in
            
            if let redTeam = response.result.value {
                self.redTeamScore = (redTeam["score"] as! Int)
                var redTeamName = (redTeam["name"] as! String)


                self.TagsFired.text = "Red Score: \(self.redTeamScore)"
                
            }
        }
    }


    func blueTeamInfo() {
        
            Alamofire.request(.GET, "https://blooming-brook-68896.herokuapp.com/teams/4.json").responseJSON{(response) -> Void in
            
            if let blueTeam = response.result.value {
                self.blueTeamScore = (blueTeam["score"] as! Int)
                var blueTeamName = (blueTeam["name"] as! String)


                self.blueTeamLabel.text = "Black Score: \(self.blueTeamScore)"
                
                
            }
        }

    }
    
    func winner() {
        if self.blueTeamScore > 19 {
            self.gameWinner.text = "Black Team Wins!"
            homeButton.hidden = false
           
        } else if self.redTeamScore > 19 {
            self.gameWinner.text = "Red Team Wins!"
            homeButton.hidden = false
        } else {
            self.gameWinner.text = " "
        }
    }
    
    
    
    
    
    override func viewDidLoad(){
       
        self.tagCount.text = "Lazer Fuel: \(self.amo)"
        
   
        super.viewDidLoad()
        
        themeSong.stop()
        
        laser1.hidden = true
        laser2.hidden = true
        laser3.hidden = true
        
       homeButton.hidden = true
        let path = NSBundle.mainBundle().pathForResource("laser", ofType: "mp3")
        let hitByLaser = NSBundle.mainBundle().pathForResource("hit", ofType: "mp3")
        let reloadSound = NSBundle.mainBundle().pathForResource("reload", ofType: "mp3")
// commenting out to save MP3s on project       let backgroundPath = NSBundle.mainBundle().pathForResource("kranz", ofType: "mp3")
        let soundURL = NSURL(fileURLWithPath: path!)
        let hitSoundURL = NSURL(fileURLWithPath: hitByLaser!)
        let reloadURL = NSURL(fileURLWithPath: reloadSound!)
//        let backgroundSoundURL = NSURL(fileURLWithPath: backgroundPath!)
        
        
        do{
            try audioPlayer = AVAudioPlayer(contentsOfURL: soundURL)
            try hitNoise = AVAudioPlayer(contentsOfURL: hitSoundURL)
            try reloadNoise = AVAudioPlayer(contentsOfURL: reloadURL)
//            try backgroundSound = AVAudioPlayer(contentsOfURL: backgroundSoundURL)
            audioPlayer.prepareToPlay()
            hitNoise.prepareToPlay()
            reloadNoise.prepareToPlay()
//            backgroundSound.prepareToPlay()
//            backgroundSound.play()
        }
        catch let err as NSError
        {
            print(err.debugDescription)
        }
        
        let redTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("redTeamInfo"), userInfo: nil, repeats: true)
        let blueTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("blueTeamInfo"), userInfo: nil, repeats: true)
        let winnerFinder = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("winner"), userInfo: nil, repeats: true)
        redTimer.tolerance = 0.2
        blueTimer.tolerance = 0.2
        winnerFinder.tolerance = 0.2
    
        
    }
    func playNstop(){
        
        if audioPlayer.playing{
            
            
            audioPlayer.play()
        }else{
            
            audioPlayer.play()
        }
        
        

//     
//        redTeamInfo()
//        blueTeamInfo()

        
}
   
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if motion == .MotionShake{
            amo = 5
            self.tagCount.text = "Lazer Fuel: \(self.amo)"
            reloadNoise.play()
        }
    }
    
    
    @IBOutlet weak var TagsFired: UILabel!

    @IBOutlet weak var CameraView: UIView!
    
    override func viewWillAppear(animated: Bool) {
        
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in devices {
            if device.position == AVCaptureDevicePosition.Back {
                
                do {
                    let input = try AVCaptureDeviceInput(device: device as! AVCaptureDevice)
                    if captureSession.canAddInput(input){
                        captureSession.addInput(input)
                        sessionOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                        
                        if captureSession.canAddOutput(sessionOutput){
                            captureSession.addOutput(sessionOutput)
                            captureSession.startRunning()
                            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                            previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
                            CameraView.layer.addSublayer(previewLayer)
                            
                            previewLayer.position = CGPoint(x: self.CameraView.frame.width / 2, y: self.CameraView.frame.height / 2)
                            previewLayer.bounds = CameraView.frame
                            
                        }
                    }
                    
                }
                catch{
                    print("ERror")
                }
            }
        }
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, fromRect: inputImage.extent)
    }

   
    @IBAction func TakePhoto(sender: UIButton) {
        if amo > 0 {amo = amo - 1}
        self.tagCount.text = "Lazer Fuel: \(self.amo)"
        
    if amo > 0 {
        crossHair.hidden = true
       
        crossHair.enabled = false
        
               playNstop()
        //Alamofire.request(.GET, "https://blooming-brook-68896.herokuapp.com/teams/2/tag")
        if let videoConnection = sessionOutput.connectionWithMediaType(AVMediaTypeVideo){
            let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            fireLaser()
            if (device.hasTorch) {
                
                do {
                    
                    try device.lockForConfiguration()
                    
                    if (device.torchMode == AVCaptureTorchMode.On) {
                        
                        device.torchMode = AVCaptureTorchMode.Off
                        
                        print("off")
                        
                    } else {
                        
                        try device.setTorchModeOnWithLevel(1.0)
                        
                        print("on")
                        
                    }
                    
                    device.unlockForConfiguration()
                    
                } catch {
                    
                    print(error)
                    
                }
                
            }
            
            var seconds = 0.15
            
            var delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            
            var dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            
            
            
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            self.sessionOutput.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                buffer, error in
                
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                var takenImage = (UIImage(data: imageData))
                var ciImage = CIImage(image: takenImage!)
                var cgIImage = self.convertCIImageToCGImage(ciImage!)
                let myImage = UIImage ( CGImage: cgIImage, scale: 1, orientation: UIImageOrientation.Up)
                
                let hit = OpenCVWrapper.codeFinder(myImage)
                if hit == 2
                {
                    Alamofire.request(.GET, "https://blooming-brook-68896.herokuapp.com/teams/1/tag")
                    self.TagsFired.text = "Red Score: \(self.redTeamScore + 1)"
                    self.hitNoise.play()
                }
                else if hit == 1
                {
                    Alamofire.request(.GET, "https://blooming-brook-68896.herokuapp.com/teams/4/tag")
                    self.blueTeamLabel.text = "Black Score: \(self.blueTeamScore + 1)"
                    self.hitNoise.play()
                }
                else
                {
                    NSLog(" hit value is neither true nor false!?")
                }
                
                UIImageWriteToSavedPhotosAlbum(myImage, nil, nil, nil)
                
                })
            })
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                
                
                
                if (device.hasTorch) {
                    
                    do {
                        
                        try device.lockForConfiguration()
                        
                        if (device.torchMode == AVCaptureTorchMode.On) {
                            
                            device.torchMode = AVCaptureTorchMode.Off
                            
                            print("off")
                            
                        } else {
                            
                            try device.setTorchModeOnWithLevel(1.0)
                            
                            print("on")
                            
                        }
                        
                        device.unlockForConfiguration()
                        
                    } catch {
                        
                        print(error)
                        
                    }
                    
                }
                
            })
            
            seconds = 0.8
            delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.crossHair.hidden = false
            })

            seconds = 2
            delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.crossHair.enabled = true
            })


        }
    } else {self.gameWinner.text = "Reload!"}
        
        crossHair.enabled = false
}
   
    //function for laser animation
    func fireLaser(){
        
        self.laser1.hidden = false
        
        var seconds = 0.15
        
        var delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        
        var dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            
            self.laser1.hidden = true
            
            self.laser2.hidden = false
            
        })
        
        seconds = 0.25
        
        delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        
        dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            
            self.laser2.hidden = true
            
            self.laser3.hidden = false
            
        })
        
        seconds = 0.45
        
        delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        
        dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            
            self.laser3.hidden = true
            
            
            
        })
        
        
        
    }
    


}

