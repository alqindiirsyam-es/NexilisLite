//
//  WhiteboardCanvas.swift
//  Nusa
//
//  Created by Rifqy Fakhrul Rijal on 21/10/19.
//  Copyright © 2019 Development. All rights reserved.
//

import Foundation
import UIKit

// Rn
// linecolor red peerlinecolor blue

extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hexString: String = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:alpha)
    }
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"#%06x", rgb)
    }
}

public class WhiteboardCanvas: UIView {
    
    var destination: String?
    
    var lineColor:UIColor = UIColor.red
    var lineWidth:CGFloat!
    var peerLineColor:UIColor = UIColor.blue
    var peerLineWidth:CGFloat!
    var path:UIBezierPath!
    var touchPoint:CGPoint!
    var startingPoint:CGPoint!
    let fRThreshold:CGFloat = 4.0;
    var eraseModeOn:Bool = false;
    
    var nWidth:CGFloat!
    var nHeight:CGFloat!
    
    var onDrawing : ((CGFloat, CGFloat, CGFloat, CGFloat, String, CGFloat, CGFloat, CGFloat) -> Void)?
    var onClearing : (() -> Void)?
    
    func listen(onDraw:@escaping ((CGFloat, CGFloat, CGFloat, CGFloat, String, CGFloat, CGFloat, CGFloat) -> Void), onClear:@escaping (() -> Void)) -> Void {
        onDrawing  = onDraw
        onClearing = onClear
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.clipsToBounds = true
        self.isMultipleTouchEnabled = false
        
        nWidth  = self.frame.size.width
        nHeight = self.frame.size.height
        
        lineWidth = 2
        
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.backgroundColor = UIColor.white.cgColor
        
        
        let margin_left = CGFloat(0.07) * UIScreen.main.bounds.width
        let margin_top  = CGFloat(0.1) * UIScreen.main.bounds.height
        let margin_bottom  = CGFloat(0.25) * UIScreen.main.bounds.height

        let width  = UIScreen.main.bounds.width - CGFloat(margin_left) - CGFloat(margin_left)
        let height = UIScreen.main.bounds.height - margin_top - margin_bottom

        self.frame = CGRect(x: margin_left, y: margin_top, width: width, height: height)
//
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        startingPoint = touch?.location(in: self)
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        touchPoint = touch?.location(in: self)
        
        let dx = abs(touchPoint.x - startingPoint.x)
        let dy = abs(touchPoint.x - startingPoint.x)
        if (dx >= fRThreshold || dy >= fRThreshold) {
            let onGoingCC: String = SecureUserDefaults.shared.value(forKey: "onGoingCC") ?? ""
            if !onGoingCC.isEmpty {
                var colorDraw = UIColor.red
                let requester = onGoingCC.components(separatedBy: ",")[0]
                let idMe = User.getMyPin()!
                if requester == idMe {
                    colorDraw = UIColor.blue
                }
                onDrawing?(touchPoint.x, touchPoint.y, nWidth, nHeight, colorDraw.toHexString(), lineWidth, startingPoint.x, startingPoint.y)

                self.drawWhiteboard(destination: destination ?? "", x: toString(from: touchPoint.x), y: toString(from: touchPoint.y), w: toString(from: nWidth), h: toString(from: nHeight), fc: colorDraw.toHexString(),
                               sw: toString(from: lineWidth), xo: toString(from: startingPoint.x), yo: toString(from: startingPoint.y))
                
                path = UIBezierPath()
                path.move(to: startingPoint)
                path.addLine(to: touchPoint)
                startingPoint = touchPoint
                drawShapeLayer(color: colorDraw)
            } else {
                let dataWB: String! = SecureUserDefaults.shared.value(forKey: "wb_vc")
                //print("DATA WB \(dataWB)")
                var colorDraw = UIColor.red
                let requester = dataWB.components(separatedBy: ",")[0]
                let idMe = User.getMyPin()!
                if requester == idMe {
                    colorDraw = UIColor.blue
                }
                onDrawing?(touchPoint.x, touchPoint.y, nWidth, nHeight, colorDraw.toHexString(), lineWidth, startingPoint.x, startingPoint.y)

                self.drawWhiteboard(destination: destination ?? "", x: toString(from: touchPoint.x), y: toString(from: touchPoint.y), w: toString(from: nWidth), h: toString(from: nHeight), fc: colorDraw.toHexString(),
                               sw: toString(from: lineWidth), xo: toString(from: startingPoint.x), yo: toString(from: startingPoint.y))
                
                path = UIBezierPath()
                path.move(to: startingPoint)
                path.addLine(to: touchPoint)
                startingPoint = touchPoint
                drawShapeLayer(color: colorDraw)
            }
        }
        
    }
    
    func drawShapeLayer(color: UIColor = UIColor.red) {
        let shapelayer = CAShapeLayer()
        shapelayer.path = path.cgPath
        shapelayer.strokeColor = color.cgColor
        shapelayer.lineWidth = lineWidth
        shapelayer.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(shapelayer)
        self.setNeedsDisplay()
    }
    
    func clear() -> Void {
        self.layer.sublayers = nil
        self.setNeedsDisplay()
        onClearing?()
    }
    
    func incomingDraw(x:CGFloat, y:CGFloat, w:CGFloat, h:CGFloat, fc:String, sw:CGFloat, xo:CGFloat, yo:CGFloat) {
        //print("DRAWING >> x:\(x) y:\(y) w:\(w) h:\(h) fc:\(fc) sw:\(sw) xo:\(xo) yo:\(yo)")
        
        let xoScaled = nWidth / w * xo;
        let yoScaled = nHeight / h * yo;
        let xScaled = nWidth / w * x;
        let yScaled = nHeight / h * y;
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: xoScaled, y: yoScaled))
        path.addLine(to: CGPoint(x: xScaled, y: yScaled))
        
        let line = CAShapeLayer()
        line.path = path.cgPath
        line.strokeColor = UIColor(hexString: fc).cgColor
        line.lineWidth = sw
        line.fillColor = UIColor(hexString: fc).cgColor
        self.layer.addSublayer(line)
        self.setNeedsDisplay()
    }
    
    func incomingData(x: String, y: String, w: String, h: String, fc: String, sw: String, xo: String, yo: String) {
        DispatchQueue.main.async {
            self.incomingDraw(x: self.toCGFloat(from: x),
                              y: self.toCGFloat(from: y),
                              w: self.toCGFloat(from: w),
                              h: self.toCGFloat(from: h),
                              fc: fc,
                              sw: self.toCGFloat(from: sw),
                              xo: self.toCGFloat(from: xo),
                              yo: self.toCGFloat(from: yo))
        }
    }
    
    func toCGFloat(from:String!) -> CGFloat {
        if let n = Double(from) {
            return CGFloat(n)
        }
        return CGFloat(0)
    }
    
    func toString(from:CGFloat!) -> String {
        return from.description
    }
    
    func setDestination(destination: String) {
        self.destination = destination
    }
    
    public func setBackground(color:UIColor){
        backgroundColor = color
    }
    
    public func setStrokeSize(size: Double){
        lineWidth = CGFloat(size)
    }
    
    public func setLineColor(color:UIColor) {
        lineColor = color
    }
    
    public func setPeerStrokeSize(size: Double){
        peerLineWidth = CGFloat(size)
    }
    
    public func setPeerLineColor(color:UIColor){
        peerLineColor = color
    }
    
    public func resetLineColor() {
        lineColor = UIColor.gray
    }
    
    func drawWhiteboard(destination: String, x: String, y: String, w: String, h: String, fc: String, sw: String, xo: String, yo: String){
        //print("DRAW HMM \(destination)")
        _ = Nexilis.writeDraw(data: "WB/1/\(x)/\(y)/\(w)/\(h)/\(fc)/\(sw)/\(xo)/\(yo)")
    }
    
}
