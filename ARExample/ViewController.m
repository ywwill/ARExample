//
//  ViewController.m
//  ARExample
//
//  Created by YangWei on 2018/3/8.
//  Copyright © 2018年 Apple-YangWei. All rights reserved.
//

#import "ViewController.h"
#import "Plane.h"

@interface ViewController () <ARSCNViewDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@property (nonatomic, strong) NSMutableDictionary *planes;

@end

    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupScene];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupSession];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Pause the view's session
    [self.sceneView.session pause];
}

- (void)setupScene{
    // Set the view's delegate
    self.sceneView.delegate = self;

    // Show statistics such as fps and timing information
    self.sceneView.showsStatistics = YES;
    
    self.planes = [NSMutableDictionary new];

    SCNScene *scene = [SCNScene new];

    // Set the scene to the view
    self.sceneView.scene = scene;
    self.sceneView.autoenablesDefaultLighting = YES;
    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin|ARSCNDebugOptionShowFeaturePoints;
}

- (void)setupSession {
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

//Called when a new node has been mapped to the given anchor
- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        return;
    }
    
    Plane *plane = [[Plane alloc] initWithAnchor:(ARPlaneAnchor *)anchor];
    [self.planes setObject:plane forKey:anchor.identifier];
    [node addChildNode:plane];
}

- (void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    Plane *plane = [self.planes objectForKey:anchor.identifier];
    
    if (plane == nil) {
        return;
    }
    
    [plane update:(ARPlaneAnchor *)anchor];
}

- (void)renderer:(id<SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    
    [self.planes removeObjectForKey:anchor.identifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - ARSCNViewDelegate

/*
// Override to create and configure nodes for anchors added to the view's session.
- (SCNNode *)renderer:(id<SCNSceneRenderer>)renderer nodeForAnchor:(ARAnchor *)anchor {
    SCNNode *node = [SCNNode new];
 
    // Add geometry to the node...
 
    return node;
}
*/

- (void)session:(ARSession *)session didFailWithError:(NSError *)error {
    // Present an error message to the user
    
}

- (void)sessionWasInterrupted:(ARSession *)session {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay
    
}

- (void)sessionInterruptionEnded:(ARSession *)session {
    // Reset tracking and/or remove existing anchors if consistent tracking is required
    
}

@end
