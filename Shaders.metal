//
//  Shaders.metal
//  ColorBlending
//
//  Created by Brenna Olson on 11/30/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//
//  Metal lets you put both the vertex and the fragment shader in the same file, so this has both shaders

#include <metal_stdlib>
//#include "SharedDataTypes.h"
using namespace metal;

typedef struct {
    float2 position;
    float4 color;
} VertexIn;


typedef struct {
    float4 position [[position]];
    float4 color;
} VertexOut;

// in param needs a buffer, etc. attribute - of course, I won't know that until I start writing some shader code
vertex VertexOut vertexShader(/*VertexIn in*/) {
    VertexOut returnValue;
    return {{0, 0, 0, 1}, {0, 0, 0, 1}};
}

fragment float4 fragmentShader() {
    float4 returnValue;
    return {0, 0, 0, 1};
}
