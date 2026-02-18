import SwiftUI

enum ImageType: String, CaseIterable, Identifiable {
    case lifestyle = "Lifestyle"
    case product = "Product"
    case headshot = "Headshot"
    case pdLifestyleLite = "PD Lifestyle Lite"
    case foodShoot = "Food Shoot"
    case standard = "Standard/Custom"
    
    var id: String { self.rawValue }
    
    var defaultDestination: String {
        switch self {
        case .lifestyle: return "Lifestyle Images"
        case .product: return "Product Images"
        case .headshot: return "Headshots"
        case .pdLifestyleLite: return "Product Photographer > Master Images – Lifestyle"
        case .foodShoot: return "Product Photographer > Master Images – Lifestyle"
        case .standard: return "Product Photographer > Master Images – Lifestyle"
        }
    }
    
    var icon: String {
        switch self {
        case .lifestyle: return "photo.on.rectangle"
        case .product: return "cube"
        case .headshot: return "person.crop.rectangle"
        case .pdLifestyleLite: return "sparkles"
        case .foodShoot: return "fork.knife"
        case .standard: return "gearshape"
        }
    }
    
    var abbreviation: String {
        switch self {
        case .lifestyle: return "LS"
        case .product: return "PR"
        case .headshot: return "HS"
        case .pdLifestyleLite: return "PD"
        case .foodShoot: return "QC"
        case .standard: return "PD"
        }
    }
    
    // All image types use the same blue color now
    var color: Color {
        return Color.blue
    }
    
    // Light blue background for all types
    var backgroundColor: Color {
        return Color.blue.opacity(0.15)
    }
}

enum Retailer: String, CaseIterable, Identifiable {
    case qvc = "QVC"
    case hsn = "HSN"
    
    var id: String { self.rawValue }
    
    // Enhanced colors for better visual distinction
    var color: Color {
        switch self {
        case .qvc: return Color(red: 0.0, green: 0.4, blue: 0.8) // Brighter blue for QVC
        case .hsn: return Color(red: 0.6, green: 0.1, blue: 0.8) // Vibrant purple for HSN
        }
    }
    
    // Background color for badges and UI elements
    var backgroundColor: Color {
        self.color.opacity(0.2)
    }
}