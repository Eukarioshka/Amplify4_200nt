// [AUTO-PATCHED FOR SWIFT 5+]
//
//  Match.swift
//  Amplify4
//
//  Created by Bill Engels on 3/2/15.
//  Copyright (c) 2015 Bill Engels. All rights reserved.
//

import Cocoa

class Match: MapItem {
    let isD: Bool  // Does match point rightward?
    let threePrime: Int  // 3' end in target coordinates
    let primability, stability : Int
    let primer: Primer
    let bezFillColor, bezStrokeColor : NSColor
    let bez: NSBezierPath
    let isCircular: Bool // need to know how to handle straddling matches
    
    init(primer: Primer, isD : Bool, threePrime : Int, primability : Int, stability : Int, isCircular : Bool) {
        self.primer = primer
        self.isD = isD
        self.threePrime = threePrime
        self.primability = primability
        self.stability = stability
        self.isCircular = isCircular
        let hsize: CGFloat = 10
        let vsize: CGFloat = 14
        let linewidth: CGFloat = 1
        let minScale: CGFloat = 0.5
        let arrowAlpha: CGFloat = 0.7
        let colorLightness: CGFloat = 0.7
        bez = NSBezierPath()

        bez.moveToPoint(NSPoint(x:0,y:0))
        if isD {
            bezFillColor = NSColor(red: 0, green: 0, blue: colorLightness, alpha:arrowAlpha)
            bezStrokeColor = NSColor.blackColor()
        } else {
            bezFillColor = NSColor(red: colorLightness, green: 0, blue: 0, alpha: arrowAlpha)
            bezStrokeColor = NSColor.blackColor()
        }
        super.init()

        var qualityScale = NSAffineTransform()
        let scaleFactor = minScale + self.quality() * minScale
        qualityScale.scaleBy(CGFloat(scaleFactor))

        if isD {
            bez.lineToPoint(NSPoint(x: -hsize, y: -vsize))
            bez.lineToPoint(NSPoint(x: -hsize, y: vsize))
        } else {
            bez.lineToPoint(NSPoint(x: hsize, y: -vsize))
            bez.lineToPoint(NSPoint(x: hsize, y: vsize))
        }
        bez.closePath()
        bez.lineWidth = linewidth
        bez.lineJoinStyle = NSLineJoinStyle.RoundLineJoinStyle
        bez.transformUsingAffineTransform(qualityScale)
    }

    func quality() ->CGFloat {
        let settings = UserDefaults.standard
        let cutoffSum = settings.integerForKey(globals.primabilityCutoff) + settings.integerForKey(globals.stabilityCutoff)
       return CGFloat(primability + stability - cutoffSum) / CGFloat(200 - cutoffSum)
    }
    
    func direction() -> String {
        if isD {return "⫸"} else {return "⫷"}
    }
    
    override func info() -> NSAttributedString {
        var info = NSMutableAttributedString()
        extendString(starter: info, suffix: "Match for primer:    ", attr: fmat.normal)
        var thefmat = fmat.bigboldred
        if isD {thefmat = fmat.bigboldblue}
        extendString(starter: info, suffix: "\(primer.name)   \(self.direction())", attr: thefmat)
        extendString(starter: info, suffix: "    3′ position = base \(threePrime + 1),    Primability = \(primability)%,    Stability = \(stability)%,    Quality = \(self.quality())", attr: fmat.normal)
        return info
    }
    
    override func report() -> NSAttributedString {
        let side = 20 // Show this number of target bases left and right of primer
        var report = NSMutableAttributedString()
        let settings = UserDefaults.standard
        
        func addReport(s : String, attr: NSDictionary) {
            report.appendAttributedString(NSAttributedString(string: s, attributes: attr as [NSObject : AnyObject]))
        }
        func spaces(k : Int) -> String {
            return String(count: k, repeatedValue: Character(" "))
        }
        func hbonds(targetString : String, primerStringReceived: String) -> String {
            // Produce a string of | or : or blank to indicate base-pairing
            let pairScores = UserDefaults.standard.array(forKey:globals.pairScores) as! [[Int]]
            let topScore = pairScores[0][0]
            let tchars = "GATCN" as NSString
            var primerString = primerStringReceived
            var pchars = globals.compIUBString as NSString
            if isD {
                pchars = globals.IUBString as NSString
            }
            var bonds = ""
            
            let n = count(targetString)
             if count(primerString) >= n {
                // If strings are different sizes, then something is wrong
                let tbases = [Character](targetString.uppercaseString)
                let pbases = [Character](primerString.uppercaseString)
                var targIndex, primerIndex : Int
                for base in 0..<min(n, count(primerString)) {
                    targIndex = tchars.rangeOfString(String(tbases[base])).location
                    let badBase = targIndex == NSNotFound
                    if badBase {targIndex = 4}
                    primerIndex = pchars.rangeOfString(String(pbases[base])).location
                    if primerIndex == NSNotFound {primerIndex = 14}
                    let pairScore = pairScores[primerIndex][targIndex]
                    if pairScore == 0 || badBase  {
                        bonds += " "
                    } else if pairScore >= topScore {
                        bonds += "|"
                    } else {
                        bonds += ":"
                    }
                }
            }
            return bonds
        }
        
        let effectivePrimer = settings.integerForKey(globals.effectivePrimer)
        var seq = primer.seq.uppercaseString as NSString
        if seq.length > effectivePrimer {
            seq = seq.substringFromIndex(seq.length - effectivePrimer)
            seq = "…" + (seq as String)
        }
        let seqLen = seq.length
        var contextRight = threePrime + side + 1
        var contextLeft = threePrime - seqLen - side + 1
        if !isD {
            contextRight = threePrime + seqLen + side
            contextLeft = threePrime - side
        }
        let apdel = NSApplication.sharedApplication().delegate! as! AppDelegate
        let targFileString = apdel.substrateDelegate.targetView.textStorage!.string as NSString
        let firstbase = apdel.targDelegate.firstbase as Int
        let targString = targFileString.substringFromIndex(firstbase).uppercaseString as NSString
        var context = NSMutableString(string: "")
        if isCircular {
            if contextLeft < 0 {
                var newContext = targString.substringWithRange(NSMakeRange(targString.length + contextLeft , -contextLeft))
                context = NSMutableString(string: newContext)
                context = NSMutableString(string: (context as String) + targString.substringWithRange(NSMakeRange(0, contextRight)))
            } else if contextRight > targString.length {
                var newContext = targString.substringWithRange(NSMakeRange(0, contextRight - targString.length))
                context = NSMutableString(string: targString.substringWithRange(NSMakeRange(contextLeft, targString.length - contextLeft)) + newContext)
//                contextRight = targString.length
            } else {
                context = NSMutableString(string: (context as String) + targString.substringWithRange(NSMakeRange(contextLeft, contextRight - contextLeft)))
            }
        } else {
            if contextLeft < 0 {
                var newContext = context.stringByPaddingToLength(-contextLeft, withString: " ", startingAtIndex: 0)
                context = NSMutableString(string: newContext)
                contextLeft = 0
            }
            if contextRight > targString.length {
                contextRight = targString.length
            }
            context = NSMutableString(string: (context as String) + targString.substringWithRange(NSMakeRange(contextLeft, contextRight - contextLeft)))
        }
        let padding = spaces(side - 3)
        let matchingTarget = context.substringWithRange(NSMakeRange(side, min(seqLen, context.length - side)))
        var bonds = hbonds(matchingTarget, seq as String)
        var paddedPrimer = NSMutableAttributedString()
        addReport("\r", fmat.hline1)
        addReport("Match for primer: \(primer.name)  \(self.direction())\r", fmat.h3)
        addReport("\rPrimability = \(primability)%    Stability = \(stability)%,    Quality = \(self.quality()) \r\r", fmat.normal)

        
        if isD {
            var startNum = threePrime - seqLen + 2
            if startNum < 0 && isCircular {
                startNum = targString.length + startNum
            }
            let startNumString = String(startNum)
            let startDigits = count(startNumString)
            let endNumString = String(threePrime + 1)
            let endDigits = count(endNumString)
            var numline = "\t\(spaces(side - startDigits/2))\(startNumString)"
            numline += spaces(seqLen - startDigits/2 - endDigits/2 - 1) + endNumString
            addReport(numline, fmat.blueseq)
            extendString(starter: report, suffix1: "\r\t\(spaces(side))", attr1: fmat.seq, suffix2: "↓", attr2: fmat.symb)
            extendString(starter: report, suffix1: spaces(seqLen - 2), attr1: fmat.seq, suffix2:  "↓", attr2: fmat.symb)
            paddedPrimer = NSMutableAttributedString(string: "\r\(primer.name)", attributes : fmat.blue as [NSObject : AnyObject])
            extendString(starter: paddedPrimer, suffix: "\t" + padding + "5′ " , attr: fmat.blueseq )
            extendString(starter: paddedPrimer, suffix1: seq, attr1: fmat.seq, suffix2: " 3′ \r", attr2: fmat.blueseq)
            report.appendAttributedString(paddedPrimer)
            extendString(starter: report, suffix: "\t\(spaces(side))\(bonds)\r", attr: fmat.greyseq)
            addReport("Context\t", fmat.blue)
            addReport((context as String) + "\r\r" , fmat.seq)
            apdel.targDelegate.selectBasesFrom(threePrime - seqLen + 2, lastSelected: threePrime + 1)

        } else {
            let reverseSeq = (String(reverse(String(seq))) as NSString)
            paddedPrimer = NSMutableAttributedString(string: padding + "3′ " , attributes: fmat.blueseq as [NSObject : AnyObject])
            extendString(starter: paddedPrimer, suffix1: reverseSeq, attr1: fmat.seq, suffix2: " 5′ ", attr2: fmat.blueseq)
            bonds = hbonds(matchingTarget, reverseSeq as String)
            addReport("Context\t", fmat.blue)
            addReport((context as String) + "\r" , fmat.seq)
            extendString(starter: report, suffix: "\t\(spaces(side))\(bonds)\r", attr: fmat.greyseq)
            addReport(primer.name + "\t", fmat.blue)
            report.appendAttributedString(paddedPrimer)
            extendString(starter: report, suffix1: "\r\t\(spaces(side))", attr1: fmat.seq, suffix2: "↑", attr2: fmat.symb)
            extendString(starter: report, suffix1: spaces(seqLen - 2), attr1: fmat.seq, suffix2:  "↑", attr2: fmat.symb)
            addReport("\r", fmat.seq)
            let startNumString = String(threePrime + 1)
            let startDigits = count(startNumString)
            var endNum = threePrime + seqLen
            if endNum > targString.length && isCircular {
                endNum -= targString.length
            }
            let endNumString = String(endNum)
            let endDigits = count(endNumString)
            var numline = "\t\(spaces(side - startDigits/2))\(startNumString)"
            numline += spaces(seqLen - startDigits/2 - endDigits/2 - 1) + endNumString
            addReport(numline + "\r\r", fmat.blueseq)
            apdel.targDelegate.selectBasesFrom(threePrime + 1, lastSelected: threePrime + seqLen)
        }
        return report
    }
    

}
