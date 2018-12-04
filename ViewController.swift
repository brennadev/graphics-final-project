//
//  ViewController.swift
//  ColorBlending
//
//  Created by Brenna Olson on 11/30/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//
//  Due to how the iOS API is set up, even for simple stuff, it has to be set up with MVC 

import UIKit
import MetalKit
import simd

class ViewController: UIViewController {
    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var redButton: ColorButton!
  
    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // the controller handles a little of the Metal setup
        renderer = Renderer(view: mtkView)
        mtkView.delegate = renderer
        mtkView.setNeedsDisplay()
    }
    
    
    @IBAction func colorButtonTapped(_ sender: ColorButton) {
        renderer.currentColor = float4(from: sender.backgroundColorRoundedCorners)
        print("background color: \(sender.backgroundColorRoundedCorners)")
        
        if sender == redButton {
            redButton.backgroundColorRoundedCorners = .red
            print("background color red button: \(sender.backgroundColorRoundedCorners)")
        }
    }
    
    
    
    @IBAction func mtkViewPanned(_ sender: UIPanGestureRecognizer) {
        
    }
}

