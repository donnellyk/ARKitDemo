import UIKit
import SceneKit
import ARKit

class MeasuringViewController : BaseARKitViewController {
  weak var label:UILabel!
  var originPoint:SphereNode?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupCrossHairs()
    setupTapGesture()
    setupLabel()
  }
}

extension MeasuringViewController {
  @objc func tapped(_ sender:AnyObject) {
    guard let result = currentCenterResult else {
      label.text = "Hit detection failed"
      return
    }

    if let origin = originPoint {
      let point = addNode(result, color: .blue)
      
      let position = SCNVector3.positionFrom(matrix: result.worldTransform)
      let distance = origin.position.distance(to: position)
      
      addLine(nodeA: origin, nodeB: point)
      label.text = "\(distance*100) cm"
    } else {
      originPoint = addNode(result, color: .red)
    }
    
  }
}

private extension MeasuringViewController {
  var currentCenterResult:ARHitTestResult? {
    let point = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
    if detectPlanes {
      return sceneView.hitTest(point, types: .existingPlaneUsingExtent).first
    } else {
      return sceneView.hitTest(point, types: .featurePoint).first
    }
  }
  
  func setupTapGesture() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
    tap.numberOfTapsRequired = 1
    
    sceneView.addGestureRecognizer(tap)
  }
  
  func setupCrossHairs() {
    let verticleView = UIView()
    verticleView.heightAnchor.constraint(equalToConstant: 15.0).isActive = true
    verticleView.widthAnchor.constraint(equalToConstant: 1.0).isActive = true
    verticleView.translatesAutoresizingMaskIntoConstraints = false
    verticleView.backgroundColor = .white
    
    view.addSubview(verticleView)
    verticleView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    verticleView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    
    let horizontalView = UIView()
    horizontalView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
    horizontalView.widthAnchor.constraint(equalToConstant: 15.0).isActive = true
    horizontalView.translatesAutoresizingMaskIntoConstraints = false
    horizontalView.backgroundColor = .white
    
    view.addSubview(horizontalView)
    horizontalView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    horizontalView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
  }
  
  func setupLabel() {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 24)
    label.textColor = .white
    label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    
    view.addSubview(label)
    label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    label.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
    
    self.label = label
  }
  
  func addNode(_ result: ARHitTestResult, color:UIColor) -> SphereNode {
    let position = SCNVector3.positionFrom(matrix: result.worldTransform)
    let point = SphereNode(position: position, color: color, size: 0.02)
    sceneView.scene.rootNode.addChildNode(point)
    return point
  }
  
  func addLine(nodeA: SCNNode, nodeB: SCNNode) {
    let positions: [Float32] = [nodeA.position.x, nodeA.position.y, nodeA.position.z, nodeB.position.x, nodeB.position.y, nodeB.position.z]
    let positionData = NSData(bytes: positions, length: MemoryLayout<Float32>.size*positions.count)
    let indices: [Int32] = [0, 1]
    let indexData = NSData(bytes: indices, length: MemoryLayout<Int32>.size * indices.count)
    
    let source = SCNGeometrySource(data: positionData as Data, semantic: .vertex, vectorCount: indices.count, usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: MemoryLayout<Float32>.size, dataOffset: 0, dataStride: MemoryLayout<Float32>.size * 3)
    let element = SCNGeometryElement(data: indexData as Data, primitiveType: .line, primitiveCount: indices.count, bytesPerIndex: MemoryLayout<Int32>.size)
    
    let line = SCNGeometry(sources: [source], elements: [element])
    
    sceneView.scene.rootNode.addChildNode(SCNNode(geometry: line))
  }
}
