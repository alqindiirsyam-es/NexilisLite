//
//  Whiteboard.swift
//  Nusa
//
//  Created by Rifqy Fakhrul Rijal on 21/10/19.
//  Copyright © 2019 Development. All rights reserved.
//

// Rn
// forgor ???

import Foundation
import UIKit

public class Whiteboard: WhiteboardDelegate {
    
    var roomId = ""
    var canvas : WhiteboardCanvas?
    
    public init(delegated: Bool) {
        if(!delegated){
            
        }
    }
    
    public func setRoomId(roomId: String){
        self.roomId = roomId
        canvas?.setDestination(destination: roomId)
    }
    
//    public func clearWhiteboard(){
//        removeWhiteboard(dest:destination)
//        canvas.clear()
//    }
    
    public func setPenColor(color: Int){
        let hexString = String(format: "%08X", color)
        canvas?.setLineColor(color: UIColor(hexString: hexString))
        changePenColor(dest: roomId, color: color)
    }
    
    public func setPenSize(size: Double){
        canvas?.setStrokeSize(size: size)
        changePenSize(dest: roomId, size: size)
    }
    
    public func changePeerPenColor(color: Int){
        let hexString = String(format: "%08X", color)
        canvas?.setPeerLineColor(color: UIColor(hexString: hexString))
    }
    
    public func changePeerPenSize(size: Double){
        canvas?.setPeerStrokeSize(size: size)
    }
    
    public func terminate(){
        clear()
        sendTerminate()
    }
    
    public func sendInit(destinations: String){
        canvas?.setLineColor(color: UIColor(hexString: "FF000000"))
        let me = User.getMyPin()!
        let tid = CoreMessage_TMessageUtil.getTID()
        roomId = "\(me)wbvc\(tid)"
        _ = Nexilis.writeDraw(data: "WB/0/\(roomId)/\(destinations)")
    }
    
    public func sendJoin(){
        canvas?.setLineColor(color: UIColor(hexString: "FF00FF00"))
        _ = Nexilis.writeDraw(data: "WB/22/\(roomId)")
    }
    
    public func sendTerminate(){
        _ = Nexilis.writeDraw(data: "WB/88")
    }
    
    func changePenSize(dest: String, size: Double){
//        let destId = Nusa.default.getUserId(name: dest, entity: entity!)
//        let message = Message.changeWhiteboardPenSize(originator: originId as! String, destination: String(destId), size: size)
//        App.write(message: message)
    }
    
    func changePenColor(dest: String, color: Int){
//        let destId = Nusa.default.getUserId(name: dest, entity: entity!)
//        let message = Message.changeWhiteboardPenColor(originator: originId as! String, destination: String(destId), color: color)
//        App.write(message: message)
    }
    
    public func draw(x: String, y: String, w: String, h: String, fc: String, sw: String, xo: String, yo: String, data: String) {
        //print("Draw whiteboard: "+x+","+y+","+w+","+h+","+fc+","+sw+","+xo+","+yo)
        canvas?.incomingData(x: x,y: y,w: w,h: h,fc: fc,sw: sw,xo: xo,yo: yo)
    }
    
    public func sendClear(){
        let ms = Date().currentTimeMillis()
        _ = Nexilis.writeDraw(data: "WB/3/\(ms)")
    }
    
    public func clear() {
        //print("Clear whiteboard")
        DispatchQueue.main.async {
            self.canvas?.clear()
        }
    }
    
}
