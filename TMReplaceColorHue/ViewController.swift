//
//  ViewController.swift
//  ReplaceColor
//
//  Created by Travis Ma on 9/9/15.
//  Copyright (c) 2015 IMSHealth. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageViewColorBar: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelHue: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var switchWhite: UISwitch!
    var ciImage: CIImage?
    var defaultHue: Float = 205 //default color of blue truck
    var hueRange: Float = 60 //hue angle that we want to replace
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ciImage = CIImage(image: imageView.image!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        labelHue.text = NSString(format:"%.2lf", slider.value) as String
        render()
    }
    
    func HSVtoRGB(_ h : Float, s : Float, v : Float) -> (r : Float, g : Float, b : Float) {
        var r : Float = 0
        var g : Float = 0
        var b : Float = 0
        let C = s * v
        let HS = h * 6.0
        let X = C * (1.0 - fabsf(fmodf(HS, 2.0) - 1.0))
        if (HS >= 0 && HS < 1) {
            r = C
            g = X
            b = 0
        } else if (HS >= 1 && HS < 2) {
            r = X
            g = C
            b = 0
        } else if (HS >= 2 && HS < 3) {
            r = 0
            g = C
            b = X
        } else if (HS >= 3 && HS < 4) {
            r = 0
            g = X
            b = C
        } else if (HS >= 4 && HS < 5) {
            r = X
            g = 0
            b = C
        } else if (HS >= 5 && HS < 6) {
            r = C
            g = 0
            b = X
        }
        let m = v - C
        r += m
        g += m
        b += m
        return (r, g, b)
    }
    
    
    func RGBtoHSV(_ r : Float, g : Float, b : Float) -> (h : Float, s : Float, v : Float) {
        var h : CGFloat = 0
        var s : CGFloat = 0
        var v : CGFloat = 0
        let col = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
        col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
        return (Float(h), Float(s), Float(v))
    }
    
    @IBAction func sliderChanged(_ sender: AnyObject) {
        labelHue.text = NSString(format:"%.2lf", slider.value) as String
        render()
    }
    
    func render() {
        let centerHueAngle: Float = defaultHue/360.0
        var destCenterHueAngle: Float = slider.value
        let minHueAngle: Float = (defaultHue - hueRange/2.0) / 360
        let maxHueAngle: Float = (defaultHue + hueRange/2.0) / 360
        let hueAdjustment = centerHueAngle - destCenterHueAngle
        if destCenterHueAngle == 0 && !switchWhite.isOn {
            destCenterHueAngle = 1 //force red if slider angle is 0
        }
        let size = 64
        var cubeData = [Float](repeating: 0, count: size * size * size * 4)
        var rgb: [Float] = [0, 0, 0]
        var hsv: (h : Float, s : Float, v : Float)
        var newRGB: (r : Float, g : Float, b : Float)
        var offset = 0
        for z in 0 ..< size {
            rgb[2] = Float(z) / Float(size) // blue value
            for y in 0 ..< size {
                rgb[1] = Float(y) / Float(size) // green value
                for x in 0 ..< size {
                    rgb[0] = Float(x) / Float(size) // red value
                    hsv = RGBtoHSV(rgb[0], g: rgb[1], b: rgb[2])
                    if hsv.h < minHueAngle || hsv.h > maxHueAngle {
                        newRGB.r = rgb[0]
                        newRGB.g = rgb[1]
                        newRGB.b = rgb[2]
                    } else {
                        if switchWhite.isOn {
                            hsv.s = 0
                            hsv.v = hsv.v - hueAdjustment
                        } else {
                            hsv.h = destCenterHueAngle == 1 ? 0 : hsv.h - hueAdjustment //force red if slider angle is 360
                        }
                        newRGB = HSVtoRGB(hsv.h, s:hsv.s, v:hsv.v)
                    }
                    cubeData[offset] = newRGB.r
                    cubeData[offset+1] = newRGB.g
                    cubeData[offset+2] = newRGB.b
                    cubeData[offset+3] = 1.0
                    offset += 4
                }
            }
        }
        let b = cubeData.withUnsafeBufferPointer { Data(buffer: $0) }
        let data = b as NSData
        let colorCube = CIFilter(name: "CIColorCube")!
        colorCube.setValue(size, forKey: "inputCubeDimension")
        colorCube.setValue(data, forKey: "inputCubeData")
        colorCube.setValue(ciImage, forKey: kCIInputImageKey)
        if let outImage = colorCube.outputImage {
            let context = CIContext(options: nil)
            let outputImageRef = context.createCGImage(outImage, from: outImage.extent)
            imageView.image = UIImage(cgImage: outputImageRef!)
        }
    }
    
    @IBAction func switchChanged(_ sender: AnyObject) {
        if switchWhite.isOn {
            imageViewColorBar.image = UIImage(named: "grayScale")
        } else {
            imageViewColorBar.image = UIImage(named: "hueScale")
        }
        render()
    }
    
}

