//
//  File.swift
//  
//
//  Created by Carlyn Maw on 8/27/21.
//

import Foundation


//MARK: -- Working with Doubles
extension Fraction {
    
    public init(_ submittedDouble:Double) {
        let result = Self.findFastApproximation(of: submittedDouble)
        self.init(whole: result.whole, numerator: result.numerator, denominator: result.denominator)
    }
    
    public init(_ submittedDouble:Double, withMaxDenominator maxDenomVal:Int) {
        let result = Self.findFareyApproximation(of: submittedDouble, withMaxDenominator: maxDenomVal)
        self.init(whole: result.whole, numerator: result.numerator, denominator: result.denominator)
    }
    
    public init(_ submittedDouble:Double, snapToCustomaryUnit divisor:CustomaryUnitValue) {
        let result = Self.findClosest(divisor, to: submittedDouble, rounding: .up)
        self.init(whole: result.whole, numerator: result.numerator, denominator: result.denominator)
    }
    
    public init(_ submittedDouble:Double, snapToDivisor divisor:Int) {
        let result = Self.findClosestTo(submittedDouble, withDivisor: divisor, rounding: .up)
        self.init(whole: result.whole, numerator: result.numerator, denominator:result.denominator)
    }
    
//    TODO: A decimal conversion style to simplify inits?
//    enum DecimalConversionStyle {
//        //Continuous Fraction
//        case fastAndHigh
//        //Farey Number Seeking
//        case closestLowest
//        //Use a value closest to an "US Customary Unit" compatible denominator
//        case snappedToCustomary
//    }
    
    public enum CustomaryUnitValue:Double, CaseIterable {
        case whole = 1.0000000
        case halves = 0.500000
        case quarters = 0.250000
        case eighths = 0.125000
        case sixteenths = 0.062500
        case thirtyseconds = 0.031250
        case sixtyfourths = 0.015625
        case onetwentyeighths = 0.0078125
        case twofiftysixths = 0.00390625
        
        var index:Int {
            switch self {
            case .whole:
                return 0
            case .halves:
                return 1
            case .quarters:
                return 2
            case .eighths:
                return 3
            case .sixteenths:
                return 4
            case .thirtyseconds:
                return 5
            case .sixtyfourths:
                return 6
            case .onetwentyeighths:
                return 7
            case .twofiftysixths:
                return 8
            }
        }
        
        subscript(index: Int) -> CustomaryUnitValue? {
            switch index {
            case 0:
                return .whole
            case 1:
                return .halves
            case 2:
                return .quarters
            case 3:
                return .eighths
            case 4:
                return .sixteenths
            case 5:
                return .thirtyseconds
            case 6:
                return .sixtyfourths
            case 7:
                return .onetwentyeighths
            case 8:
                return .twofiftysixths
            default:
                return nil
            }
        }

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
    static func findFastApproximation(of sumittedValue: Double) -> (whole:Int?, numerator:Int, denominator:Int) {
        var multiplier = 1
        let pair = continuedFractionApproximator(of: sumittedValue)
        if pair.numerator < 0 {
            multiplier = -1
        }
        let result = Self.mixedFormFromSimple(abs(pair.numerator), pair.denominator)
        let whole = result.whole == 0 ? nil : result.whole * multiplier
        
        //if it's been used set it back to 1
        if result.whole != 0 {
            multiplier = 1
        }
        
        return (whole: whole, numerator:result.numerator * multiplier, denominator: result.denominator)
    }
    
    
    static func continuedFractionApproximator(of sumittedValue: Double) -> (numerator:Int, denominator:Int) {
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
    // see also stern-brocot sequence
    
    
    //Using Farey numbers for Max denom b/c likely thats a situation where the person cares about pretty
    //looking numbers.
    
    static func findFareyApproximation(of submittedDouble:Double, withMaxDenominator maxLimit:Int) -> (whole:Int?, numerator:Int, denominator:Int) {
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
            
            //If we lucked into a return, else snuggle the pairs in
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

    
    //MARK: -- Snaping to Given Denominators
    


    //Should find the lowest... kinda very slow
    static func findClosest(_ granularity:CustomaryUnitValue = .sixtyfourths, to submittedValue:Double, rounding snapDirection:SnapDirection = .up) -> (whole:Int?, numerator:Int, denominator:Int) {
        
        let absValue = submittedValue.magnitude
        var multiplier = absValue == submittedValue ? 1 : -1
  
        let split = splitDecimal(absValue)
        
        let (n1, d1) = customaried(split.fractional, withBinaryPlaceTolerance: granularity.index)
        let (numerator, denominator) = shiftReducer(n1, d1) //not gcd b/c only valif if denom is power of 2
        
        let whole = split.whole == 0 ? nil : split.whole * multiplier
        
        //if it's been used set it back to 1
        if split.whole != 0 {
            multiplier = 1
        }
        
        return (whole: whole, numerator:numerator * multiplier, denominator: denominator)

    }
    
    //Value between 0 and 1
    static func customaried(_ submittedDouble:Double, withBinaryPlaceTolerance T:Int = 8, snapDirection:SnapDirection = .up ) -> (Int, Int){
        let denominator = pow(2.0, Double(T))
        let numerator = Int((denominator * submittedDouble).rounded(snapDirection.roundRule))
        
        return (numerator, Int(denominator))
    }

    
    static func findClosestTo(_ submittedValue:Double, withDivisor divisor:Int, rounding snapDirection:SnapDirection = .up) -> (whole:Int?, numerator:Int, denominator:Int) {
        
        let absValue = submittedValue.magnitude
        var multiplier = absValue == submittedValue ? 1 : -1
  
        let split = splitDecimal(absValue)
        let denominator = divisor
        
        let result:Double = split.fractional * Double(divisor)
        var numerator = 0
        
        numerator = Int(result.rounded(snapDirection.roundRule))
        
        let whole = split.whole == 0 ? nil : split.whole * multiplier
        
        //if it's been used set it back to 1
        if split.whole != 0 {
            multiplier = 1
        }
        
        return (whole: whole, numerator:numerator * multiplier, denominator: denominator)
    }
    
    enum SnapDirection {
        case up
        case down
        case nearest
        
        var roundRule:FloatingPointRoundingRule {
            switch self {
            case .up:
                return FloatingPointRoundingRule.awayFromZero
            case .down:
                return FloatingPointRoundingRule.towardZero
            case .nearest:
                return FloatingPointRoundingRule.toNearestOrEven
            }
        }
    }
    

    
//END EXTENTION
}
