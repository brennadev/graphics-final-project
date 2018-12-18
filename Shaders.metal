//
//  Shaders.metal
//  ColorBlending
//
//  Created by Brenna Olson on 11/30/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//
//  Metal lets you put both the vertex and the fragment shader in the same file, so this has both shaders

#include <metal_stdlib>
#include "SharedDataTypes.h"
using namespace metal;

typedef struct {
    float2 position;
    float4 color;
} VertexIn;


typedef struct {
    float4 position [[position]];
    float4 colorA;  // first of two overlapping colors
    float4 colorB;  // second of two overlapping colors; black if no overlap (always check colorsOverlap first)
    bool colorsOverlap; // whether or not there's an overlap at the position; only check colorB's value if true
} VertexOut;


// in param needs a buffer, etc. attribute - of course, I won't know that until I start writing some shader code
vertex VertexOut vertexShader(uint vertexID [[ vertex_id ]],
                              constant int *strokeCount [[ buffer(strokeCountBufferID) ]],
                              constant float4 *color [[ buffer(colorBufferID) ]],
                              constant int *vertexCount [[ buffer(vertexCountBufferID) ]],
                              device float2 *vertices [[ buffer(verticesBufferID) ]],
                              constant float2 *viewportSize [[ buffer(4) ]]) {
    VertexOut returnValue;
    
    // because of the way I had to set up the buffer, it'll have to manually move to the next stroke

    // determine which stroke we're currently in
    int totalVertexCountSoFar = 0;
    int strokeIndex = 0;
    
    for (int i = 0; i < *strokeCount; i++) {
        if (vertexCount[i] + totalVertexCountSoFar <= vertexID) {
            totalVertexCountSoFar += vertexCount[i];
        } else {
            strokeIndex = i - 1;    // the important piece in determining which stroke we're in
            break;
        }
    }
    
    returnValue.colorA = color[strokeIndex];
    
    bool colorsOverlap = false;
    int vertexQuadLocation = vertexID % 6;
    
    // only need to go every 6 vertices as that's where they will line up right for an overlap
    for (int i = vertexQuadLocation; i < *vertexCount; i += 6) {
        // when we have a matching point
        // this if is really weird - it doesn't seem to want to compare the float2 directly
        if (vertices[i].x == vertices[vertexID].x && vertices[i].y == vertices[vertexID].y) {
            // determine which stroke the matching point is in
            int totalVertexCountSoFarMatchingVertex = 0;
            int strokeIndexMatching = 0;
            
            for (int j = 0; j < *strokeCount; j++) {
                if (vertexCount[j] + totalVertexCountSoFarMatchingVertex <= i) {
                    totalVertexCountSoFarMatchingVertex += vertexCount[j];
                } else {
                    strokeIndexMatching = j - 1;
                    break;
                }
            }
            
            // the matching index is in a different stroke - now have the color to blend with
            if (strokeIndexMatching != strokeIndex) {
                colorsOverlap = true;
                returnValue.colorB = color[strokeIndexMatching];
                break;
            }
        }
    }
    
    returnValue.colorsOverlap = colorsOverlap;
    
    // in normalized device coordinates
    returnValue.position.xy = vertices[vertexID] / *viewportSize;
    returnValue.position.zw = {0, 1};
    
    return {{0, 0, 0, 1}, {0, 0, 0, 1}, {0, 0, 0, 1}, false};
}

// formulas based off of Wikipedia article
float getHue(float4 color) {
    float returnValue;
    
    float maxRGB = max(color.r, max(color.g, color.b));
    float minRGB = min(color.r, min(color.g, color.b));
    
    if (maxRGB == color.r) {
        returnValue = 60 * (color.g - color.b) / (maxRGB - minRGB);
    } else if (maxRGB == color.g) {
        returnValue = 60 * (2 + (color.b - color.r) / (maxRGB - minRGB));
    } else if (maxRGB == color.b) {
        returnValue = 60 * (4 + (color.r - color.g) / (maxRGB - minRGB));
    } else {
        returnValue = 0;
    }
    
    if (returnValue < 0) {
        returnValue += 360;
    }
    
    return returnValue;
}


float getSaturation(float4 color) {
    
    float maxRGB = max(color.r, max(color.g, color.b));
    float minRGB = min(color.r, min(color.g, color.b));
    
    if (maxRGB == 0) {
        return 0;
    } else {
        return (maxRGB - minRGB) / maxRGB;
    }
}


float getBrightness(float4 color) {
    return max(color.r, max(color.g, color.b));
}


float4 getRGBFromHSB(float hue, float saturation, float brightness) {
    float chroma = saturation * brightness;
    
    int huePrime = hue / 60;
    
    float x = chroma * (1 - abs(huePrime % 2 - 1));
    
    float3 rgbColor;
    
    if (hue > 5.0) {
        rgbColor = {chroma, 0, x};
    } else if (hue > 4.0) {
        rgbColor = {x, 0, chroma};
    } else if (hue > 3.0) {
        rgbColor = {0, x, chroma};
    } else if (hue > 2.0) {
        rgbColor = {0, chroma, x};
    } else if (hue > 1.0) {
        rgbColor = {x, chroma, 0};
    } else if (hue >= 0.0) {
        rgbColor = {chroma, x, 0};
    } else {
        rgbColor = {0, 0, 0};
    }
    
    float m = brightness - chroma;
    
    return {rgbColor.r + m, rgbColor.g + m, rgbColor.b + m, 1.0};
}


fragment float4 fragmentShader(constant float *brightnessPercentage [[ buffer(5) ]],
                               VertexOut vertexData [[ stage_in ]]) {
    
    // when there's only one color at a given location
    if (!vertexData.colorsOverlap) {
        return vertexData.colorA;
        
    // blend the two colors
    } else {
        float colorAHue = getHue(vertexData.colorA);
        float colorASaturation = getSaturation(vertexData.colorA);
        float colorABrightness = getBrightness(vertexData.colorA);
        
        float colorBHue = getHue(vertexData.colorB);
        float colorBSaturation = getSaturation(vertexData.colorB);
        float colorBBrightness = getBrightness(vertexData.colorB);
        
        // handle a weird case where the colors are "wrapping around" on the hue values - where this behavior starts is subjective; for example, red and blue
        bool isNearOppositeEdges = false;
        
        if ((colorAHue < 40 && colorBHue > 185) || (colorAHue > 185 && colorBHue < 40)) {
            isNearOppositeEdges = true;
        }
        
        // where the fancy math comes in
        float combinedHue = 0.5 * colorAHue + 0.5 * colorBHue;
        
        // for the wrap around case to work
        if (isNearOppositeEdges) {
            combinedHue = 360 - combinedHue;
        }
        
        float combinedSaturation = 0.5 * colorASaturation + 0.5 * colorBSaturation;
        
        float combinedBrightness = *brightnessPercentage * (0.5 * colorABrightness + 0.5 * colorBBrightness);
        
        return getRGBFromHSB(combinedHue, combinedSaturation, combinedBrightness);
    }
}
