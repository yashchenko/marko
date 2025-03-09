//
//  AppointmentSlotView.swift
//  Marko
//
//  Created by Ivan on 28.02.2025.
//

import UIKit

class AppointmentSlotView: UIView {
    private let slotLabel = UILabel()
    private let payButton = UIButton(type: .system)
    
    /// Closure called when the pay button is tapped.
    var onPayTapped: (() -> Void)?
    
    init(slotText: String) {
        super.init(frame: .zero)
        slotLabel.text = slotText
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupView() {
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        backgroundColor = .white
        
        slotLabel.font = UIFont.systemFont(ofSize: 16)
        slotLabel.translatesAutoresizingMaskIntoConstraints = false
        
        payButton.setTitle("Book & Pay", for: .normal)
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.addTarget(self, action: #selector(payButtonTapped), for: .touchUpInside)
        
        addSubview(slotLabel)
        addSubview(payButton)
        
        NSLayoutConstraint.activate([
            slotLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            slotLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            payButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            payButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            payButton.leadingAnchor.constraint(equalTo: slotLabel.trailingAnchor, constant: 10),
            
            heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func payButtonTapped() {
        onPayTapped?()
    }
}
