// [AUTO-PATCHED FOR SWIFT 5+]
//
//  AppDelegate.swift
//  Amplify4
//
//  Created by Bill Engels on 1/15/15.
//  Copyright (c) 2015 Bill Engels. All rights reserved.
//

import Cocoa


@main


class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var targetView: NSTextView!
    @IBOutlet weak var targDelegate: TargDelegate!
    @IBOutlet weak var targetScrollView: NSScrollView!
    @IBOutlet weak var substrateDelegate: AMsubstrateDelegate!
    
    var settings = [String: Any]()
    
    override init() {
        super.init()
        UserDefaults.standard.registerDefaults(globals.factory as [NSObject : AnyObject])
        UserDefaultsController.shared.initialValues = globals.factory as [NSObject : AnyObject]
        let docController: AnyObject = NSDocumentController.shared
        let maxdocs = docController.maximumRecentDocumentCount
        let doclist = docController.recentDocumentURLs
        let docnum = doclist.count
        if let oldDocList = UserDefaults.standard.array(forKey:globals.recentDocs) {
            for doc in (oldDocList as? [String])  {
                if let url = URL(fileURLWithPath: doc) {
                    docController.noteNewRecentDocumentURL(url)
                }
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Insert code here to initialize your application
        targetScrollView.contentView.postsBoundsChangedNotifications = true
        let settings = UserDefaults.standard
        var targetURL = URL()
        var primerURL = URL()
        if (substrateDelegate.primerFile.path == nil) && settings.bool(forKey:globals.useRecentPrimers) {
            // No primers were opened at startup and user wants to use recent file
            if let primerPath = settings.string(forKey:globals.recentPrimerPath) {
                if let primerURL = URL(fileURLWithPath: primerPath) {
                    if primerURL.checkResourceIsReachable() {
                        // There is a recent file path and it does point to an actual file
                        substrateDelegate.openURLArray([primerURL])
                    }
                }
            }
        }
        
        
        if (substrateDelegate.targetFile.path == nil) && settings.bool(forKey:globals.useRecentTarget) {
            // No target was opened at startup and user wants to use recent file
            if let targetPath = settings.string(forKey:globals.recentTargetPath) {
                if let targetURL = URL(fileURLWithPath: targetPath) {
                    if targetURL.checkResourceIsReachable() {
                        // There is a recent file path and it does point to an actual file
                        substrateDelegate.openURLArray([targetURL])
                    }
                }
            }
        }
        
        if (substrateDelegate.targetFile.path == nil) {  //  still
            if let welcomePath = NSBundle.mainBundle().pathForResource("Welcome", ofType: "rtf") {
                 let didit = targetView.readRTFDFromFile(welcomePath)
            }
        }
    }
    
     func application(sender: NSApplication, openFiles filenames: [AnyObject]) {
        var urlArray = [Any]()
        for name in filenames {
            if let furl = URL(fileURLWithPath: (name as? String)!) {
                urlArray.addObject(furl)
            }
        }
        if urlArray.count < 1 {
            sender.replyToOpenOrPrint(NSApplicationDelegateReply.Failure)
        } else {
            substrateDelegate.openURLArray(urlArray)
            sender.replyToOpenOrPrint(NSApplicationDelegateReply.Success)
        }
    }
    
    @IBAction func openBuiltinSamples(sender: AnyObject) {
        if let primerSamplePath = NSBundle.mainBundle().pathForResource(globals.samplePrimers, ofType: "primers") {
            if let targetSamplePath = NSBundle.mainBundle().pathForResource(globals.sampleTarget, ofType: "rtf") {
                let primerURL = URL(fileURLWithPath: primerSamplePath)!
                let targetURL = URL(fileURLWithPath: targetSamplePath)!
                substrateDelegate.openURLArray([primerURL, targetURL])
                // Now blank out the current file URLs so that we don't try to save into the application bundle
                substrateDelegate.primerFile = URL()
                substrateDelegate.targetFile = URL()
            }
        }
    }

    let prefsWindow = AMprefsController(windowNibName: "AMprefsController")
    let helpWindowController = AmplifyHelpController(windowNibName: "AmplifyHelp")

    @IBAction func doPrefs(sender: AnyObject) {
        prefsWindow.initialSettings = prefsWindow.currentSettings()
        prefsWindow.showWindow(self)
       let didit =  prefsWindow.windowLoaded
    }
    
    @IBAction func doHelp(sender: AnyObject) {
       helpWindowController.showWindow(self)
        let didit = helpWindowController.windowLoaded
        let helpWindow = helpWindowController.helpWindow
        helpWindow.display()
        helpWindow.makeKeyAndOrderFront(self)
        return
      }
    
    @IBAction func findMeInHelp(sender: AnyObject) {
        if let btn = sender as? NSButton, senderId = btn.identifier {
            helpWindowController.showWindow(self)
            let didit = helpWindowController.windowLoaded
            let helpWindow = helpWindowController.helpWindow
            helpWindow.display()
            helpWindow.makeKeyAndOrderFront(self)
            let nsname = senderId as NSString
            helpWindowController.scrollToString(nsname)
        }
    }
    
    func applicationWillTerminate(aNotification: Notification) {
        let docController: AnyObject = NSDocumentController.shared
        if let doclist = docController.recentDocumentURLs as? [URL] {
            var docpaths = [String]()
            for doc in doclist {
                docpaths.append(doc.path!)
            }
            UserDefaults.standard.setObject(docpaths, forKey: globals.recentDocs)
            if let ppath = substrateDelegate.primerFile.path {
                UserDefaults.standard.setObject(ppath, forKey: globals.recentPrimerPath)
            } else {
                UserDefaults.standard.removeObjectForKey(globals.recentPrimerPath)
            }
            if let tpath = substrateDelegate.targetFile.path {
                UserDefaults.standard.setObject(tpath, forKey: globals.recentTargetPath)
            } else {
                UserDefaults.standard.removeObjectForKey(globals.recentTargetPath)
            }
            UserDefaults.standard.synchronize()
        }
    }
    
    @IBAction func amplify(sender: AnyObject) {
        targDelegate.cleanupTarget()
        let newDoc: Document = NSDocumentController.shared.openUntitledDocumentAndDisplay(true, error: nil)! as! Document
    }
    
    @IBAction func amplifyCircular(sender: AnyObject) {
        let theDC: NSDocumentController = NSDocumentController.shared as! NSDocumentController
        if let newDoc: DocumentCircular = theDC.makeUntitledDocumentOfType("CircularDocumentType", error: nil)! as? DocumentCircular {
            theDC.addDocument(newDoc)
            newDoc.makeWindowControllers()
            newDoc.showWindows()
        }
    }
    
    
}
