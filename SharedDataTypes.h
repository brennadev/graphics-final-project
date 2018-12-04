//
//  SharedDataTypes.h
//  ColorBlending
//
//  Created by Brenna Olson on 11/30/18.
//  Copyright © 2018 Brenna Olson. All rights reserved.
//

// Data types shared between Swift code and shaders - has to be in C, not Swift, for it to interoperate

#ifndef SharedDataTypes_h
#define SharedDataTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

/*typedef struct {
    float2 position;
    float4 color;
} VertexIn;


typedef struct {
    
} VertexOut;*/


#endif /* SharedDataTypes_h */
