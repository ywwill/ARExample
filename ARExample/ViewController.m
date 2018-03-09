//
//  ViewController.m
//  ARExample
//
//  Created by YangWei on 2018/3/8.
//  Copyright © 2018年 Apple-YangWei. All rights reserved.
//

#import "ViewController.h"
#import "Plane.h"

@interface ViewController () <ARSCNViewDelegate,UIGestureRecognizerDelegate,SCNPhysicsContactDelegate>

@property (nonatomic, strong) IBOutlet ARSCNView *sceneView;

@property (nonatomic, strong) NSMutableDictionary *planes; //存平面

@property (nonatomic, strong) NSMutableArray *boxes; // 存放正方体

@end

typedef NS_OPTIONS(NSInteger, CollisionCategory){
    CollisionCategoryBottom  = 1 << 0,
    CollisionCategoryCube    = 1 << 1,
};
    
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupScene];
    
    [self setupRecognizers];
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
    
    self.boxes = [NSMutableArray new];

    SCNScene *scene = [SCNScene new];

    // Set the scene to the view
    self.sceneView.scene = scene;
    self.sceneView.autoenablesDefaultLighting = YES;
    self.sceneView.debugOptions = ARSCNDebugOptionShowWorldOrigin|ARSCNDebugOptionShowFeaturePoints;
    
    //将一个大的节点放到虚拟世界的下面，当正方体爆炸掉落到这个节点上时，就将正方体移除
    SCNBox *bottomPlane = [SCNBox boxWithWidth:1000 height:0.5 length:1000 chamferRadius:0];
    SCNMaterial *bottomMaterial = [SCNMaterial new];
    bottomMaterial.diffuse.contents = [UIColor colorWithWhite:1.0 alpha:0.2];
    bottomPlane.materials = @[bottomMaterial];
    SCNNode *bottomNode = [SCNNode nodeWithGeometry:bottomPlane];
    bottomNode.position = SCNVector3Make(0, -10, 0);
    bottomNode.physicsBody = [SCNPhysicsBody
                              bodyWithType:SCNPhysicsBodyTypeKinematic
                              shape: nil];
    bottomNode.physicsBody.categoryBitMask = CollisionCategoryBottom;
    bottomNode.physicsBody.contactTestBitMask = CollisionCategoryCube;
    
    [self.sceneView.scene.rootNode addChildNode:bottomNode];
    self.sceneView.scene.physicsWorld.contactDelegate = self;
}

- (void)setupSession {
    // Create a session configuration
    ARWorldTrackingConfiguration *configuration = [ARWorldTrackingConfiguration new];
    
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    
    // Run the view's session
    [self.sceneView.session runWithConfiguration:configuration];
}

//设置手势
- (void)setupRecognizers {
    
    //单击插入一个正方体
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.sceneView addGestureRecognizer:tapGestureRecognizer];
    
    //一根手指长按清除正方体
    UILongPressGestureRecognizer *explosionGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHoldFrom:)];
    explosionGestureRecognizer.minimumPressDuration = 0.5;
    [self.sceneView addGestureRecognizer:explosionGestureRecognizer];
    
    //两根手指长按清除平面
    UILongPressGestureRecognizer *hidePlanesGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHidePlaneFrom:)];
    hidePlanesGestureRecognizer.minimumPressDuration = 1;
    hidePlanesGestureRecognizer.numberOfTouchesRequired = 2;
    [self.sceneView addGestureRecognizer:hidePlanesGestureRecognizer];
}

//单击方法
- (void)handleTapFrom: (UITapGestureRecognizer *)recognizer {
    //获取屏幕空间tap坐标，并将它传递给ARSCNView的hitTest方法
    CGPoint tapPoint = [recognizer locationInView:self.sceneView];
    
    NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:tapPoint types:ARHitTestResultTypeExistingPlaneUsingExtent];
    
    if (result.count == 0) {
        return;
    }
    
    // 插入正方体
    ARHitTestResult * hitResult = [result firstObject];
    [self insertGeometry:hitResult];
}

//一个手指长按方法
- (void)handleHoldFrom: (UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    //使用屏幕坐标执行 hit test，以查看是否点击了平面
    CGPoint holdPoint = [recognizer locationInView:self.sceneView];
    NSArray<ARHitTestResult *> *result = [self.sceneView hitTest:holdPoint types:ARHitTestResultTypeExistingPlaneUsingExtent];
    if (result.count == 0) {
        return;
    }
    
    //将正方体以爆炸的方式清除
    ARHitTestResult * hitResult = [result firstObject];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self explode:hitResult];
    });
}

//两个手指长按方法
- (void)handleHidePlaneFrom: (UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    //隐藏所有平面
    for(NSUUID *planeId in self.planes) {
        [self.planes[planeId] hide];
    }
    
    //停止检测或者更新存在的平面
    ARWorldTrackingConfiguration *configuration = (ARWorldTrackingConfiguration *)self.sceneView.session.configuration;
    configuration.planeDetection = ARPlaneDetectionNone;
    [self.sceneView.session runWithConfiguration:configuration];
}

// 插入正方体
- (void)insertGeometry:(ARHitTestResult *)hitResult {
    
    float dimension = 0.1;
    SCNBox *cube = [SCNBox boxWithWidth:dimension height:dimension length:dimension chamferRadius:0];
    SCNNode *node = [SCNNode nodeWithGeometry:cube];
    
    // SCNPhysicsBody告诉SceneKit这个几何图形应该被物理引擎操纵
    node.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
    node.physicsBody.mass = 2.0;
    node.physicsBody.categoryBitMask = CollisionCategoryCube;
    
    // 将几何图形略高于用户点击的点,这样就可以制造出正方体在平面上降落的效果
    float insertionYOffset = 0.5;
    node.position = SCNVector3Make(
                                   hitResult.worldTransform.columns[3].x,
                                   hitResult.worldTransform.columns[3].y + insertionYOffset,
                                   hitResult.worldTransform.columns[3].z
                                   );
    [self.sceneView.scene.rootNode addChildNode:node];
    [self.boxes addObject:node];
}

//爆炸的方法
- (void)explode:(ARHitTestResult *)hitResult {
    float explosionYOffset = 0.1;
    
    //取explosion在worldTransform的坐标
    SCNVector3 position = SCNVector3Make(
                                         hitResult.worldTransform.columns[3].x,
                                         hitResult.worldTransform.columns[3].y - explosionYOffset,
                                         hitResult.worldTransform.columns[3].z
                                         );
    
    //取每一个正方体的坐标，然后计算正方体和博炸点的距离
    for (SCNNode *cubeNode in self.boxes) {
        SCNVector3 distance = SCNVector3Make(cubeNode.worldPosition.x - position.x,
                                             cubeNode.worldPosition.y - position.y,
                                             cubeNode.worldPosition.z - position.z);
        
        float length = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z);
        
        //设置最大距离，当距离超过maxDistance后，便不会受到force的影响
        float maxDistance = 2;
        float scale = MAX(0, (maxDistance - length));
        
        scale = scale * scale * 2;
        
        // 将距离矢量缩放到合适的尺度
        distance.x = distance.x / length * scale;
        distance.y = distance.y / length * scale;
        distance.z = distance.z / length * scale;
        
        // 对几何图形施加一个force，将force设置到正方体的角使其旋转
        [cubeNode.physicsBody applyForce:distance atPosition:SCNVector3Make(0.05, 0.05, 0.05) impulse:YES];
    }
}

#pragma mark - ARSCNViewDelegate

- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    if (![anchor isKindOfClass:[ARPlaneAnchor class]]) {
        return;
    }
    
    Plane *plane = [[Plane alloc] initWithAnchor:(ARPlaneAnchor *)anchor isHidden:NO];
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

#pragma mark - SCNPhysicsContactDelegate

- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact{
//检测正方体和下面底部的碰撞，当正方体掉到了bottomNode下面，就移除正方体
    CollisionCategory contactMask = contact.nodeA.physicsBody.categoryBitMask | contact.nodeB.physicsBody.categoryBitMask;
    
    if (contactMask == (CollisionCategoryBottom | CollisionCategoryCube)) {
        if (contact.nodeA.physicsBody.categoryBitMask == CollisionCategoryBottom) {
            [contact.nodeB removeFromParentNode];
        } else {
            [contact.nodeA removeFromParentNode];
        }
    }
}

@end
