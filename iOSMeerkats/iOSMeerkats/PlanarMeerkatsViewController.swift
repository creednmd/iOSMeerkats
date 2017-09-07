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


class PlanarMeerkatsViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    fileprivate var meerkats: [SCNNode] = []
    fileprivate var planes: [String : SCNNode] = [:]
    fileprivate var showPlanes: Bool = true
    fileprivate var mainPlane: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Plane Mapper"
        
        self.sceneView.antialiasingMode = .multisampling4X
        self.sceneView.delegate = self
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapScreen)))
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Hide Planes", style: .plain, target: self, action: #selector(tapTogglePlanes))
        
        self.configureWorldBottom()
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
    
    // MARK: - UI Events
    
    @IBAction func tapScreen(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.sceneView)
        
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let node = SCNScene(named: "art.scnassets/scaledMeerkat.scn")!.rootNode
        self.meerkats.append(node)
        addObject(node: node)
    }
    
    @objc private func tapTogglePlanes() {
        self.showPlanes = !self.showPlanes
        self.planes.values.forEach({ NodeGenerator.update(planeNode: $0, hidden: !self.showPlanes) })
        self.navigationItem.rightBarButtonItem?.title = self.showPlanes ? "Hide Planes" : "Show Planes"
    }
    
    // MARK: - Private Methods
    
    
    private func configureWorldBottom() {
        let bottomPlane = SCNBox(width: 1000, height: 0.005, length: 1000, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        bottomPlane.materials = [material]
        
        let bottomNode = SCNNode(geometry: bottomPlane)
        bottomNode.position = SCNVector3(x: 0, y: -10, z: 0)
        
        let physicsBody = SCNPhysicsBody.static()
        physicsBody.categoryBitMask = CollisionTypes.bottom.rawValue
        physicsBody.contactTestBitMask = CollisionTypes.shape.rawValue
        bottomNode.physicsBody = physicsBody
        
        self.sceneView.scene.rootNode.addChildNode(bottomNode)
        self.sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func addObject(node: SCNNode) {
        let worldTransform = mainPlane!.worldTransform
        let magicOffset: Float = -0.8
        let minZOffset: Float = -0.5
        let maxZOffset: Float = 0.5
        let minXOffset: Float =  -0.5
        let maxXOffset: Float = 0.5
        //node.position = SCNVector3Make(worldTransform.m31, worldTransform.m32, worldTransform.m33)
        node.position = mainPlane!.position
        node.position.y += magicOffset
        node.position.z = Float.random(min: minZOffset, max: maxZOffset)
        node.position.x = Float.random(min: minXOffset, max: maxXOffset)
        self.sceneView.scene.rootNode.addChildNode(node)
    }
}

extension PlanarMeerkatsViewController {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        let planeNode = NodeGenerator.generatePlaneFrom(planeAnchor: planeAnchor, physics: true, hidden: !self.showPlanes)
        node.addChildNode(planeNode)
        self.planes[key] = planeNode
        if self.mainPlane == nil {
            self.mainPlane = planeNode
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key] {
            NodeGenerator.update(planeNode: existingPlane, from: planeAnchor, hidden: !self.showPlanes)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = self.planes[key] {
            existingPlane.removeFromParentNode()
            self.planes.removeValue(forKey: key)
        }
    }
}

extension PlanarMeerkatsViewController {
    
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

struct CollisionTypes : OptionSet {
    let rawValue: Int
    
    static let bottom  = CollisionTypes(rawValue: 1 << 0)
    static let shape = CollisionTypes(rawValue: 1 << 1)
}


extension PlanarMeerkatsViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("updated anchor \(anchors)")
    }
}

extension Float {
    static func random(min: Float, max: Float) -> Float {
        let f = Float(arc4random()) / Float(UInt32.max)
        let d = max - min
        let off = f * d
        return min + off
    }
}


