//
//  ViewController.swift
//  ColorBlending
//
//  Created by Brenna Olson on 11/30/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//
//  Due to how the iOS API is set up, even for simple stuff, it has to be set up with MVC
//  This file just handles the UI input and the very start of the Metal setup

import UIKit
import MetalKit
import simd

class ViewController: UIViewController {
    @IBOutlet weak var mtkView: MTKView!
  
    var renderer: Renderer!
    var translationStartPoint = float2(0, 0)
    var metalLayer: CAMetalLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // this block from Ray Wenderlich tutorial
        metalLayer = CAMetalLayer()
        metalLayer.device = MTLCreateSystemDefaultDevice()!
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        mtkView.layer.addSublayer(metalLayer)
        
        // the controller handles a little of the Metal setup
        renderer = Renderer(view: mtkView, layer: metalLayer)
        mtkView.delegate = renderer
        mtkView.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
        mtkView.delegate?.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
        mtkView.setNeedsDisplay()
    }
    
    
    /// When any of the color buttons are tapped
    @IBAction func colorButtonTapped(_ sender: ColorButton) {
        renderer.currentColor = float4(from: sender.backgroundColorRoundedCorners)
    }
    
    @IBAction func brightnessPercentageSliderValueChanged(_ sender: ValueDescriptionSlider) {
        renderer.currentBrightnessPercentage = sender.value
    }
    
    
    
    /// When the user taps/drags on the Metal view
    @IBAction func mtkViewPanned(_ sender: UIPanGestureRecognizer) {
        
        let pointTapped = float2(from: sender.translation(in: mtkView))
        
        // make sure the values drawn on get added to the buffer
        switch sender.state {
        case .began:
            translationStartPoint = pointTapped
            renderer.addStroke(at: pointTapped)
        case .changed:
            renderer.addPoint(at: translationStartPoint + pointTapped)
            break
        default:
            break
        }
    }
}



