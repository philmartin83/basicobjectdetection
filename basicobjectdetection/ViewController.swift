//
//  ViewController.swift
//  Basic Object Detecton
//
//  Created by Phil Martin on 09/06/2018.
//  Copyright © 2018 Phil Martin. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVSpeechSynthesizerDelegate {
    
    var btn = UIButton()
    var theCameraViewLayer = AVCaptureVideoPreviewLayer()
    var objectDetected : Bool = false
    var objectType : String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        launchAVCaptureSession()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func launchAVCaptureSession()
    {
        let launchCapture = AVCaptureSession()
        launchCapture.sessionPreset = .photo
        guard let getTheCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: getTheCaptureDevice) else { return }
        launchCapture.addInput(input)
        launchCapture.startRunning()
        
        theCameraViewLayer = AVCaptureVideoPreviewLayer(session: launchCapture)
        view.layer.addSublayer(theCameraViewLayer)
        theCameraViewLayer.frame = CGRect.init(origin: CGPoint.init(x: 0, y: 0) , size: CGSize.init(width: view.frame.width, height: view.frame.height - 100))
        
        searchObjectDetection(captureSession: launchCapture)
    }
    
    func searchObjectDetection(captureSession : AVCaptureSession)
    {
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "theQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        guard let thePixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        
        guard let myModel = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let myRequest  = VNCoreMLRequest(model: myModel) { (finishedRequest, error) in
            if (error != nil)
            {
                let badError = UIAlertController.init(title: "Error", message: "cannot detect the object", preferredStyle: UIAlertControllerStyle.alert)
                self.present(badError, animated: true, completion: nil)
            }
            else
            {
                guard let result = finishedRequest.results as? [VNClassificationObservation] else {return}
                
                guard let observation = result.first else {return}
                let accuaracy = observation.confidence * 100
                
                if (accuaracy >= 90 && !self.objectDetected)
                {
                    self.objectDetected = true
                    self.objectType = observation.identifier;
                    self.displayButton()
                }
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: thePixelBuffer, options: [:]).perform([myRequest])
        
    }
    
    func displayButton()
    {
        btn.isHidden = false
        if(self.objectDetected)
        {
            let objectedRecognied = UIAlertController.init(title: "Object Found", message: "Object found press 'Describe Object' to confirm", preferredStyle: UIAlertControllerStyle.alert)
            objectedRecognied.addAction( UIAlertAction.init(title: "Describe Object", style: UIAlertActionStyle.default, handler: { (okAction) in
                self.textToSpeachOvject()
            }))
            self.present(objectedRecognied, animated: true, completion: nil)
            
        }
        
    }
    func textToSpeachOvject()
    {
        let  speech = AVSpeechSynthesizer()
        speech.delegate = self
        let myWords =  String.init(format: "The object found is %@", self.objectType)
        let talkToMe = AVSpeechUtterance(string:  myWords)
        talkToMe.rate = 0.3
        speech.speak(talkToMe)
        
    }
    
    private func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
        
        self.objectDetected = false
    }
}



