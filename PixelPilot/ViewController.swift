//
//  ViewController.swift
//  PixelPilot
//
//  Created by Zakk Hoyt on 1/29/16.
//  Copyright © 2016 Zakk Hoyt. All rights reserved.
//
//  This app will load an image, resize it to 16x16, then send each pixel's RGB (from 0 - 255) to an arduino which will use
//  https://github.com/adafruit/Adafruit_NeoPixel
//  Using serial cocoapod here
//  https://github.com/armadsen/ORSSerialPort

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var serialComboBox: NSComboBox!
    @IBOutlet weak var sendButton: NSButton!
    @IBOutlet weak var imageButton: NSButton!
    @IBOutlet weak var imageLabel: NSTextField!
    @IBOutlet weak var imageWell: NSImageView!
    
    private var imageURL: NSURL? = nil
    private var serialPorts = [ORSSerialPort]()
    override func viewDidLoad() {
        super.viewDidLoad()

        scanSerialPorts()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func scanSerialPorts() {
        // See how to use here:
        
        // Serial ports
        serialPorts.removeAll()
        let ports = ORSSerialPortManager.sharedSerialPortManager().availablePorts
        for port in ports{
            print("port: " + port.name)
            serialPorts.append(port)
        }

        // UI
        serialComboBox.removeAllItems()
        for port in serialPorts {
            serialComboBox.addItemWithObjectValue(port.name)
        }
        if serialPorts.count > 0 {
            serialComboBox.selectItemAtIndex(0)
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
        }
        
        
        let error = NSError(domain: "PixelPilot", code: -10001, userInfo: userInfo)
        return error
        
    }
    
    private func displayError(error: NSError) {
        print("Error: " + error.localizedDescription)
        
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
        panel.allowedFileTypes = [kUTTypeImage as String]
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

    @IBAction func refreshButtonAction(sender: AnyObject) {
        scanSerialPorts()
    }
    
    @IBAction func aboutButtonAction(sender: AnyObject) {
        let alert = NSAlert()
        alert.messageText = "How to use:"
        alert.informativeText = "The loaded image is resized to 16x16. When you tap send, a connection is made to the arduino at 9600 baud. Pixel data is sent starting from the bottom left each row at a time.\n" +
            "This is an example string for the bottom left pixel (first one):\n" +
            "x:0|y:15|r:255|g:255|b:255\\n\n" +
            "Use string tokenizers to parse the data and then clock it out to neopixel"
        

        alert.addButtonWithTitle("Okay")
        alert.runModal()

    }
    
    @IBAction func sendButtonAction(sender: AnyObject) {
        if serialPorts.count == 0 {
            return
        }
        

        let port = serialPorts[serialComboBox.indexOfSelectedItem] // ORSSerialPort
        port.baudRate = 9600;
        port.parity = .None;
        port.numberOfStopBits = 1;
        port.usesRTSCTSFlowControl = true;
        port.delegate = self

        // send one pixel of dat
        let string = "r:255|g:128|b:64\n"
        if let data = string .dataUsingEncoding(NSUTF8StringEncoding) {
            port.sendData(data)
        } else {
            let de = error("Failed to send data", failureReason: "Could not create data from string")
            displayError(de)
        }
        
        let image = imageWell.image
        let rawImage = NSBitmapImageRep(data: (image?.TIFFRepresentation)!)
        for y in 15.stride(to: -1, by: -1) {
            for x in 0..<16 {
                let color = rawImage?.colorAtX(x, y: y)
                if let red = color?.redComponent, green = color?.greenComponent, blue = color?.blueComponent {
                    let r = UInt(red * 255)
                    let g = UInt(green * 255)
                    let b = UInt(blue * 255)
                    
                    
                    let string = ("x:\(x)|y:\(y)|r:\(r)|g:\(g)|b:\(b)")
                    let outputString = string + "\n"
                    print("sending: " + string)
                    if let data = outputString .dataUsingEncoding(NSUTF8StringEncoding) {
                        port.sendData(data)
                    } else {
                        print("Could not create pixel string for " + outputString)
                    }
                }
            }
        }
    }
    
    @IBAction func serialComboAction(sender: AnyObject) {
        
    }
}


extension ViewController: ORSSerialPortDelegate {
    func serialPortWasRemovedFromSystem(serialPort: ORSSerialPort) {
        let de = error("Disconnected", failureReason: "Serial port was removed from system")
        displayError(de)
        scanSerialPorts()
    }
}

