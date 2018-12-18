//
//  Renderer.swift
//  ColorBlending
//
//  Created by Brenna Olson on 11/30/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//
//  This is the "core" of the CPU-side of things and where the pipeline setup code goes

// A small amount of code (where noted) came from a raywenderlich.com tutorial (I downloaded the code a while back) - as some stuff from the website has changed, I'm not sure if this is even from a current version of an article, but this is so you at least know what website I got the code from
/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import MetalKit
import simd

/// Structure for data stored in buffer
struct Stroke {
    var color: float4
    
    /// Used for buffer indexing purposes - represents one point of one square drawn
    var vertexCount: Int
    var positions: [float2]
}


class Renderer: NSObject, MTKViewDelegate {
    
    let view: MTKView
    let device: MTLDevice
    let pipelineState: MTLRenderPipelineState
    let commandQueue: MTLCommandQueue
    
    /// Color the user is currently drawing with
    var currentColor = float4.black
    
    /// How much of the brightness to keep when blending colors
    var currentBrightnessPercentage: Float = 1.0
    
    /// Size of the drawing area
    var viewportSize = float2(0, 0)
    
    // MARK: - Buffer
    /// All the strokes drawn on the screen
    var strokes = [Stroke]()
    
    
    // due to the dynamic nature of the data, multiple buffers are needed
    var colorsBuffer: MTLBuffer?
    var vertexCountsBuffer: MTLBuffer?
    
    // PASS IN AS THE ACTUAL PIXELS (the actual number of pixels on a Retina display), NOT POINTS
    var verticesBuffer: MTLBuffer?
    
    var colorsBufferTotalBytes = 8192
    var vertexCountsBufferTotalBytes = 8192
    var verticesBufferTotalBytes = 65536
    
    
    /// Due to the way the vertex data is stored, it's easier to keep an accumulated value of the vertices generated to pass to `drawPrimitives`
    var totalVertexCount = 0
    
    var layer: CAMetalLayer
    
    // MARK: - Initialization
    init(view: MTKView, layer: CAMetalLayer) {
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
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.invalid
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create pipeline state")
        }
        
        commandQueue = device.makeCommandQueue()!
        self.layer = layer
        
        colorsBuffer = device.makeBuffer(length: colorsBufferTotalBytes, options: .storageModeShared)
        vertexCountsBuffer = device.makeBuffer(length: vertexCountsBufferTotalBytes, options: .storageModeShared)
        verticesBuffer = device.makeBuffer(length: verticesBufferTotalBytes, options: .storageModeShared)
        
        
        // this value will get updated as strokes get added
        colorsBuffer?.contents().storeBytes(of: strokes.count, toByteOffset: 0, as: Int.self)
    }
    
    
    // MARK: - MTKViewDelegate Methods
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize.x = Float(size.width)
        viewportSize.y = Float(size.height)
    }
    
    
    // called each frame - what's run on each iteration of the render loop (the actual render loop is set up automatically)
    func draw(in view: MTKView) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        // stuff below from Ray Wenderlich tutorial
        guard let drawable = layer.nextDrawable() else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        // end stuff from tutorial
        
        if let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            
            renderCommandEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewportSize[0]), height: Double(viewportSize[1]), znear: -1.0, zfar: 1.0))
            
            renderCommandEncoder.setRenderPipelineState(pipelineState)
            
            var strokesCount = strokes.count
            
            renderCommandEncoder.setVertexBytes(&strokesCount, length: MemoryLayout<Int>.stride, index: 0)
            renderCommandEncoder.setVertexBuffer(colorsBuffer, offset: 0, index: 1)
            renderCommandEncoder.setVertexBuffer(vertexCountsBuffer, offset: 0, index: 2)
            renderCommandEncoder.setVertexBuffer(verticesBuffer, offset: 0, index: 3)
            
            renderCommandEncoder.setVertexBytes(&viewportSize, length: MemoryLayout<float2>.stride, index: 4)
            renderCommandEncoder.setFragmentBytes(&currentBrightnessPercentage, length: MemoryLayout<Float>.stride, index: 5)
            
            renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: totalVertexCount)
            
            renderCommandEncoder.endEncoding()
            commandBuffer.present(drawable)
        }
        
        commandBuffer.commit()
    }
    
    
    // MARK: - Stroke Data Updating
    /// When a stroke is started
    func addStroke(at location: float2) {
        // in order to make a square, not just a single pixel, move slightly away from that original point
        let topLeft = float2(location.x - 1, location.y + 1) * 2
        let bottomLeft = float2(location.x - 1, location.y - 1) * 2
        let topRight = float2(location.x + 1, location.y + 1) * 2
        let bottomRight = float2(location.x + 1, location.y - 1) * 2
        
        // a single quad is drawn for a given point
        let positions = [topLeft, bottomLeft, bottomRight, topLeft, bottomRight, topRight]
        
        strokes.append(Stroke(color: currentColor, vertexCount: positions.count, positions: positions))
        
        
        // color
        colorsBuffer?.contents().storeBytes(of: currentColor, toByteOffset: MemoryLayout<float4>.stride * (strokes.count - 1), as: float4.self)
        
        // total vertex count for stroke
        vertexCountsBuffer?.contents().storeBytes(of: positions.count, toByteOffset: MemoryLayout<Int>.stride * (strokes.count - 1), as: Int.self)
        
        // actual vertices
        //verticesBuffer?.contents().storeBytes(of: positions, toByteOffset: MemoryLayout<float2>.stride * totalVertexCount, as: Array<float2>.self)
        verticesBuffer?.contents().storeBytes(of: positions[0], toByteOffset: MemoryLayout<float2>.stride * totalVertexCount, as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[1], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 1), as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[2], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 2), as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[3], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 3), as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[4], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 4), as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[5], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 5), as: float2.self)
        
        // making sure we're keeping track of the amount of data stored
        totalVertexCount += positions.count
        
        // ready to render
        view.setNeedsDisplay()
    }
    
    
    /// When a new point is drawn, the buffer needs to be updated with that point
    func addPoint(at location: float2) {
        // in order to make a square, not just a single pixel, move slightly away from that original point
        let topLeft = float2(location.x - 1, location.y + 1) * 2
        let bottomLeft = float2(location.x - 1, location.y - 1) * 2
        let topRight = float2(location.x + 1, location.y + 1) * 2
        let bottomRight = float2(location.x + 1, location.y - 1) * 2
        
        // a single quad is drawn for a given point
        let positions = [topLeft, bottomLeft, bottomRight, topLeft, bottomRight, topRight]
        
        strokes[strokes.endIndex - 1].positions.append(contentsOf: positions)

        
        // total vertex count for stroke
        strokes[strokes.endIndex - 1].vertexCount += positions.count     // FYI Swift doesn't have ++ or --

        verticesBuffer?.contents().storeBytes(of: positions[0], toByteOffset: MemoryLayout<float2>.stride * totalVertexCount, as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[1], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 1), as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[2], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 2), as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[3], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 3), as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[4], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 4), as: float2.self)
        verticesBuffer?.contents().storeBytes(of: positions[5], toByteOffset: MemoryLayout<float2>.stride * (totalVertexCount + 5), as: float2.self)
        
        vertexCountsBuffer?.contents().storeBytes(of: strokes[strokes.endIndex - 1].vertexCount, toByteOffset: MemoryLayout<Int>.stride * (strokes.count - 1), as: Int.self)
        
        // making sure we're keeping track of the amount of data stored
        totalVertexCount += positions.count
        
        // ready to render
        view.setNeedsDisplay()
    }
}
