//
//  ViewController.swift
//  ReplaceColor
//
//  Created by Travis Ma on 9/9/15.
//  Copyright (c) 2015 IMSHealth. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelHue: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var switchWhite: UISwitch!
    var ciImage: CIImage?
    var isWhite = false

    override func viewDidLoad() {
        super.viewDidLoad()
        ciImage = CIImage(image: imageView.image!)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        labelHue.text = NSString(format:"%.2lf", slider.value) as String
        render()
    }
    
    func HSVtoRGB(h : Float, s : Float, v : Float) -> (r : Float, g : Float, b : Float) {
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

    
    func RGBtoHSV(r : Float, g : Float, b : Float) -> (h : Float, s : Float, v : Float) {
        var h : CGFloat = 0
        var s : CGFloat = 0
        var v : CGFloat = 0
        let col = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
        col.getHue(&h, saturation: &s, brightness: &v, alpha: nil)
        h = fmod(h, 1.0)
        return (Float(h), Float(s), Float(v))
    }
    
//old function
//    func RGBtoHSV(r : Float, g : Float, b : Float) -> (h : Float, s : Float, v : Float) {
//        var h : Float = 0
//        var s : Float = 0
//        var v : Float = 0
//        let minN = min(r, min(g, b))
//        let maxN = max(r, max(g, b))
//        v = maxN
//        let delta = maxN - minN
//        if (maxN == 0) {
//            s = 0
//            h = -1
//        } else {
//            s = delta / maxN
//            if r == maxN {
//                h = (g - b) / delta         // between yellow & magenta
//            } else if g == maxN {
//                h = 2 + (b - r) / delta     // between cyan & yellow
//            } else {
//                h = 4 + (r - g) / delta     // between magenta & cyan
//            }
//            h *= 60                         // degrees
//            if h < 0 {
//                h += 360
//            }
//            h /= 360.0
//        }
//        return (h, s, v)
//    }
    
    @IBAction func sliderChanged(sender: AnyObject) {
        labelHue.text = NSString(format:"%.2lf", slider.value) as String
        render()
    }
    
    func render() {
        let centerHueAngle: Float = 214.0/360.0 //default color of truck body blue
        let destCenterHueAngle: Float = slider.value
        let minHueAngle: Float = (214.0 - 60.0/2.0) / 360 //60 degree range = +30 -30
        let maxHueAngle: Float = (214.0 + 60.0/2.0) / 360
        var hueAdjustment = centerHueAngle - destCenterHueAngle
        if destCenterHueAngle == 0 {
            hueAdjustment = 1 //force black if slider angle is 0
        }
        let size = 64
        var cubeData = [Float](count: size * size * size * 4, repeatedValue: 0)
        var rgb: [Float] = [0, 0, 0]
        var hsv: (h : Float, s : Float, v : Float)
        var newRGB: (r : Float, g : Float, b : Float)
        var offset = 0
        for var z = 0; z < size; z++ {
            rgb[2] = Float(z) / Float(size) // blue value
            for var y = 0; y < size; y++ {
                rgb[1] = Float(y) / Float(size) // green value
                for var x = 0; x < size; x++ {
                    rgb[0] = Float(x) / Float(size) // red value
                    hsv = RGBtoHSV(rgb[0], g: rgb[1], b: rgb[2])
                    if isWhite {
                        let alpha: Float = (hsv.h > minHueAngle && hsv.h < maxHueAngle) ? 0.2 : 1.0
                        cubeData[offset]   = rgb[0] * alpha
                        cubeData[offset+1] = rgb[1] * alpha
                        cubeData[offset+2] = rgb[2] * alpha
                        cubeData[offset+3] = alpha
                    } else {
                        //print("RGB \(rgb[0]) \(rgb[1]) \(rgb[2]) HSV \(hsv.h) \(hsv.s) \(hsv.v)")
                        if hsv.h < minHueAngle || hsv.h > maxHueAngle {
                            newRGB.r = rgb[0]
                            newRGB.g = rgb[1]
                            newRGB.b = rgb[2]
                        } else {
                            hsv.h = destCenterHueAngle == 1 ? 0 : hsv.h - hueAdjustment //force red if slider angle is 360
                            newRGB = HSVtoRGB(hsv.h, s:hsv.s, v:hsv.v)
                        }
                        cubeData[offset]   = newRGB.r
                        cubeData[offset+1] = newRGB.g
                        cubeData[offset+2] = newRGB.b
                        cubeData[offset+3] = 1.0
                    }
                    offset += 4
                }
            }
        }
        let data = NSData(bytes: cubeData, length: cubeData.count * sizeof(Float))
        let colorCube = CIFilter(name: "CIColorCube")!
        colorCube.setValue(size, forKey: "inputCubeDimension")
        colorCube.setValue(data, forKey: "inputCubeData")
        colorCube.setValue(ciImage, forKey: kCIInputImageKey)
        if let outImage = colorCube.outputImage {
            let context = CIContext(options: nil)
            let outputImageRef = context.createCGImage(outImage, fromRect: outImage.extent)
            imageView.image = UIImage(CGImage: outputImageRef)
        }
    }
    
    @IBAction func switchChanged(sender: AnyObject) {
        switchWhite.on = !isWhite
        isWhite = !isWhite
        render()
    }

}
