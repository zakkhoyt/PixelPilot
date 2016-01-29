//
//  ViewController.swift
//  PixelPilot
//
//  Created by Zakk Hoyt on 1/29/16.
//  Copyright © 2016 Zakk Hoyt. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var serialComboBox: NSComboBox!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var imageButton: NSButton!
    @IBOutlet weak var imageLabel: NSTextField!
    @IBOutlet weak var imageWell: NSImageView!
    private var imageURL: NSURL? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    private func error(description: String?, failureReason: String?) -> NSError {
        
        var userInfo = [String: String]()
        
        if let description = description {
            userInfo[NSLocalizedDescriptionKey] = description
        } else {
            userInfo[NSLocalizedDescriptionKey] = "Error"
        }
        
        if let failureReason = failureReason {
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        } else {
//            userInfo[NSLocalizedFailureReasonErrorKey] = "Undefined"
        }
        
        
        let error = NSError(domain: "PixelPilot", code: -10001, userInfo: userInfo)
        return error
        
    }
    
    private func displayError(error: NSError) {
        
        
        let alert = NSAlert()
        alert.messageText = error.localizedDescription
        if let localizedFailureReason = error.localizedFailureReason {
            alert.informativeText = localizedFailureReason
        }
        alert.addButtonWithTitle("Okay")
        alert.runModal()
    }
    
    private func loadImage(url: NSURL) {
        if let image = NSImage(contentsOfURL: url) {
            let smallImage = self.resizeImage(image)
            imageWell.image = smallImage
        } else {
            let alertError = error("Could not load image from URL", failureReason: nil)
            displayError(alertError)
        }
    }
    
    private func resizeImage(image: NSImage) -> NSImage {
        let smallFrame = NSRect(x: 0, y: 0, width: 16, height: 16)
        let sourceImageRep = image.bestRepresentationForRect(smallFrame, context: nil, hints: nil)
        let targetImage = NSImage(size: smallFrame.size)
        targetImage.lockFocus()
        sourceImageRep?.drawInRect(smallFrame)
        targetImage.unlockFocus()
        return targetImage
    }

    // MARK: IBActions
    
    @IBAction func imageButtonAction(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        let clicked = panel.runModal()
        
        if clicked == NSFileHandlingPanelOKButton {
            for url in panel.URLs {
                
                if let path = url.path {
                    print("selected input file: " + url.description)
                    imageLabel.stringValue = path
                    loadImage(url)
                } else {
                    let alertError = error("Invalid file url", failureReason: nil)
                    displayError(alertError)

                }
            }
        }
    }

    
    @IBAction func sendButtonAction(sender: AnyObject) {
    }
    
    
    @IBAction func serialComboAction(sender: AnyObject) {
    }
    
    
    
}

