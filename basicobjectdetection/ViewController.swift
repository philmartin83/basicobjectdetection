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

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVSpeechSynthesizerDelegate  {
    
    var btn = UIButton()
    var theCameraViewLayer = AVCaptureVideoPreviewLayer()
    var objectDetected : Bool = false
    var objectType : String = ""
    let speech = AVSpeechSynthesizer()
    
    
    let descriptionLabel : UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        speech.delegate = self
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        session.addInput(input)
        
         session.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "theQueue"))
        session.addOutput(dataOutput)
    }
    
    func layoutDesciptionLabel()
    {
        view.addSubview(descriptionLabel)
        descriptionLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        descriptionLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let objectObservation = results.first else { return }
            print(objectObservation.identifier, objectObservation.confidence)
            DispatchQueue.main.async {
                
                self.descriptionLabel.text = "\(objectObservation.identifier) \(objectObservation.confidence * 100)"
                
                let accuarcy = objectObservation.confidence * 100
                if(accuarcy >= 89 && !self.objectDetected)
                {
                    self.objectType = objectObservation.identifier
                    self.objectDetected = true
                    self.displayButton()
                }
             
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func displayButton()
    {
        if(self.objectDetected)
        {
            let objectedRecognied = UIAlertController.init(title: "Object Found", message: "Object found press 'Describe Object' to confirm", preferredStyle: UIAlertControllerStyle.alert)
            objectedRecognied.addAction( UIAlertAction.init(title: "Describe Object", style: UIAlertActionStyle.default, handler: { (okAction) in
                self.textToSpeachObject()
            }))
            self.present(objectedRecognied, animated: true, completion: nil)
            
        }
        
    }
    func textToSpeachObject()
    {
        let myWords = "The object found is \(self.objectType)"
        let talkToMe = AVSpeechUtterance(string:  myWords)
        talkToMe.rate = 0.55
        speech.speak(talkToMe)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        perform(#selector(setDetectionToFalse), with: nil, afterDelay: 1.0)
    }
    
    @objc func setDetectionToFalse()
    {
        self.objectDetected = false
    }
}



