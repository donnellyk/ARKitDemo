import UIKit
import ARKit
import SceneKit

extension UIViewController {
  
}
class SimpleTrackingViewController : BaseARKitViewController {
  weak var trackingButton:UIButton!
  var isTracking:Bool = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupTrackingButton()
    detectPlanes = true
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    debugOptions = [ARSCNDebugOptions.showFeaturePoints]
  }
  
  @objc func trackingTapped(_ sender:AnyObject) {
    guard !busyView.isAnimating else {
      return
    }

    isTracking = !isTracking
    
    if isTracking {
      trackingButton.setTitle("Stop tracking", for: .normal)
    } else {
      trackingButton.setTitle("Start tracking", for: .normal)
    }
    
  }
  
  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    guard isTracking else {
      return
    }
    
    addPoint(fromTransform: frame.camera.transform)
  }
}

private extension SimpleTrackingViewController {
  func setupTrackingButton() {
    let trackingButton = UIButton()
    trackingButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(trackingButton)
    trackingButton.setTitle("Start tracking", for: .normal)
    trackingButton.addTarget(self, action: #selector(trackingTapped), for: .touchUpInside)
    
    trackingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    trackingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    
    self.trackingButton = trackingButton
  }
  
  func addPoint(fromTransform transform:matrix_float4x4) {
    let position = SCNVector3.positionFrom(matrix: transform)
    let point = SphereNode(position: position)
    sceneView.scene.rootNode.addChildNode(point)
  }
}
