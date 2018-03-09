//
//  Plane.h
//  ARExample
//
//  Created by YangWei on 2018/3/8.
//  Copyright © 2018年 Apple-YangWei. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>

@interface Plane : SCNNode

- (instancetype)initWithAnchor:(ARPlaneAnchor *)anchor isHidden:(BOOL)hidden;

- (void)update:(ARPlaneAnchor *)anchor;

- (void)setTextureScale;

- (void)hide;

@property (nonatomic, strong) SCNBox *planeGeometry;

@end
