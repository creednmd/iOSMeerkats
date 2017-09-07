//
//  ViewController.swift
//  iOSMeerkats
//
//  Created by Anthony Cohn-Richardby on 07/09/2017.
//  Copyright © 2017 Anthony Cohn-Richardby. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    // MARK: - Outlets
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var errorBGView: UIVisualEffectView!
    @IBOutlet weak var errorLabel: UILabel!

    // MARK: - Properties
    
    var isErrorState = false {
        didSet {
            showErrorState()
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Plane Mapper"
        
        self.sceneView.antialiasingMode = .multisampling4X
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapScreen)))
        
        // Create and set the scene
        if let scene = SCNScene(named: "art.scnassets/meerkat.dae") {
            sceneView.scene = scene
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if ARWorldTrackingSessionConfiguration.isSupported {
            let configuration = ARWorldTrackingSessionConfiguration()
            configuration.planeDetection = .horizontal
            self.sceneView.session.run(configuration)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.sceneView.session.pause()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startSession()
    }
    
    // MARK: - Private
    
    fileprivate func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    fileprivate func showErrorState() {
        errorBGView.isHidden = !isErrorState
        errorLabel.isHidden = !isErrorState
    }
    
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
    
    private func anyPlaneFrom(location:CGPoint, usingExtent:Bool = true) -> (SCNNode, SCNVector3, ARPlaneAnchor)? {
        let results = sceneView.hitTest(location,
                                        types: usingExtent ? ARHitTestResult.ResultType.existingPlaneUsingExtent : ARHitTestResult.ResultType.existingPlane)
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key] {
            existingPlane.removeFromParentNode()
            self.planes.removeValue(forKey: key)
        }
    }
}

extension ViewController {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let mask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        
        if CollisionTypes(rawValue: mask) == [CollisionTypes.bottom, CollisionTypes.shape] {
            if contact.nodeA.physicsBody!.categoryBitMask == CollisionTypes.bottom.rawValue {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
}

// MARK: - ARSCNViewDelegate

//extension ViewController: ARSCNViewDelegate {
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        //
//    }
//}

// MARK: - ARSessionObserver
extension ViewController: ARSessionObserver {
    
    func sessionWasInterrupted(_ session: ARSession) {
        errorLabel.text = "Session Interrupted!"
        isErrorState = true
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        startSession()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        errorLabel.text = "Failed! - \(error.localizedDescription)"
        isErrorState = true
        startSession()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var message: String? = nil
        
        switch camera.trackingState {
        case .notAvailable:
            message = "Tracking not available"
        case .limited(.initializing):
            message = "Initializing AR session"
        case .limited(.excessiveMotion):
            message = "Too much motion"
        case .limited(.insufficientFeatures):
            message = "Not enough surface details"
        default:
            isErrorState = false
            return
        }
        
        errorLabel.text = message
        isErrorState = true
    }
}

//extension ViewController: ARSession {
//    
//}

