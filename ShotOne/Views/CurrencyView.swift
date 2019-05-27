//
//  CurrencyView.swift
//  ShotOne
//
//  Created by Ivan Zinovyev on 25/03/2019.
//  Copyright © 2019 Ivan Zinovyev. All rights reserved.
//

import UIKit

// MARK: - Constants

private struct Constants {
    
    struct Bar {
        
        struct Shadow {
            
            static let dx: CGFloat = -3
            
            static let opacity: Float = 0.7
            
            static let radius: CGFloat = 5
            
        }
        
        static let cornerRadius: CGFloat = 1.5
        
        static let leading: CGFloat = 29.5
        
        static let width: CGFloat = 4
        
        static let bottomMargin: CGFloat = -5
        
    }
    
    struct Title {
        
        static let color = #colorLiteral(red: 0.6, green: 0.631372549, blue: 0.7843137255, alpha: 1)
        
        static let textAlignment: NSTextAlignment = .center
        
        static let topMargin: CGFloat = -18
        
    }
    
    struct Value {
        
        static let color = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        static let textAlignment: NSTextAlignment = .center
        
        static let sideMargin: CGFloat = 25
        
    }
    
}

// MARK: - Defaults

private struct Defaults {
    
    struct Background {
        
        static let cornerRadius: CGFloat = 37
        
        static let topPadding: CGFloat = 26
        
        static let colors = [ #colorLiteral(red: 0.2235294118, green: 0.2352941176, blue: 0.4117647059, alpha: 1), #colorLiteral(red: 0.1529411765, green: 0.1882352941, blue: 0.2980392157, alpha: 1) ]
        
    }
    
    struct Title {
        
        static let text: String = .empty
        
        static let attributedText = NSAttributedString(string: .empty)
        
        static let bottomMargin: CGFloat = 48
        
        static let font: UIFont? = .systemFont(ofSize: 12, weight: .bold)
        
    }
    
    struct Value {
        
        static let text: String = .empty
        
        static let attributedText = NSAttributedString(string: .empty)
        
        static let offset: CGFloat = 12
        
        static let font: UIFont? = .systemFont(ofSize: 26, weight: .medium)
        
    }
    
    struct Bar {
        
        static let color = #colorLiteral(red: 0.09803921569, green: 0.8235294118, blue: 0.4941176471, alpha: 1)
        
    }
    
}

class CurrencyView: BaseView {
    
    // MARK: - Layers
    
    private lazy var backgroundLayer: CAGradientLayer = {
        let layer = CAGradientLayer()

        layer.contentsScale = UIScreen.main.nativeScale
        layer.cornerRadius = Defaults.Background.cornerRadius
        layer.set(colors: Defaults.Background.colors)
        
        layer.layout(topPadding: Defaults.Background.topPadding, relativeTo: self)
        
        return layer
    }()
    
    // MARK: - Views
    
    private lazy var barView: UIView = {
        let view = UIView()
        
        view.layer.cornerRadius = Constants.Bar.cornerRadius
        view.set(barColor: Defaults.Bar.color)
        
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        
        label.font = Defaults.Title.font
        label.textColor = Constants.Title.color
        label.textAlignment = Constants.Title.textAlignment
        
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        
        label.font = Defaults.Value.font
        label.textColor = Constants.Value.color
        label.textAlignment = Constants.Value.textAlignment
        label.adjustsFontSizeToFitWidth = true
        
        return label
    }()
    
    // MARK: - Constraints
    
    lazy var valueCenterYConstraint = valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor,
                                                                          constant: valueOffset)
    
    // MARK: - Properties
    
    @objc dynamic var attributedTitle = Defaults.Title.attributedText {
        didSet { titleLabel.attributedText = attributedTitle }
    }
    
    @objc dynamic var attributedValue = Defaults.Value.attributedText {
        didSet { valueLabel.attributedText = attributedValue }
    }
    
    @objc dynamic var backgroundColors = Defaults.Background.colors {
        didSet { backgroundLayer.set(colors: backgroundColors) }
    }
    
    @objc dynamic var backgroundCornerRadius = Defaults.Background.cornerRadius {
        didSet { backgroundLayer.cornerRadius = backgroundCornerRadius }
    }
    
    @objc dynamic var backgroundTopPadding = Defaults.Background.topPadding {
        didSet { layoutBackgroundLayer() }
    }
    
    @objc dynamic var barColor = Defaults.Bar.color {
        didSet { barView.set(barColor: barColor) }
    }

    @objc dynamic var title = Defaults.Title.text {
        didSet { titleLabel.text = title }
    }
    
    @objc dynamic var titleFont = Defaults.Title.font {
        didSet { titleLabel.font = titleFont }
    }
    
    @objc dynamic var value = Defaults.Value.text {
        didSet { valueLabel.text = value }
    }
    
    @objc dynamic var valueFont = Defaults.Value.font {
        didSet { valueLabel.font = valueFont }
    }
    
    @objc dynamic var valueOffset = Defaults.Value.offset {
        didSet { valueCenterYConstraint.constant = valueOffset }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutBackgroundLayer()
    }
    
    // MARK: - Overrides
    
    override func initialize() {
        addViews()
        configureConstraints()
    }
    
}

// MARK: - Subviews

private extension CurrencyView {
    
    func addViews() {
        layer.addSublayers(
            backgroundLayer
        )
        
        addSubviews(
            barView,
            valueLabel,
            titleLabel
        )
    }
    
}

// MARK: - Layout

private extension CurrencyView {
    
    // MARK: - Manual
    
    func layoutBackgroundLayer() {
        backgroundLayer.layout(topPadding: backgroundTopPadding, relativeTo: self)
    }
    
    // MARK: - Auto
    
    func configureConstraints() {
        layoutTitleLabel()
        layoutValueLabel()
        layoutBarView()
    }
    
    func layoutTitleLabel() {
        titleLabel.activate {[
            $0.widthAnchor.constraint(equalTo: widthAnchor),
            $0.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: Constants.Title.topMargin),
            $0.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]}
    }
    
    func layoutValueLabel() {
        valueLabel.activate {[
            $0.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.Value.sideMargin),
            $0.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.Value.sideMargin),
            valueCenterYConstraint
        ]}
    }
    
    func layoutBarView() {
        barView.activate {[
            $0.widthAnchor.constraint(equalToConstant: Constants.Bar.width),
            $0.topAnchor.constraint(equalTo: topAnchor),
            $0.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.Bar.leading),
            $0.bottomAnchor.constraint(equalTo: valueLabel.topAnchor, constant: Constants.Bar.bottomMargin)
        ]}
    }
    
}

// MARK: - Private

private extension UIView {
    
    func set(barColor: UIColor) {
        backgroundColor = barColor
        
        layer.addShadow(color: barColor,
                        radius: Constants.Bar.Shadow.radius,
                        opacity: Constants.Bar.Shadow.opacity,
                        dx: Constants.Bar.Shadow.dx)
    }
    
}
