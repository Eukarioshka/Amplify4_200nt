// [AUTO-PATCHED FOR SWIFT 5+]
//
//  Dimer.swift
//  Amplify4
//
//  Created by Bill Engels on 2/16/15.
//  Copyright (c) 2015 Bill Engels. All rights reserved.
//

import Foundation

struct Dimer {
    let p1, p2 : Primer
    let olap, n1, n2 : Int
    let p1pos: Int
    let quality: Double
    let serious: Bool
    
    var p1n = [Int]()
    var p2n = [Int]()

    init (primer primer1 : Primer, and primer2 : Primer) {
        //        self.serious = false
        //        p1pos = -1
        // Make sure primer 2 is the larger one
        if count(primer1.seq) < count(primer2.seq) {
            n1 = count(primer1.seq)
            n2 = count(primer2.seq)
            self.p1 = primer1
            self.p2 = primer2
        } else {
            self.p1 = primer2
            self.p2 = primer1
            n1 = count(p1.seq)
            n2 = count(p2.seq)
        }
        if primer1.hasBadBases() || primer2.hasBadBases() {
            self.quality = -1
            self.olap = 0
            self.serious = false
            self.p1pos = 0
        } else {
            let settings = UserDefaults.standard
            let dimerScores = settings.array(forKey:globals.dimScores) as! [[Int]]
            let dimerStringency = settings.integerForKey(globals.dimerStringency)
            let dimerMinOverlap = settings.integerForKey(globals.dimerOverlap)
            let dbases = [Character](globals.IUBString)
            var v = 0
            for c in p1.seq.uppercaseString {
                v = 0
                while c != dbases[v] {v++}
                p1n.append(v)
            }
            for c in p2.seq.uppercaseString {
                v = 0
                while c != dbases[v] {v++}
                p2n.append(v)
            }
            var bestQuality = Int.min
            var tempp1pos = -1
            var q = 0
            for leftEnd in 0..<n2 {
                q = 0
                for rightEnd in leftEnd..<min(leftEnd + n1 , n2) {
                    let index1 = p1n[n1 - (rightEnd - leftEnd) - 1]
                    let index2 = p2n[rightEnd ]
                    q += dimerScores[index1][index2]
                }
                if q >= bestQuality {
                    bestQuality = q
                    tempp1pos = leftEnd
                }
            }
            self.p1pos = tempp1pos
            self.quality = Double(bestQuality)
            self.olap = min(n1, n2 - tempp1pos)
            let xolap = olap
            let xquality = quality
            self.serious = (xquality > settings.doubleForKey(globals.dimerStringency)) && (xolap >= settings.integerForKey(globals.dimerOverlap))
        }
    }
    
    func report() -> String {
        // re-do this function with attributed strings?
         let dimerScores = UserDefaults.standard.array(forKey:globals.dimScores) as! [[Int]]
        let space = Character(" ")
        var s = "\r5' " + p2.seq + " 3'\r" + String(count: p1pos + 3, repeatedValue: space)
        for position2 in p1pos..<(p1pos + olap) {
            let index1 = p1n[n1 - 1 - (position2 - p1pos)]
            let index2 = p2n[position2]
            let score = dimerScores[index1][index2]
            if score < 0 {
                s += " "
            } else if score < 10 {
                s += ":"
            } else {
                s += "|"
            }
        }
        s +=  "\r"
        s += String(count: p1pos, repeatedValue: space) + "3' " + reverse(p1.seq) + " 5'\r"
        
        return s
    }
    
    func freport() -> NSAttributedString {
       
        let dimerScores = UserDefaults.standard.array(forKey:globals.dimScores) as! [[Int]]
        var report = NSMutableAttributedString()
        
        func addReport(s : String, attr: NSDictionary) {
            report.appendAttributedString(NSAttributedString(string: s, attributes: attr as [NSObject : AnyObject]))
        }
        
        addReport("\r", fmat.hline1)
        addReport("Potential primer-dimer for primers: \(p2.name) and \(p1.name)\r", fmat.h3)
        addReport("\rOverlap = \(olap),   Quality = \(quality)\r", fmat.normal)
        
        let space = Character(" ")
        addReport("\r\(p2.name)\t", fmat.blue)
        addReport("5′ ", fmat.blueseq)
        addReport(p2.seq, fmat.seq)
        addReport(" 3′\r", fmat.blueseq)
        addReport("\t", fmat.blue)

        var s = String(count: p1pos + 3, repeatedValue: space)
        for position2 in p1pos..<(p1pos + olap) {
            let index1 = p1n[n1 - 1 - (position2 - p1pos)]
            let index2 = p2n[position2]
            let score = dimerScores[index1][index2]
            if score < 0 {
                s += " "
            } else if score < 10 {
                s += ":"
            } else {
                s += "|"
            }
        }
        s +=  "\r"
        addReport(s, fmat.greyseq)
        addReport("\(p1.name)\t", fmat.blue)
        addReport(String(count: p1pos, repeatedValue: space) + "3′ " , fmat.blueseq)
        addReport(String(reverse(p1.seq)), fmat.seq)
        addReport(" 5′\r\r", fmat.blueseq)
        
        return report
    }

}