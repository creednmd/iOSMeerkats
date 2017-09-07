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


class PlanarMeerkatsViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var errorBGView: UIVisualEffectView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!

    // MARK: - Properties
    
    fileprivate var meerkats: [SCNNode] = []
    fileprivate var planes: [String : SCNNode] = [:]
    fileprivate var showPlanes: Bool = true
    
    fileprivate var mainPlane: SCNNode?
    fileprivate var mainPlaneAnchor: ARPlaneAnchor?
    
    fileprivate var isErrorState = false {
        didSet {
            showErrorState()
        }
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Plane Mapper"
        
        // set this to get the initial state setup
        isErrorState = true

        sceneView.antialiasingMode = .multisampling4X
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapScreen)))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Hide Planes", style: .plain, target: self, action: #selector(tapTogglePlanes))
        
        configureWorldBottom()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    // MARK: - UI Events
    
    @IBAction func tapScreen(_ sender: UITapGestureRecognizer) {
        _ = sender.location(in: sceneView)
        
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
<<<<<<< Updated upstream
        let node = SCNScene(named: "art.scnassets/scaledMeerkat.scn")!.rootNode


        self.meerkats.append(node)
        addObject(node: node)
=======
        if let node = SCNScene(named: "art.scnassets/scaledMeerkat.scn")?.rootNode {
            meerkats.append(node)
            addObject(node: node)
        }
>>>>>>> Stashed changes
    }
    
    @objc private func tapTogglePlanes() {
        showPlanes = !showPlanes
        planes.values.forEach({ NodeGenerator.update(planeNode: $0, hidden: !showPlanes) })
        navigationItem.rightBarButtonItem?.title = showPlanes ? "Hide Planes" : "Show Planes"
    }
    
    @IBAction func settingsTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController else { return }
        present(vc, animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    
    private func startSession() {
        guard ARWorldTrackingConfiguration.isSupported else { return }
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    fileprivate func showErrorState() {
        errorBGView.isHidden = !isErrorState
        errorLabel.isHidden = !isErrorState
    }

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
        
        sceneView.scene.rootNode.addChildNode(bottomNode)
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func addObject(node: SCNNode) {
        guard let mainPlane = self.mainPlane else { return }
        let worldTransform = mainPlane.worldTransform
        let magicOffset: Float = -0.8
        
        let minZOffset: Float = -0.5
        let maxZOffset: Float = 0.5
        let minXOffset: Float =  -0.5
        let maxXOffset: Float = 0.5
        //node.position = SCNVector3Make(worldTransform.m31, worldTransform.m32, worldTransform.m33)
<<<<<<< Updated upstream
        node.position = mainPlane!.position
        node.position.y = mainPlaneAnchor!.transform.columns.3.y

        
        node.position.z = Float.random(min: minZOffset, max: maxZOffset)
        node.position.x = Float.random(min: minXOffset, max: maxXOffset)
        
        self.sceneView.scene.rootNode.addChildNode(node)
=======
        node.position = mainPlane.position
        node.position.y += magicOffset
        node.position.z = Float.random(min: minZOffset, max: maxZOffset)
        node.position.x = Float.random(min: minXOffset, max: maxXOffset)
        sceneView.scene.rootNode.addChildNode(node)
>>>>>>> Stashed changes
    }
}

// MARK: - ARSessionObserver

extension PlanarMeerkatsViewController: ARSessionObserver {
    
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
        isErrorState = message != nil
    }
}

// MARK: - SCNPhysicsContactDelegate

extension PlanarMeerkatsViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let mask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        guard CollisionTypes(rawValue: mask) == [CollisionTypes.bottom, CollisionTypes.shape] else { return }
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionTypes.bottom.rawValue {
            contact.nodeB.removeFromParentNode()
        }
        else {
            contact.nodeA.removeFromParentNode()
        }
    }

}

// MARK: - ARSCNViewDelegate

extension PlanarMeerkatsViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let key = planeAnchor.identifier.uuidString
        let planeNode = NodeGenerator.generatePlaneFrom(planeAnchor: planeAnchor, physics: true, hidden: !showPlanes)
        node.addChildNode(planeNode)
<<<<<<< Updated upstream
        self.planes[key] = planeNode
        if self.mainPlane == nil {
            self.mainPlane = planeNode
            self.mainPlaneAnchor = planeAnchor
=======
        planes[key] = planeNode
        if mainPlane == nil {
            mainPlane = planeNode
        }
        
        DispatchQueue.main.async {
            self.isErrorState = false
>>>>>>> Stashed changes
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let key = planeAnchor.identifier.uuidString
        if let existingPlane = planes[key] {
            NodeGenerator.update(planeNode: existingPlane, from: planeAnchor, hidden: !showPlanes)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let key = planeAnchor.identifier.uuidString
        guard let existingPlane = planes[key] else { return }
        existingPlane.removeFromParentNode()
        planes[key] = nil
    }
}

// MARK: - ARSessionDelegate

extension PlanarMeerkatsViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("updated anchor \(anchors)")
    }
}
