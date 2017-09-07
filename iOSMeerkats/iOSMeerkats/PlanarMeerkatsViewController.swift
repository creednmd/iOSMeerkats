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

enum Multiplier: Int {
    case first = 1
    case second = 2
    case third = 3
    
    init?(elapsedTime: Int) {
        switch elapsedTime {
        case let x where x >= 10:
            self = .second
        case let x where x >= 20:
            self = .third
        default:
            return nil
        }
    }
}

class PlanarMeerkatsViewController: UIViewController {
    
    // MARK: - Constants
    
    static let MAXMEERKATS = 50
    
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
    fileprivate var clippingFloor: SCNFloor?
    fileprivate var clippingFloorNode: SCNNode!
    fileprivate var timer: Timer?
    
    fileprivate var isErrorState = false {
        didSet {
            showErrorState()
        }
    }
    
    fileprivate var elapsedTime: TimeInterval = 0 {
        didSet {
            guard let multiplier = Multiplier(elapsedTime: Int(self.elapsedTime)) else { return }
            self.multiplier = multiplier.rawValue
        }
    }
    fileprivate var multiplier = 1
    fileprivate var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Plane Mapper"
        
        // set this to get the initial state setup
        isErrorState = true
        score = 0

        sceneView.antialiasingMode = .multisampling4X
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        
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
        if self.sceneView.scene.rootNode.childNodes.count > PlanarMeerkatsViewController.MAXMEERKATS {
            let alert = UIAlertController(title: "YOU LOST", message: "The meerkats have taken over. Way to go.", preferredStyle: .alert)
            let okay = UIAlertAction(title: "Okay", style: .default, handler: { (_) in
                fatalError()
            })
            alert.addAction(okay)
            self.present(alert, animated: true, completion: nil)
        }
        else {
            for _ in 0..<multiplier {
                guard let node = SCNScene(named: "art.scnassets/scaledMeerkat.scn")?.rootNode else { continue }
                meerkats.append(node)
                addObject(node: node)
            }
        }
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
    private func addClippingFloor() {
        self.clippingFloor = SCNFloor()
        
        self.clippingFloor?.reflectivity = 0
        self.clippingFloor?.materials.first?.isLitPerPixel = false
        self.clippingFloor?.materials.first?.colorBufferWriteMask = .alpha
        
        self.clippingFloorNode = SCNNode(geometry: self.clippingFloor)
        
        clippingFloorNode.renderingOrder = -1
        clippingFloorNode.position = self.mainPlane!.position
        clippingFloorNode.position.y = mainPlaneAnchor!.transform.columns.3.y

        
        self.sceneView.scene.rootNode.addChildNode(clippingFloorNode)
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
        
        let minZOffset: Float = -1.0
        let maxZOffset: Float = 0
        let minXOffset: Float =  -0.5
        let maxXOffset: Float = 0.5

        node.position = mainPlane.position
        node.position.y = mainPlaneAnchor!.transform.columns.3.y - 0.4

        node.position.z = Float.random(min: minZOffset, max: maxZOffset)
        node.position.x = Float.random(min: minXOffset, max: maxXOffset)
        
        var posNew = node.position
        posNew.y = mainPlaneAnchor!.transform.columns.3.y
        node.runAction(SCNAction.move(to: posNew, duration: 2.0)) {}

        node.runAction(SCNAction.rotate(by: 200, around: SCNVector3Make(0, 1, 0), duration: 100))
        
        sceneView.scene.rootNode.addChildNode(node)
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


extension PlanarMeerkatsViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        let hitResults = sceneView.hitTest(location, options: nil)
        guard let node = hitResults.first?.node else { return }
        handleTouchFor(node)
    }
    
    func handleTouchFor(_ node : SCNNode) {
        print("Remove Meerkat \(node)")
        guard node != self.clippingFloorNode else { return }
        guard node != self.sceneView.scene.rootNode else { return }
        Sounder.playSqueak()
        score += multiplier

        var posNew = node.position
        posNew.y -= 0.4
        node.runAction(SCNAction.move(to: posNew, duration: 2.0)) {
            node.removeFromParentNode()
        }
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
        planes[key] = planeNode
        if mainPlane == nil {
            mainPlane = planeNode
            mainPlaneAnchor = planeAnchor
            self.addClippingFloor()
            self.beginGame()
        }
        
        DispatchQueue.main.async {
            self.isErrorState = false
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
    
    func beginGame() {
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true, block: { _ in
                self.elapsedTime += 0.1
                self.tapScreen(UITapGestureRecognizer())
            })
        }
    }
}

// MARK: - ARSessionDelegate

extension PlanarMeerkatsViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("updated anchor \(anchors)")
    }
}

class Sounder {
    static func playSqueak() {
        let string = Bundle.main.path(forResource: "thing", ofType: "wav")!
        let url = URL(fileURLWithPath: string) as CFURL
        var effect: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url, &effect)
        AudioServicesPlaySystemSound(effect)
    }
}
