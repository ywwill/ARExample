//
//  Plane.m
//  ARExample
//
//  Created by YangWei on 2018/3/8.
//  Copyright © 2018年 Apple-YangWei. All rights reserved.
//

#import "Plane.h"

@implementation Plane

- (instancetype)initWithAnchor:(ARPlaneAnchor *)anchor{
    self = [super init];
    
    self.planeGeometry = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
    
    SCNMaterial *material = [SCNMaterial new];
    UIImage *img = [UIImage imageNamed:@"tron_grid"];
    material.diffuse.contents = img;
    self.planeGeometry.materials = @[material];
    
    SCNNode *planeNode = [SCNNode nodeWithGeometry:self.planeGeometry];
    planeNode.position = SCNVector3Make(anchor.extent.x, 0, anchor.extent.z);
    
    planeNode.transform = SCNMatrix4MakeRotation(-M_PI/2.0, 1.0, 0.0, 0.0);
    
    [self setTextureScale];
    
    [self addChildNode:planeNode];
    
    return self;
}

- (void)update:(ARPlaneAnchor *)anchor{
    self.planeGeometry.width = anchor.extent.x;
    self.planeGeometry.height = anchor.extent.z;
    self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
    
    [self setTextureScale];
}

- (void)setTextureScale {
    CGFloat width = self.planeGeometry.width;
    CGFloat height = self.planeGeometry.height;
    
    // As the width/height of the plane updates, we want our tron grid material to
    // cover the entire plane, repeating the texture over and over. Also if the
    // grid is less than 1 unit, we don't want to squash the texture to fit, so
    // scaling updates the texture co-ordinates to crop the texture in that case
    SCNMaterial *material = self.planeGeometry.materials.firstObject;
    material.diffuse.contentsTransform = SCNMatrix4MakeScale(width, height, 1);
    material.diffuse.wrapS = SCNWrapModeRepeat;
    material.diffuse.wrapT = SCNWrapModeRepeat;
}

@end
