//
//  CustomSegue.swift
//  forReading
//
//  Created by kashiwa-gohan on 2021/12/18.
//

import Cocoa
import OSLog

class CustomSegue: NSStoryboardSegue {
    
    static let osLog = OSLog(subsystem: "for", category: "CustomSegue")
    
    override func perform() {
        //ViewControllerの親子関係を設定する
        //親：parentViewController --- 子：sourceViewController
        guard
            let source = self.sourceController as? NSViewController,
            let destination = self.destinationController as? NSViewController,
            let parent = source.parent
            else {
                os_log(.error, log: CustomSegue.osLog, "ViewControllerの親子関係の設定に失敗しました")
                return
        }

        //遷移先のViewControllerの親を設定する
        if (!parent.children.contains(destination)) {
            parent.addChild(destination)
        }

        //遷移アニメーションを設定する
        NSAnimationContext.runAnimationGroup(
            { context in
            context.duration = 1.0
            
            var frame = source.view.frame
            frame.origin.x = frame.size.width
            destination.view.frame = frame
            //表示されているViewのsuperViewに遷移先の画面を追加する
            source.view.superview?.addSubview(destination.view)
            
            var newSFrame = source.view.frame
            newSFrame.origin.x = newSFrame.size.width
            
            let newDFrame = source.view.frame

            source.view.animator().frame = newSFrame
            destination.view.animator().frame = newDFrame
        }, completionHandler: {
            //表示されているViewをsuperViewから切り離す
            source.view.removeFromSuperview()
        })
    }
}
