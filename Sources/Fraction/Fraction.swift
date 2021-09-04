//
//  Fractions.swift
//  PotterNotes
//
//  Created by Labtanza on 8/15/21.
//

import Foundation

public struct Fraction {
    
    //----- For testing and setup
    public var test = true
    public func testFunc() -> String? {
        test ? "test function found" : nil
    }
    public static var text = "Hello, World!"
    //-----------------------
    
    private(set) var whole:Int?
    private(set) var numerator:Int
    private(set) var denominator:Int {
        willSet {
            if newValue == 0 {
                fatalError()
            }
        }
    }
    
    public var double:Double {
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
    
    public var components:(Int, Int, Int) {
        let w = whole ?? 0
        return(w, numerator, denominator)
    }
    
    public func unmixedComponents() -> (Int, Int) {
        (((whole ?? 0) * denominator) + numerator, denominator)
    }
    
    public var isProper:Bool {
        numerator < denominator  && !isMixed
    }
    
    public var isMixed:Bool {
        whole != 0 && whole != nil
    }
    
    public func reduced() -> Fraction {
        let gcd = Self.gcd(numerator, denominator)
        return Fraction(whole: whole, numerator: numerator/gcd, denominator: denominator/gcd)
    }
    
}

//MARK: - Int based convenience itializers
extension Fraction {

    public init(_ tuple:(Int, Int, Int)) {
        self.init(whole: tuple.0, numerator: tuple.1, denominator: tuple.2)
    }
    
}


//MARK: - Static Functions

//MARK: -- Math
extension Fraction:Comparable, Equatable {
    
    
    // ---------  Fighting Words
    //(Rational Numbers People will want to have a word)
    public static func < (lhs: Fraction, rhs: Fraction) -> Bool {
        lhs.double < rhs.double
    }
    
    public static func ==(lhs: Fraction, rhs: Fraction) ->Bool {
        lhs.double == rhs.double
    }
    // ---------  End Fighting Words
    
     
    public static func +(_ lhs:Fraction, _ rhs:Fraction) -> Fraction {
        let (lhs_N, lhs_D) = lhs.unmixedComponents()
        let (rhs_N, rhs_D) = rhs.unmixedComponents()
        
        let crossDenominator = lhs_D * rhs_D
        let cross_lDrN = lhs_D * rhs_N
        let cross_rDlN = lhs_N * rhs_D
        
        return Fraction(mixedFormFromSimple((cross_lDrN + cross_rDlN), crossDenominator))
    }
    
    public static func -(_ lhs:Fraction, _ rhs:Fraction) -> Fraction {
        let (lhs_N, lhs_D) = lhs.unmixedComponents()
        let (rhs_N, rhs_D) = rhs.unmixedComponents()
        
        let crossDenominator = lhs_D * rhs_D
        let cross_lDrN = lhs_D * rhs_N * -1
        let cross_rDlN = lhs_N * rhs_D
        
        return Fraction(mixedFormFromSimple((cross_lDrN + cross_rDlN), crossDenominator))
    }
    
    public static func *(_ lhs:Fraction, _ rhs:Fraction) -> Fraction {
        let (lhs_N, lhs_D) = lhs.unmixedComponents()
        let (rhs_N, rhs_D) = rhs.unmixedComponents()
        
        let numerator = lhs_N * rhs_N
        let denominator = lhs_D * rhs_D
        
        return Fraction(mixedFormFromSimple(numerator, denominator))
    }
    
    public static func /(_ lhs:Fraction, _ rhs:Fraction) -> Fraction {
        let (lhs_N, lhs_D) = lhs.unmixedComponents()
        let (rhs_N, rhs_D) = rhs.unmixedComponents()
        
        let numerator = lhs_N * rhs_D
        let denominator = lhs_D * rhs_N
        
        return Fraction(mixedFormFromSimple(numerator, denominator))
    }
    
    //MARK: Internal Processing
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
        
        //binary last digit check, recursive
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
    
    static func shiftReducer(_ m:Int, _ n:Int) -> (Int, Int) {
        if m == n {
            return (1, 1)
        }
        
        if (m & 1) == 0 && (n & 1) == 0 {
            return shiftReducer(m >> 1, n >> 1) //<< 1
        }
        
        return (m,n)
    }
    
    static func mixedFormFromSimple(_ n:Int, _ d:Int) -> (whole:Int, numerator:Int, denominator:Int) {
        let (quotient, remainder) = n.quotientAndRemainder(dividingBy: d)
        return (quotient, remainder, d)
    }

    
}

