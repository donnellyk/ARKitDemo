import Foundation
import ARKit
import SceneKit

// MARK: - BASE VIEW CONTROLLER
/// Simple view controller that implemented the base element needs to display ARKit
class BaseARKitViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
  private var currentPlanes:[UUID: PlaneNode] = [:]
  
  weak var sceneView: ARSCNView!
  weak var busyView:UIActivityIndicatorView!
  var debugOptions:SCNDebugOptions {
    get {
      return sceneView.debugOptions
    }
    set {
      sceneView.debugOptions = newValue
    }
  }
  @IBInspectable var detectPlanes = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupARView()
    setupBusyView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    let config = ARWorldTrackingConfiguration()
    if detectPlanes {
      config.planeDetection = .horizontal
    }
    
    sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    sceneView.session.delegate = self
    
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    sceneView.frame = view.bounds
  }

  
  func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    switch camera.trackingState {
    case .notAvailable, .limited:
      busyView.startAnimating()
    case .normal:
      busyView.stopAnimating()
    }
  }
  
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard detectPlanes, let planeAnchor = anchor as? ARPlaneAnchor else {
      return
    }
    
    let plane = PlaneNode(planeAnchor: planeAnchor)
    currentPlanes[planeAnchor.identifier] = plane
    node.addChildNode(plane)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    guard let plane = currentPlanes[anchor.identifier], let planeAnchor = anchor as? ARPlaneAnchor else {
      return
    }
    
    plane.update(anchor: planeAnchor)
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    currentPlanes.removeValue(forKey: anchor.identifier)
  }
}

private extension BaseARKitViewController {
  func setupARView() {
    let arView = ARSCNView(frame: .zero)
    arView.delegate = self
    
    view.addSubview(arView)
    sceneView = arView
  }
  
  func setupBusyView() {
    let busyView = UIActivityIndicatorView()
    busyView.translatesAutoresizingMaskIntoConstraints = false
    busyView.hidesWhenStopped = true
    busyView.startAnimating()
    busyView.activityIndicatorViewStyle = .whiteLarge
    view.addSubview(busyView)
    
    busyView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    busyView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    
    self.busyView = busyView
  }
}

// MARK: - SIMPLE SPHERE
class SphereNode: SCNNode {
  init(position: SCNVector3, color:UIColor = .red, size:CGFloat = 0.005) {
    super.init()
    let sphereGeometry = SCNSphere(radius: size)
    let material = SCNMaterial()
    material.diffuse.contents = color
    material.lightingModel = .physicallyBased
    sphereGeometry.materials = [material]
    self.geometry = sphereGeometry
    self.position = position
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

class PlaneNode : SCNNode {
  private var planeGeometry:SCNPlane
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(planeAnchor:ARPlaneAnchor) {
    self.planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
    super.init()

    let planeNode = SCNNode(geometry: planeGeometry)
    planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
    
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.gray.withAlphaComponent(0.4)
    material.lightingModel = .physicallyBased
    planeGeometry.materials = [material]

    addChildNode(planeNode)
  }
  
  func update(anchor:ARPlaneAnchor) {
    planeGeometry.width = CGFloat(anchor.extent.x);
    planeGeometry.height = CGFloat(anchor.extent.z);
    position = SCNVector3Make(anchor.center.x, 0, anchor.center.z);
  }
}

// MARK: - CALUCLATION HELPERS
extension SCNVector3 {
  func distance(to destination: SCNVector3) -> CGFloat {
    let dx = destination.x - x
    let dy = destination.y - y
    let dz = destination.z - z
    return CGFloat(sqrt(dx*dx + dy*dy + dz*dz))
  }
  
  static func positionFrom(matrix: matrix_float4x4) -> SCNVector3 {
    let column = matrix.columns.3
    return SCNVector3(column.x, column.y, column.z)
  }
}

