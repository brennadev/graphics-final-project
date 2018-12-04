//
//  Renderer.swift
//  ColorBlending
//
//  Created by Brenna Olson on 11/30/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//
//  This is the "core" of the CPU-side of things and where the pipeline setup code goes

import UIKit
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {
    
    let view: MTKView
    let device: MTLDevice
    let pipelineState: MTLRenderPipelineState
    let commandQueue: MTLCommandQueue
    
    var currentColor = float4.black
    
    init(view: MTKView) {
        self.view = view
        device = MTLCreateSystemDefaultDevice()!
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        // Pipeline descriptor setup
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create pipeline state")
        }
        
        commandQueue = device.makeCommandQueue()!
    }
    
    // this stub has to be in here, but since I'm only running on one device in one orientation, it shouldn't need to do anything
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    
    // called each frame - what's run on each iteration of the render loop (the actual render loop is set up automatically)
    func draw(in view: MTKView) {
        
    }
    

}
