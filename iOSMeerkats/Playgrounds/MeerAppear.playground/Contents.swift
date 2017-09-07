import UIKit
import SceneKit
import QuartzCore   // for the basic animation
import PlaygroundSupport


// create a scene view with an empty scene
var sceneView = SCNView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
var scene = SCNScene()
sceneView.scene = scene
PlaygroundPage.current.liveView = sceneView

// default lighting
sceneView.autoenablesDefaultLighting = true

// a camera
var cameraNode = SCNNode()
cameraNode.camera = SCNCamera()
cameraNode.position = SCNVector3(x: 0, y: 0, z: 10)
scene.rootNode.addChildNode(cameraNode)

// meerkat
let meerkatScene = SCNScene(named: "scaledMeerkat.scn")!
//let meerkatNode = meerkatScene.rootNode.childNode(withName: "meerkat", recursively: true)!
let meerkatNode = meerkatScene.rootNode.childNodes[0]
scene.rootNode.addChildNode(meerkatNode)

// set a rotation axis (no angle) to be able to
// use a nicer keypath below and avoid needing
// to wrap it in an NSValue
//meerkatNode?.rotation = SCNVector4(x: 1.0, y: 1.0, z: 0.0, w: 0.0)
//
//// animate the rotation of the torus
//var spin = CABasicAnimation(keyPath: "rotation.w") // only animate the angle
//spin.toValue = 2.0 * .pi
//spin.duration = 3
//spin.repeatCount = HUGE // for infinity
//meerkatNode?.addAnimation(spin, forKey: "spin around")

