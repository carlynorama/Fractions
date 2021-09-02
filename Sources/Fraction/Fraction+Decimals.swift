//
//  File.swift
//  
//
//  Created by Carlyn Maw on 8/27/21.
//

import Foundation


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
    
    //Is using the ulp of the numbers to determine if any difference
    //between the number seem meaningful relative to their size.
    //TODO: Swift has a .ulp feature to doubles. This should be rewritten
    //to use it.
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
    
    //Use this one when the tolerance is significantly larger than the
    //.ulp would.
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
    static func speedsterApproximation(of sumittedValue: Double) -> (numerator:Int, denominator:Int) {
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
    
    enum DecimalConversionStyle {
        //Continuous Fraction
        case fastAndHigh
        //Farey Number Seeking
        case closestLowest
        //Use a value closest to an "Imperial" denominator
        case snappedToImperial
    }
}
