//
//  Fraction+String.swift
//  
//
//  Created by Carlyn Maw on 8/27/21.
//

import Foundation


//MARK: -- Find in String
extension Fraction:LosslessStringConvertible {
    public init?(_ candidateString:String) {
        guard let parsed = Self.parseFirst(in: candidateString) else {
            return nil
        }
        self.init(whole: parsed.whole, numerator: parsed.numerator, denominator: parsed.denominator)
    }
    
    static let fractionRegExPattern = #"(?<neg>-?){0,1}(?:\s){0,1}(?:(?<whole>\d+)\s)?(?<numerator>\d+)\/(?<denominator>\d+)"#
    
    static private func parseResult(_ match:NSTextCheckingResult, candidateString:String) -> (Int?, Int, Int) {
        var mulitplier = 1
        var wholeNumber: Int?
        
        var numerator: Int?
        var denominator: Int?
        
        if candidateString[(Range(match.range(withName: "neg"), in: candidateString)!)] == "-" {
            mulitplier = -1
            //print("negative!")
        }
        
        if let wholeNumberRange = Range(match.range(withName: "whole"), in: candidateString) {
            wholeNumber = Int(candidateString[wholeNumberRange])
            if wholeNumber != nil {
                wholeNumber = wholeNumber! * mulitplier
            }
        }
        
        if let numeratorRange = Range(match.range(withName: "numerator"), in: candidateString) {
            numerator = Int(candidateString[numeratorRange])
            if wholeNumber == nil {
                numerator = numerator! * mulitplier
            }
        }
        
        if let denominatorRange = Range(match.range(withName: "denominator"), in: candidateString) {
            denominator = Int(candidateString[denominatorRange])
        }
        
        
        if numerator == nil || denominator == nil {
            fatalError("how did they not get found???!!!")
        }
        
        return (whole:wholeNumber, numerator:numerator!, denominator:denominator!)
    }
    
    static private func parseAll(in candidateString:String) -> [(whole:Int?, numerator:Int, denominator:Int)] {
        let regex = try? NSRegularExpression(pattern: fractionRegExPattern, options: .caseInsensitive)
        
        var foundFractions:[(whole:Int?, numerator:Int, denominator:Int)] = []
        
        if let matches = regex?.matches(in: candidateString, options: [], range: NSRange(location: 0, length: candidateString.utf16.count)) {
            
            for m in 0..<matches.count {
                foundFractions.append(parseResult(matches[m], candidateString: candidateString))
            }
        }
        return foundFractions
    }
    
    static private func parseFirst(in candidateString:String) -> (whole:Int?, numerator:Int, denominator:Int)? {
        guard let regex = try? NSRegularExpression(pattern: fractionRegExPattern, options: .caseInsensitive) else {
            print("bad regex")
            return nil
        }
        if let match = regex.firstMatch(in: candidateString, options: [], range: NSRange(location: 0, length: candidateString.utf16.count)) {
            return parseResult(match, candidateString: candidateString)
        }
        return nil
    }
}

