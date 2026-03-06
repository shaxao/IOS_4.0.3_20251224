//
//  AnimationConstants.swift
//  RestaurantIngredientManager
//
//  Animation constants and utilities for consistent UI animations
//

import SwiftUI

/// Animation constants for consistent UI animations throughout the app
enum AnimationConstants {
    
    // MARK: - Duration Constants
    
    /// Quick animations (e.g., button press, toggle)
    static let quick: Double = 0.2
    
    /// Standard animations (e.g., view transitions, list updates)
    static let standard: Double = 0.3
    
    /// Slow animations (e.g., modal presentations, complex transitions)
    static let slow: Double = 0.5
    
    // MARK: - Spring Animations
    
    /// Bouncy spring animation for playful interactions
    static let bouncy = Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)
    
    /// Smooth spring animation for standard interactions
    static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
    
    /// Gentle spring animation for subtle effects
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0)
    
    // MARK: - Easing Animations
    
    /// Ease in animation
    static let easeIn = Animation.easeIn(duration: standard)
    
    /// Ease out animation
    static let easeOut = Animation.easeOut(duration: standard)
    
    /// Ease in-out animation
    static let easeInOut = Animation.easeInOut(duration: standard)
    
    // MARK: - List Animations
    
    /// Animation for list item insertion
    static let listInsert = Animation.spring(response: 0.35, dampingFraction: 0.75)
    
    /// Animation for list item removal
    static let listRemove = Animation.easeOut(duration: 0.25)
    
    /// Animation for list item move
    static let listMove = Animation.easeInOut(duration: 0.3)
    
    // MARK: - Modal Animations
    
    /// Animation for modal presentation
    static let modalPresent = Animation.spring(response: 0.4, dampingFraction: 0.85)
    
    /// Animation for modal dismissal
    static let modalDismiss = Animation.easeOut(duration: 0.3)
    
    // MARK: - Scale Values
    
    /// Scale for pressed state
    static let pressedScale: CGFloat = 0.95
    
    /// Scale for hover state
    static let hoverScale: CGFloat = 1.05
    
    // MARK: - Opacity Values
    
    /// Opacity for disabled state
    static let disabledOpacity: Double = 0.5
    
    /// Opacity for hidden state
    static let hiddenOpacity: Double = 0.0
    
    /// Opacity for visible state
    static let visibleOpacity: Double = 1.0
}

// MARK: - View Extensions

extension View {
    
    /// Applies a scale animation on press
    func scaleOnPress(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? AnimationConstants.pressedScale : 1.0)
            .animation(AnimationConstants.bouncy, value: isPressed)
    }
    
    /// Applies a fade in animation
    func fadeIn(duration: Double = AnimationConstants.standard) -> some View {
        self.transition(.opacity)
            .animation(.easeIn(duration: duration), value: UUID())
    }
    
    /// Applies a slide in animation from the specified edge
    func slideIn(from edge: Edge, duration: Double = AnimationConstants.standard) -> some View {
        self.transition(.move(edge: edge))
            .animation(.easeOut(duration: duration), value: UUID())
    }
    
    /// Applies a scale and fade animation
    func scaleAndFade(isVisible: Bool) -> some View {
        self
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(AnimationConstants.smooth, value: isVisible)
    }
    
    /// Applies a shake animation for errors
    func shake(trigger: Int) -> some View {
        self.modifier(ShakeEffect(shakes: trigger))
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    
    var animatableData: Int {
        get { shakes }
        set { shakes = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(CGFloat(shakes) * .pi * 2) * 10
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Loading Animation

struct LoadingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.blue, lineWidth: 3)
            .frame(width: 30, height: 30)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse() -> some View {
        self.modifier(PulseAnimation())
    }
}

// MARK: - Slide Transition

struct SlideTransition: ViewModifier {
    let isPresented: Bool
    let edge: Edge
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? (isPresented ? 0 : -UIScreen.main.bounds.width) :
                   edge == .trailing ? (isPresented ? 0 : UIScreen.main.bounds.width) : 0,
                y: edge == .top ? (isPresented ? 0 : -UIScreen.main.bounds.height) :
                   edge == .bottom ? (isPresented ? 0 : UIScreen.main.bounds.height) : 0
            )
            .animation(AnimationConstants.smooth, value: isPresented)
    }
}

extension View {
    func slideTransition(isPresented: Bool, from edge: Edge = .trailing) -> some View {
        self.modifier(SlideTransition(isPresented: isPresented, edge: edge))
    }
}
