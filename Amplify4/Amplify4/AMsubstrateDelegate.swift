// [AUTO-PATCHED FOR SWIFT 5+]
//
//  AMsubstrateDelegate.swift
//  Amplify4
//
//  Created by Bill Engels on 1/21/15.
//  Copyright (c) 2015 Bill Engels. All rights reserved.
//

import Cocoa

class AMsubstrateDelegate: NSObject, NSTableViewDataSource,NSTableViewDelegate {

    var targetFont = "Menlo"
    var endHeader = "End Header"
    var targetFontSize = 12.0
    var primersChanged = false
    var targetChanged = false
    var primerFile = URL()
    var targetFile = URL()
    var primers = [Primer]()
    let settings = UserDefaults.standard

    
    @IBOutlet weak var targetScrollView: NSScrollView!
    @IBOutlet weak var primerTableView: NSTableView!
    @IBOutlet var targetView: NSTextView!
    @IBOutlet weak var targetDelegate: TargDelegate!
    @IBOutlet weak var appdel: AppDelegate!
    @IBOutlet weak var substrateWindow: NSWindow!
    @IBOutlet var primerInfoView: NSTextView!
    @IBOutlet weak var printOutputMenuItem: NSMenuItem!
    
    override init() {
        super.init()
    }
    
    func tableViewSelectionDidChange(aNotification: Notification) {
        let selection = primerTableView.selectedRowIndexes.firstIndex
        self.showInfoForPrimer(selection)
    }
    
    func showInfoForPrimer(k : Int) {
        if (k < 0) || (k >= primers.count) {return}
        let sto = primerInfoView.textStorage!
        sto.setAttributedString(primers[k].info())
    }
    
    let searchWindow = SearchPrimers(windowNibName: "SearchPrimers")
    
    func performFindPanelAction(sender : AnyObject) -> AnyObject {
        searchWindow.showWindow(self)
        return self
    }
    
    func copy(sender : AnyObject) -> AnyObject {
        let first = substrateWindow.firstResponder
        var a = 0
        if first  == primerTableView {
            let selection = primerTableView.selectedRowIndexes
            if selection.count < 1 {return self}
            var clip = NSPasteboard.generalPasteboard()
            clip.declareTypes([NSPasteboardTypeString], owner: nil);
            var srow = selection.firstIndex
            var s = primers[srow].line
            srow = selection.indexGreaterThanIndex(srow)
            while srow != NSNotFound {
                s += "\r" + primers[srow].line
                srow = selection.indexGreaterThanIndex(srow)
            }
            let didit = clip.setString(s, forType: NSPasteboardTypeString)
        }
        return self
    }
    
    @IBAction func copyNameFirst(sender: AnyObject) {
        if substrateWindow.firstResponder == primerTableView {
            let selection = primerTableView.selectedRowIndexes
            if selection.count < 1 {return}
            var clip = NSPasteboard.generalPasteboard()
            clip.declareTypes([NSPasteboardTypeString], owner: nil);
            var srow = selection.firstIndex
            var s = primers[srow].nameFirstLine
            srow = selection.indexGreaterThanIndex(srow)
            while srow != NSNotFound {
                s += "\r" + primers[srow].nameFirstLine
                srow = selection.indexGreaterThanIndex(srow)
            }
            let didit = clip.setString(s, forType: NSPasteboardTypeString)
        }
    }
    
    func delete(sender : AnyObject) -> AnyObject {
        let fid = (substrateWindow.firstResponder as! NSView).identifier
        if fid == "primer Table View" {
            self.deletePrimers(sender);
        }
        return self
    }
    
    func cut(sender : AnyObject) -> AnyObject {
        let fid = substrateWindow.firstResponder
        if fid == primerTableView {
            self.copy(sender)
            self.deleteSelectedPrimers()
            primerTableView.reloadData()
            primerTableView.deselectAll(self)
        }
        return self
    }
    
    @IBOutlet weak var saveItem: NSMenuItem!
    @IBOutlet weak var saveAsItem: NSMenuItem!
    @IBOutlet weak var copyRearrangedItem: NSMenuItem!
    @IBOutlet weak var copyItem: NSMenuItem!
    @IBOutlet weak var findItem: NSMenuItem!
    
    @IBOutlet weak var printItem: NSMenuItem!
    @IBOutlet weak var plainFindItem: NSMenuItem!
    
override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
    
    if menuItem == printOutputMenuItem {printOutputMenuItem.hidden = true}

    let fid = substrateWindow.firstResponder
    if fid == primerTableView {
        if menuItem == printItem {
            printItem.title = "Print Primer List …"
        }
        if menuItem == findItem {
            findItem.title = "Find Primers …"
            findItem.enabled = true
        }
        if menuItem == plainFindItem {
            menuItem.title = "Find Primers …"
            plainFindItem.enabled = true
        }
        if menuItem == saveItem {
            saveItem.title = "Save Primers"
            saveAsItem.title = "Save Primers As…"
            if primerFile.path == nil {return false}
            return primersChanged
        }
        copyRearrangedItem.hidden = false
    } else if fid == targetView {
        if menuItem == printItem {
            printItem.title = "Print Target Sequence …"
        }
        if menuItem == saveItem {
            saveItem.title = "Save Target"
            saveAsItem.title = "Save Target As…"
            if targetFile.path == nil {return false}
            return targetChanged
        }
        copyRearrangedItem.hidden = true
    }
        return true // super.validateMenuItem(menuItem)
}
    
    func printDocument(sender: AnyObject) {
        let fid = substrateWindow.firstResponder
        if fid == targetView {
            let printOp = NSPrintOperation(view: targetView)
            printOp.runOperation()
        }
        if fid == primerTableView {
            let printOp = NSPrintOperation(view: primerTableView)
            printOp.runOperation()
        }
    }
    
    func paste(sender : AnyObject) -> AnyObject {
        let fid = substrateWindow.firstResponder

        if fid == primerTableView {
            var clip = NSPasteboard.generalPasteboard()
 //           clip.addTypes([NSPasteboardTypeString], owner: nil)
            let newline = NSCharacterSet(charactersInString: "\n\r")
            let selection = primerTableView.selectedRowIndexes
            var srow = -1
            if selection.count > 0 {
                srow = selection.lastIndex
            }
            if let lines = clip.stringForType(NSPasteboardTypeString)?.componentsSeparatedByCharactersInSet(newline) {
                for line in lines {
                    primers.insert(Primer(theLine: line), atIndex: ++srow)
                }
            }
            primerTableView.reloadData()  // must reload before selecting or scrolling
            primerTableView.selectRowIndexes(NSIndexSet(index: srow), byExtendingSelection: false)
            primerTableView.scrollRowToVisible(srow)
            primersChanged = true
        }
        return self
    }
    
    // code for enumerator from:
    // https://github.com/mattneub/Programming-iOS-Book-Examples/blob/master/bk2ch10p503attributedString/ch23p771attributedStringInLabel/ViewController.swift
    
    func changeFamilyOrSizeOnly(#content: NSMutableAttributedString, ffamily: String, fsize: Double) {
        let fontManager = NSFontManager.sharedFontManager()
        let opts: NSAttributedStringEnumerationOptions = .LongestEffectiveRangeNotRequired
        content.enumerateAttribute(NSFontAttributeName,
            inRange:NSMakeRange(0,content.length),
            options:opts,
            usingBlock: {
                (value:AnyObject!, range:NSRange, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
                let font = value as! NSFont
                var newsize = CGFloat(fsize)
                if newsize < 1 {newsize = font.pointSize}
                let fontF = fontManager.convertFont(font, toFamily: ffamily)
                let fontFS = fontManager.convertFont(fontF, toSize: CGFloat(newsize))
                content.addAttribute(NSFontAttributeName,
                    value:fontFS,
                    range:range)
        })
        targetDelegate.setBaseNumbers(self)
    }
    
    @IBAction func setTargFont(sender: AnyObject) {
        let butt = sender as! NSPopUpButton
        let ffam = butt.selectedItem!.title
        targetFont = ffam
        settings.setObject(ffam, forKey: globals.targetFont)
        changeFamilyOrSizeOnly(content: targetView.textStorage!, ffamily: ffam, fsize: -1)
    }
    

    @IBAction func setTargSize(sender: AnyObject) {
        
        let ddict: NSDictionary = settings.dictionaryRepresentation()
        let dkeys = ddict.allKeys
        let x = settings.doubleForKey(globals.targetSize)
        let fontSize =  CGFloat(settings.doubleForKey(globals.targetSize))
        let fontn = settings.string(forKey:globals.targetFont)!
        let endh = settings.string(forKey:globals.endHeader)!
        
        let butt = sender as! NSPopUpButton
        let ssize = butt.selectedItem!.title as NSString
        targetFontSize = ssize.doubleValue
        settings.setInteger(ssize.integerValue, forKey: globals.targetSize)
        changeFamilyOrSizeOnly(content: targetView.textStorage!, ffamily: "", fsize: targetFontSize)
    }
    
    
    @IBAction func openTargetFromWindow(sender: AnyObject) {
        self.openTargetString(sender)
    }
    
    func primerFileQ(url : URL) -> Bool {
        // Determine whether a file is more likely to be a primer or target file.
        // If the extension is "primers" then it's a primer file
        // If it's formatted text (.rtf or .rtfd) then it's target
        // Otherwise, consider it target if there are fewer than 1 tabs per line
        var primerQ = true
        let tabsPerLineInPrimerFile = 1.0
        let ext = url.pathExtension!
        switch ext {
        case "primers", "pri", "csv", "CSV" : primerQ = true
        case "rtf", "rtfd" : primerQ = false
        default : // Ambiguous
            let utext = NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding, error: nil)!
            let tabcount = Double(utext.componentsSeparatedByString("\t").count)
            let lineChars = NSCharacterSet(charactersInString: "\n\r")
            let linecount = Double(utext.componentsSeparatedByCharactersInSet(lineChars).count)
            let charcount = Double(utext.length)
            let tabsperline: Double = tabcount / linecount
            let tabrunsize: Double = charcount / tabcount
            if tabsperline < tabsPerLineInPrimerFile {primerQ = false}
        }
        return primerQ
    }
    
    func getTargetFromURL(url : URL) -> Bool {
        let didit = targetView.readRTFDFromFile(url.path!)
        if didit {
            var tstorage = targetView.textStorage!
            changeFamilyOrSizeOnly(content: tstorage, ffamily:settings.string(forKey:globals.targetFont)!, fsize: settings.doubleForKey(globals.targetSize))
            targetDelegate.targetNeedsCleaning = true
            targetChanged = false
            targetDelegate.cleanupTarget()
            targetFile = url
//            settings.setObject(targetFile.path, forKey: globals.recentTargetPath)
            let theDocController: AnyObject = NSDocumentController.shared
            theDocController.noteNewRecentDocumentURL(url)
            substrateWindow.title = targetFile.path!.lastPathComponent
        }
        return didit
    }
   
    func getPrimersFromURL(url : URL) {
        primerFile = url
        let urlext = url.pathExtension! as String
        let inputString = NSString(contentsOfURL: primerFile, encoding: NSUTF8StringEncoding, error: nil)
        if (inputString == nil) {return}
        let newline = NSCharacterSet(charactersInString: "\n\r")
        let lines = inputString!.componentsSeparatedByCharactersInSet(newline) as? [String]
        primers = []
        for line in lines {
            if count(line) > 1 {
                // ignore blank lines
                switch urlext {
                case "csv", "CSV" :
                    primers.append(Primer(theCSVLine: line))
                default :
                    primers.append(Primer(theLine: line))
                }
            }
        }
        primersChanged = false
        primerTableView.reloadData()
        let theDocController: AnyObject = NSDocumentController.shared
        theDocController.noteNewRecentDocumentURL(url)
//        settings.setObject(primerFile.path, forKey: globals.recentPrimerPath)
    }
    
    func openURLArray(urls : [Any]) {
        var needPrimers = true
        var needTarget = true
        for url in urls {
            if primerFileQ(url as! URL) {
                if needPrimers {
                    getPrimersFromURL(url as! URL)
                    needPrimers = false
                }
            } else {
                if needTarget {
                    getTargetFromURL(url as! URL)
                    needTarget = false
                }
            }
        }
    }
    
    @IBOutlet weak var whatToOpen: NSMatrix!
    @IBAction func openTargetString(sender: AnyObject) {
        var openPanel = NSOpenPanel()
        openPanel.message = "Open file for target sequence or primers (or both)"
        openPanel.allowedFileTypes = ["rtf", "txt", "", "rtfd", "primers", "pri", "csv", "CSV", "SEQ"]
        openPanel.allowsOtherFileTypes = true
        openPanel.allowsMultipleSelection = true
        openPanel.accessoryView = whatToOpen
        whatToOpen.selectCellAtRow(0, column: 0)
        if openPanel.runModal() == NSCancelButton {return}
        let what = whatToOpen.selectedRow
            switch what {
            case 0:
                openURLArray(openPanel.URLs)
            case 1:   // User chose Primer List Only. Only look at first URL
                getPrimersFromURL(openPanel.URL!)
            default :    // User chose Target Sequence Only
                getTargetFromURL(openPanel.URL!)
            }
    }
    
    
    
    @IBOutlet weak var formattedOrPlain: NSMatrix!
    @IBAction func saveTargetStringAs(sender: AnyObject) {
        var savePanel = NSSavePanel()
        savePanel.message = "Save target sequence as ..."
        savePanel.allowedFileTypes = ["rtf", "txt", ""]
        savePanel.accessoryView = formattedOrPlain
        if savePanel.runModal() == NSCancelButton {return}
        var targetURL = savePanel.URL! as URL
        var didit = false
        switch formattedOrPlain.selectedRow {
        case 0:
            didit = targetView.RTFFromRange(NSMakeRange(0, (targetView.textStorage?.length)!))!.writeToURL(targetURL, atomically: true)
        default:
            targetURL = targetURL.URLByDeletingPathExtension!.URLByAppendingPathExtension("txt")
            didit = (targetView.string! as NSString).writeToURL(targetURL, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        }
        if didit {
            targetFile = savePanel.URL! as URL
            targetChanged = false
        }
    }
    
    @IBAction func saveTargetString(sender: AnyObject) {
        let didit = targetView.RTFFromRange(NSMakeRange(0, (targetView.textStorage?.length)!))!.writeToURL(targetFile, atomically: true)
        if didit {
            targetChanged = false
        }
    }
    
    func saveDocumentAs(sender: AnyObject) -> AnyObject {
        let fid = substrateWindow.firstResponder
        if fid == primerTableView {
            if primers.count < 1 {return self}
            self.savePrimersAs(sender)
        } else if fid == targetView {
            self.saveTargetStringAs(sender)
        }
        return self
     }
    
    func saveDocument(sender: AnyObject) -> AnyObject {
        let fid = (substrateWindow.firstResponder as! NSView).identifier as String!
        switch fid {
        case "primer Table View":
            if let primerPath = primerFile.path {
                self.savePrimers()
            }
        case "target Text View" :
            if let targetPath = targetFile.path {
                self.saveTargetString(sender)
            }
        default:
            let a = "There is nothing to save"
        }
    return self

    }

    func allPrimerString(tab : Bool = true) -> String {
        var s = ""
        if primers.count < 1 {return s}
        if tab {
            s = primers[0].line
            for k in 1..<primers.count {
                s += "\n" + primers[k].line
            }
        }else {
            s = primers[0].csvline
            for k in 1..<primers.count {
                s +=  "\n" + primers[k].csvline
            }
        }
        return s
    }
    
    @IBAction func savePrimersAs(sender: AnyObject) {
        var savePanel = NSSavePanel()
        savePanel.title = "Save primer list in new file"
        savePanel.allowedFileTypes = ["primers", "pri", "txt","", "csv"]
        savePanel.message = "Save all primers in file"
        if savePanel.runModal() == NSCancelButton {return}
        if savePanel.URL == nil {return}
        if let theURL = savePanel.URL {
            let urlext = theURL.pathExtension
            let primerString = allPrimerString(tab: urlext != "csv")
            primerString.writeToURL(theURL, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
            primersChanged = false
            primerFile = theURL
        }
    }
    
    func savePrimers() {
        if let urlext = primerFile.pathExtension {
            let primerString = allPrimerString(tab: urlext != "csv")
            let didit = primerString.writeToURL(primerFile, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
            if didit {
                primersChanged = false
            }
        }
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        return primers.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?
    {
        if ((tableColumn!.identifier as String) == "C")
        {
            return primers[row].check
        }
        else if ((tableColumn!.identifier) == "Sequence")
        {
            return primers[row].seq
        } else if (tableColumn!.identifier == "Name") {
            return primers[row].name
        } else {
            return primers[row].note
        }
    }
    
    @IBAction func checkAll(sender: AnyObject) {
        if primers.count < 1 {return}
        for i in 0...primers.count - 1 {
            primers[i].check = 1
        }
        primerTableView.reloadData()
    }
    
    @IBAction func uncheckAll(sender: AnyObject) {
        if primers.count < 1 {return}
        for i in 0...primers.count - 1 {
            primers[i].check = 0
        }
        primerTableView.reloadData()
    }
    
    @IBAction func toggleAll(sender: AnyObject) {
        if primers.count < 1 {return}
        for i in 0...primers.count - 1 {
            primers[i].check = 1 - primers[i].check
        }
        primerTableView.reloadData()
    }
    
    
    
    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int)
    {
        if(tableColumn?.identifier == "C") {
            primers[row].check = 1 - primers[row].check
        } else {
            primersChanged = true
        }
        if tableColumn?.identifier == "Sequence" {
            primers[row].seq = object as! String
        } else if tableColumn?.identifier == "Name" {
            primers[row].name = object as! String
        } else if tableColumn?.identifier == "Notes" {
            primers[row].note = object as! String
        }
        showInfoForPrimer(row)
        primersChanged = true
    }
    
    @IBAction func toggleSelected(sender: AnyObject) {
        if primers.count < 1 {return}
        let selection = primerTableView.selectedRowIndexes
        var srow = selection.firstIndex
        while srow != NSNotFound {
            primers[srow].check = 1-primers[srow].check
            srow = selection.indexGreaterThanIndex(srow)
        }
        primerTableView.reloadData()
    }
    
    @IBAction func uncheckSelected(sender: AnyObject) {
        if primers.count < 1 {return}
        let selection = primerTableView.selectedRowIndexes
        var srow = selection.firstIndex
        while srow != NSNotFound {
            primers[srow].check = 0
            srow = selection.indexGreaterThanIndex(srow)
        }
        primerTableView.reloadData()
    }
    
    @IBAction func checkSelected(sender: AnyObject) {
        if primers.count < 1 {return}
        let selection = primerTableView.selectedRowIndexes
        var srow = selection.firstIndex
        while srow != NSNotFound {
            primers[srow].check = 1
            srow = selection.indexGreaterThanIndex(srow)
        }
        primerTableView.reloadData()
    }
    
    @IBAction func selectNone(sender: AnyObject) {
        primerTableView.deselectAll(self)
    }
    
    @IBAction func newPrimer(sender: AnyObject) {
        var row = primerTableView.selectedRowIndexes.firstIndex
        if row > primers.count {row = 0}
        primers.insert(Primer(), atIndex: row)
        primerTableView.reloadData()
//        primerTableView.scrollToEndOfDocument(self)
        let newIndex = NSIndexSet(index: row)
        primerTableView.selectRowIndexes(newIndex, byExtendingSelection: false)
        showInfoForPrimer(row)
        primersChanged = true
    }

    func deleteSelectedPrimers() {
        // without asking are you sure
        if primers.count < 1 {return}
        let selection = primerTableView.selectedRowIndexes
        if selection.count < 1 {return}
        var srow = selection.lastIndex
        while srow != NSNotFound {
            primers.removeAtIndex(srow)
            srow = selection.indexLessThanIndex(srow)
        }
        primersChanged = true
    }
    
    @IBAction func deletePrimers(sender: AnyObject) {
        if primers.count < 1 {return}
        let ruSure = NSAlert()
        ruSure.addButtonWithTitle("Okay")
        ruSure.addButtonWithTitle("Cancel")
        let selection = primerTableView.selectedRowIndexes
        if selection.count > 0 {
            if selection.count == 1 {
                ruSure.messageText = "Are you sure you want to remove this primer?"
            } else {
                ruSure.messageText = "Are you sure you want to remove \(selection.count) primers?"
            }
            let code = ruSure.runModal()
            if code == NSAlertFirstButtonReturn {
                self.deleteSelectedPrimers();
                primerTableView.reloadData()
                primerTableView.deselectAll(self)
            }
        }
    }
 
    func iubComp(c : String) -> String {
        switch c {
        case "A": return "T"
        case "C": return "G"
        case "T":  return "A"
        case "G": return "C"
        case "Y": return "R"
        case "R": return "Y"
        case "W": return "W"
        case "S": return "S"
        case "K": return "M"
        case "M": return "K"
        case "D": return "H"
        case "V": return "B"
        case "H": return "D"
        case "B": return "V"
        case "N": return "N"
        case "a": return "t"
        case "c": return "g"
        case "t":  return "a"
        case "g": return "c"
        case "y": return "r"
        case "r": return "y"
        case "w": return "w"
        case "s": return "s"
        case "k": return "m"
        case "m": return "k"
        case "d": return "h"
        case "v": return "b"
        case "h": return "d"
        case "b": return "v"
        case "n": return "n"
        default : return "N"
        }
    }

    @IBAction func flipPrimers(sender: AnyObject) {
        if primers.count < 1 {return}
        let selection = primerTableView.selectedRowIndexes
        if selection.count < 1 {return}
        var srow = selection.firstIndex
        var flip = ""
        while srow != NSNotFound {
            flip = ""
            for c in (primers[srow].seq as String) {
                flip = iubComp(String(c)) + flip
            }
            primers[srow].seq = flip
            srow = selection.indexGreaterThanIndex(srow)
        }
        showInfoForPrimer(selection.firstIndex)
        primerTableView.reloadData()
        primersChanged = true
    }
    
}
