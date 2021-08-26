//
//  Fractions.swift
//  PotterNotes
//
//  Created by Labtanza on 8/15/21.
//

import Foundation

public struct Fraction {
    
    public var test = true
     

     
     public func testFunc() -> String? {
         test ? "test function found" : nil
     }
     
     public static var text = "Hello, World!"
    
    private(set) var whole:Int?
    private(set) var numerator:Int
    private(set) var denominator:Int {
        willSet {
            if newValue == 0 {
                fatalError()
            }
        }
    }
    
    public var decimal:Double {
        Double(whole ?? 0) + (Double(numerator)/Double(denominator))
    }
    
   public var description:String {
        var string = ""
        if isMixed {
            string = "\(whole!) "
        }
        string.append("\(numerator)/\(denominator)")
        
        return string
    }
    
    public var tuple:(Int, Int, Int) {
        let w = whole ?? 0
        return(w, numerator, denominator)
    }
    
    public func unmixed() -> (Int, Int) {
        (((whole ?? 0) * denominator) + numerator, denominator)
    }
    
    public var isProper:Bool {
        numerator < denominator
    }
    
    public var isMixed:Bool {
        whole != 0 && whole != nil
    }
    
    public func reduced() -> Fraction {
        let gcd = Self.gcd(numerator, denominator)
        return Fraction(whole: whole, numerator: numerator/gcd, denominator: denominator/gcd)
    }
    
}

//MARK: - Initializers
extension Fraction {
    //Also see the Lossless String Encodable
 
    public init?(_ double:Double, maxDenominator:Int = 100) {
        if let result = Self.calcFraction(double, maxDenominator: maxDenominator) {
            self.init(whole: result.whole, numerator: result.numerator, denominator:result.denominator)
        } else {
            return nil
        }
    }
    
    public init(_ double:Double, snapToDivisor divisor:Int) {
        let result = Self.snapped(double, divisor: divisor)
        self.init(whole: result.whole, numerator: result.numerator, denominator:result.denominator)
    }
    
    public init(_ tuple:(Int, Int, Int)) {
        self.init(whole: tuple.0, numerator: tuple.1, denominator: tuple.2)
    }
    
}


//MARK: - Static Functions

//MARK: -- Math
extension Fraction {
    //Stein Algorithm, Binary Recursion
    static func gcd(_ m:Int, _ n:Int) -> Int {
        //filter easy cases
        if m == n {
            return m
        }
        if m == 0 {
            return n
        }
        if n == 0 {
            return m
        }
        
        if (m & 1) == 0 {
            // m is even
            if (n & 1) == 1 {
                // and n is odd
                return gcd(m >> 1, n)
            } else {
                // both m and n are even
                return gcd(m >> 1, n >> 1) << 1
            }
        } else if (n & 1) == 0 {
            // m is odd, n is even
            return gcd(m, n >> 1)
        } else if (m > n) {
            // reduce larger argument
            return gcd((m - n) >> 1, n)
        } else {
            // reduce larger argument
            return gcd((n - m) >> 1, m)
        }
    }
    
}

//MARK: -- Find in String
extension Fraction:LosslessStringConvertible {
    public init?(_ canidateString:String) {
        guard let parsed = Self.parseFirst(in: canidateString) else {
            return nil
        }
        self.init(whole: parsed.whole, numerator: parsed.numerator, denominator: parsed.denominator)
    }
    
    static let fractionRegExPattern = #"(?<neg>-?){0,1}(?:\s){0,1}(?:(?<whole>\d+)\s)?(?<numerator>\d+)\/(?<denominator>\d+)"#
    
    static private func parseResult(_ match:NSTextCheckingResult, canidateString:String) -> (Int?, Int, Int) {
        var mulitplier = 1
        var wholeNumber: Int?
        
        var numerator: Int?
        var denominator: Int?
        
        if canidateString[(Range(match.range(withName: "neg"), in: canidateString)!)] == "-" {
            mulitplier = -1
            print("negative!")
        }
        
        if let wholeNumberRange = Range(match.range(withName: "whole"), in: canidateString) {
            wholeNumber = Int(canidateString[wholeNumberRange])
            if wholeNumber != nil {
                wholeNumber = wholeNumber! * mulitplier
            }
        }
        
        if let numeratorRange = Range(match.range(withName: "numerator"), in: canidateString) {
            numerator = Int(canidateString[numeratorRange])
            if wholeNumber == nil {
                numerator = numerator! * mulitplier
            }
        }
        
        if let denominatorRange = Range(match.range(withName: "denominator"), in: canidateString) {
            denominator = Int(canidateString[denominatorRange])
        }
        
        
        if numerator == nil || denominator == nil {
            fatalError("how did they not get found???!!!")
        }
        
        return (whole:wholeNumber, numerator:numerator!, denominator:denominator!)
    }
    
    static private func parseAll(in canidateString:String) -> [(whole:Int?, numerator:Int, denominator:Int)] {
        let regex = try? NSRegularExpression(pattern: fractionRegExPattern, options: .caseInsensitive)
        
        var foundFractions:[(whole:Int?, numerator:Int, denominator:Int)] = []
        
        if let matches = regex?.matches(in: canidateString, options: [], range: NSRange(location: 0, length: canidateString.utf16.count)) {
            
            for m in 0..<matches.count {
                foundFractions.append(parseResult(matches[m], canidateString: canidateString))
            }
        }
        return foundFractions
    }
    
    static private func parseFirst(in canidateString:String) -> (whole:Int?, numerator:Int, denominator:Int)? {
        guard let regex = try? NSRegularExpression(pattern: fractionRegExPattern, options: .caseInsensitive) else {
            print("bad regex")
            return nil
        }
        if let match = regex.firstMatch(in: canidateString, options: [], range: NSRange(location: 0, length: canidateString.utf16.count)) {
            return parseResult(match, canidateString: canidateString)
        }
        return nil
    }
}

//MARK: -- Working with Decimals
extension Fraction {
    
    static func splitDecimal(_ submittedValue:Double, discardTiny:Bool = true) -> (whole:Int, fractional:Double) {
        var whole = Int(submittedValue)
        var fractional = submittedValue - Double(whole)
        
        if discardTiny {
            if nearlyEqualDoubles(0, fractional) {
                fractional = 0
            } else if nearlyEqualDoubles(1, fractional) {
                fractional = 0
                whole = whole + 1
            }
        
        }
        return (whole, fractional)
    }
    
    static func nearlyEqualDoubles(_ lhs:Double, _ rhs:Double) -> Bool {
        //abs(abs(lhs) - abs(rhs)) <= tolerance
        let abslhs = lhs.magnitude
        let absrhs = rhs.magnitude
        let diff = (abslhs - absrhs).magnitude

            if (lhs == rhs) { // shortcut, handles infinities
                return true;
            } else if (lhs == 0 || rhs == 0 || (abslhs + absrhs < Double.leastNonzeroMagnitude)) {
                // a or b is zero or both are extremely close to it
                // relative error is less meaningful here
                return diff < (Double.ulpOfOne * Double.leastNonzeroMagnitude);
            } else { // use relative error
                return diff / Double.minimum((abslhs + absrhs), Double.greatestFiniteMagnitude) < Double.ulpOfOne;
            }
    }
    
    static func compareDoubles(_ lhs:Double, _ rhs:Double, withTolerance tolerance:Double) -> Bool {
        let diff = (lhs.magnitude - rhs.magnitude).magnitude
        return diff < tolerance
    }

    //Slowest
    static func calcFraction(_ submittedValue:Double, maxDenominator:Int = 100) -> (whole:Int?, numerator:Int, denominator:Int)? {
        
        if let whole = Int(exactly: submittedValue) {
            return (whole: whole, numerator:0, denominator:1)
        }
        
        let split = splitDecimal(submittedValue)
        
        for i in 2...maxDenominator {
            let multipliedFractional = split.fractional * Double(i)
            
            if let test = Int(exactly: multipliedFractional) {
                return (whole: split.whole, numerator: test, denominator:i)
            }
            
        }
        return nil
    }
    
    //Never use. Only works if double is gaurenteed to be a rational number.
    static private func easyRationalsFinder(_ submittedValue:Double, maxDenominator:Int = 100) -> (whole:Int?, numerator:Int, denominator:Int)? {
        
        if let whole = Int(exactly: submittedValue) {
            return (whole: whole, numerator:0, denominator:1)
        }
        
        let split = splitDecimal(submittedValue)
        
        for i in 2...maxDenominator {
            let multipliedFractional = split.fractional * Double(i)
            
            if let test = Int(exactly: multipliedFractional) {
                return (whole: split.whole, numerator: test, denominator:i)
            }
            
        }
        return nil
    }
    
    //Uses continued fractions to
    func speedsterApproximation(of sumittedValue: Double) -> (numerator:Int, denominator:Int) {
        print("Running A algo")
        var x = sumittedValue.magnitude
        let multiplier = x == sumittedValue ? 1 : -1
        var a = x.rounded(.towardZero)  //this is now
        var (h1, k1, h, k) = (1, 0, Int(a), 1)
        
        //k is an int so it doesn't have .ulp, so we have to find it
        // i.e. Double.ulpOfOne * pow(2.0, Double(value.exponent))
        //this while statement is saying that the current remainer of
        //the fraction you're using has to be bigger that the next
        //reprentable number - i.e. that differnce should be meaningful
        //not just the difference of how doubles are handled.
        while x - a > Double.ulpOfOne * pow(2, Double(Double(k).exponent)) {
            x = 1.0/(x - a)
            a = x.rounded(.down)
            (h1, k1, h, k) = (h, k, h1 + Int(a) * h, k1 + Int(a) * k)
            //print("\(Double(k).ulp) \tvs.\t \(Double.ulpOfOne * pow(2, Double(Double(k).exponent)))")
        }
        return (h * multiplier, k)
    }
    
    static func snappedToImperial(_ submittedValue:Double, toNearest granularity:ImperialSnapValue = .sixteenths, snapDirection:SnapDirection = .up) -> (whole:Int?, numerator:Int, denominator:Int) {
        
        var currentlysnapsto:ImperialSnapValue?
        //does it already snap?
        for size in ImperialSnapValue.allCases {
            if submittedValue.truncatingRemainder(dividingBy: size.rawValue)  == 0 {
                currentlysnapsto = size
                break
            }
        }
        
        if currentlysnapsto != nil && currentlysnapsto!.rawValue > granularity.rawValue {
            return snapped(submittedValue, divisor: Int(1/currentlysnapsto!.rawValue))
        }
        
        return snapped(submittedValue, divisor: Int(1/granularity.rawValue))
    }
    
    static func snapped(_ submittedValue:Double, divisor:Int, snapDirection:SnapDirection = .up) -> (whole:Int?, numerator:Int, denominator:Int) {
        let whole = (Int(submittedValue.rounded(.towardZero)))
        let denominator = divisor
        
        let result:Double = (submittedValue - Double(whole)) * Double(divisor)
        var numerator = 0
        
        switch snapDirection {
        
        case .up:
            numerator = Int(result.rounded(.awayFromZero))
        case .down:
            numerator = Int(result.rounded(.towardZero))
        }
        
        return (whole: whole, numerator: numerator, denominator: denominator)
    }
    
    enum SnapDirection {
        case up
        case down
    }
    
    enum ImperialSnapValue:Double, CaseIterable {
        case whole = 1.0000000
        case halves = 0.500000
        case quarters = 0.250000
        case eighths = 0.125000
        case sixteenths = 0.062500
        case thirtyseconds = 0.031250
        case sixtyfourths = 0.015625
    }
}
