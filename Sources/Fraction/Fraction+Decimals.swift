//
//  File.swift
//  
//
//  Created by Carlyn Maw on 8/27/21.
//

import Foundation


//MARK: -- Working with Decimals
extension Fraction {
    
    enum DecimalConversionStyle {
        //Continuous Fraction
        case fastAndHigh
        //Farey Number Seeking
        case closestLowest
        //Use a value closest to an "Imperial" denominator
        case snappedToImperial
    }
    
    enum ImperialSnapValue:Double, CaseIterable {
        case whole = 1.0000000
        case halves = 0.500000
        case quarters = 0.250000
        case eighths = 0.125000
        case sixteenths = 0.062500
        case thirtyseconds = 0.031250
        case sixtyfourths = 0.015625
        case onetwentyeighths = 0.0078125
        case twofiftysixths = 0.00390625
    }
    
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

    //MARK: - Approaches to estimating fractions
    
    //MARK: -- Continued fractions
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
    
    //MARK: -- Farey Numbers
    //See Numberphiles
    //Funny Fractions and Ford Circles
    //https://www.youtube.com/watch?v=0hlvhQZIOQw
    //Infinite Fractions
    //https://www.youtube.com/watch?v=DpwUVExX27E
    //Papers
    //"Recounting the Rationals" Calkin, Wilf 1999
    // Also
    // https://www.cut-the-knot.org/proofs/fords.shtml#mediant
    
    
    //Uses Farey numbers, potentially could end up with a lower denom than the speedster
    //Mostly clean up to handle numbers not in 0...1
    static func findFareyApproximation(of submittedDouble:Double, withMaxDenominator maxLimit:Int) -> (Int?, Int, Int) {
        let neg = submittedDouble < 0
        let split = splitDecimal(submittedDouble)
        
        guard split.fractional.magnitude > 0 else {
            return (split.whole, 0, 1)
        }
        
        var (numerator, denominator) = fareyAprroximator(of: split.fractional.magnitude, withMaxDenominator: maxLimit)

        
        let whole = split.whole == 0 ? nil : split.whole
        
        if neg && whole == nil {
            numerator = numerator * -1
        }

        return (whole, numerator, denominator)
        
    }

    //only takes positive numbers between 0 and 1
    //if it is given a bigger number, the searching algo
    //has a stride of the whole number (rounded up)
    static private func fareyAprroximator(of submittedDouble:Double, withMaxDenominator maxLimit:Int) -> (Int, Int){
        var pair1 = (0,1)
        var pair2 = (1, 1)
        
        while pair1.1 <= maxLimit && pair2.1 <= maxLimit {
            let mendiantPair = fareyAddition(f1: pair1, f2: pair2)
            let mendiantDouble = Double(mendiantPair.0)/Double(mendiantPair.1)
            
            //If we lucked into it return, else snuggle the pairs in
            switch submittedDouble {
            case mendiantDouble:
                return mendiantPair
            case let x where x < mendiantDouble:
                pair2 = mendiantPair
            default:
                pair1 = mendiantPair
            }
            
            //print("pair1:\(pair1), pair2:\(pair2)")
            
        }
        
        //print("pair1:\(pair1), pair2:\(pair2)")
        let lowerDenomPair = pair1.1 > maxLimit ? pair2 : pair1
        return lowerDenomPair
    }

    //Also mendiants and fresman sums
    private static func fareyAddition(f1:(Int, Int), f2:(Int, Int)) -> (Int, Int){
        let n = f1.0 + f2.0
        let d = f1.1 + f2.1
        return (n, d)
    }

    private static func fareyShift(pair:(Int, Int)) -> (Int, Int) {
        let x = pair.0 + pair.1
        let y = pair.1
        return (x,y)
    }

    //stern-brocot sequence?
    private static func fareySequence(iterations:Int) {
        var pair = (0,1)
        var sequence:[Int] = []
        for i in 0...iterations {
            let newPair = fareyShift(pair: pair)
            sequence.append(newPair.0)
            sequence.append(newPair.1)
            pair = (sequence[i], sequence[i+1])
        }
        print(sequence)
    }

    //Not very useful...
    private static func fareySequence(maxValue:Int) {
        //let iterations = 100000
        var i = 0
        var pair = (0,1)
        var sequence:[Int] = []
        while !sequence.contains(maxValue+1) {
            let newPair = fareyShift(pair: pair)
            if newPair.1 == (maxValue+1) || newPair.0 == maxValue+1 {
                break
            }
            sequence.append(newPair.0)
            sequence.append(newPair.1)
            pair = (sequence[i], sequence[i+1])
            //print(pair)
            i = i + 1
        }
        print(sequence)
    }
    
    //MARK: -- Snaping to Given Denominators

    //Should find the lowest... kinda very slow
    static func snappedToImperial(_ submittedValue:Double, toNearest granularity:ImperialSnapValue = .sixtyfourths, snapDirection:SnapDirection = .up) -> (whole:Int?, numerator:Int, denominator:Int) {
        
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
    


    
    //MARK: - Farey Numbers
    

 
    
//END EXTENTION
}
