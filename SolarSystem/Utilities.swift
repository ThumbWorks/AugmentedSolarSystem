/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility functions and type extensions used throughout the projects.
*/

import Foundation
import ARKit

// MARK: - Collection extensions
extension Array where Iterator.Element == CGFloat {
	var average: CGFloat? {
		guard !isEmpty else {
			return nil
		}
		
		var ret = self.reduce(CGFloat(0)) { (cur, next) -> CGFloat in
			var cur = cur
			cur += next
			return cur
		}
		let fcount = CGFloat(count)
		ret /= fcount
		return ret
	}
}

extension Array where Iterator.Element == SCNVector3 {
	var average: SCNVector3? {
		guard !isEmpty else {
			return nil
		}
		
		var ret = self.reduce(SCNVector3Zero) { (cur, next) -> SCNVector3 in
			var cur = cur
			cur.x += next.x
			cur.y += next.y
			cur.z += next.z
			return cur
		}
		let fcount = Float(count)
		ret.x /= fcount
		ret.y /= fcount
		ret.z /= fcount
		
		return ret
	}
}

extension RangeReplaceableCollection where IndexDistance == Int {
	mutating func keepLast(_ elementsToKeep: Int) {
		if count > elementsToKeep {
			self.removeFirst(count - elementsToKeep)
		}
	}
}

// MARK: - SCNNode extension

extension SCNNode {
	
	func setUniformScale(_ scale: Float) {
		self.scale = SCNVector3Make(scale, scale, scale)
	}
	
	func renderOnTop() {
		self.renderingOrder = 2
		if let geom = self.geometry {
			for material in geom.materials {
				material.readsFromDepthBuffer = false
			}
		}
		for child in self.childNodes {
			child.renderOnTop()
		}
	}
}

// MARK: - SCNVector3 extensions

extension SCNVector3 {
	
	init(_ vec: vector_float3) {
		self.x = vec.x
		self.y = vec.y
		self.z = vec.z
	}
	
	func length() -> Float {
		return sqrtf(x * x + y * y + z * z)
	}
	
	mutating func setLength(_ length: Float) {
		self.normalize()
		self *= length
	}
	
	mutating func setMaximumLength(_ maxLength: Float) {
		if self.length() <= maxLength {
			return
		} else {
			self.normalize()
			self *= maxLength
		}
	}
	
	mutating func normalize() {
		self = self.normalized()
	}
	
	func normalized() -> SCNVector3 {
		if self.length() == 0 {
			return self
		}
		
		return self / self.length()
	}
	
	static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
		return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
	}
	
	func friendlyString() -> String {
		return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)), \(String(format: "%.2f", z)))"
	}
	
	func dot(_ vec: SCNVector3) -> Float {
		return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
	}
	
	func cross(_ vec: SCNVector3) -> SCNVector3 {
		return SCNVector3(self.y * vec.z - self.z * vec.y, self.z * vec.x - self.x * vec.z, self.x * vec.y - self.y * vec.x)
	}
}

public let SCNVector3One: SCNVector3 = SCNVector3(1.0, 1.0, 1.0)

func SCNVector3Uniform(_ value: Float) -> SCNVector3 {
	return SCNVector3Make(value, value, value)
}

func SCNVector3Uniform(_ value: CGFloat) -> SCNVector3 {
	return SCNVector3Make(Float(value), Float(value), Float(value))
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
	left = left + right
}

func -= (left: inout SCNVector3, right: SCNVector3) {
	left = left - right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func /= (left: inout SCNVector3, right: Float) {
	left = left / right
}

func *= (left: inout SCNVector3, right: Float) {
	left = left * right
}

// MARK: - SCNMaterial extensions

extension SCNMaterial {
	
	static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
		let material = SCNMaterial()
		material.diffuse.contents = diffuse
		material.isDoubleSided = true
		if respondsToLighting {
			material.locksAmbientWithDiffuse = true
		} else {
			material.ambient.contents = UIColor.black
			material.lightingModel = .constant
			material.emission.contents = diffuse
		}
		return material
	}
}

// MARK: - CGPoint extensions

extension CGPoint {
	
	init(_ size: CGSize) {
		self.x = size.width
		self.y = size.height
	}
	
	init(_ vector: SCNVector3) {
		self.x = CGFloat(vector.x)
		self.y = CGFloat(vector.y)
	}
	
	func distanceTo(_ point: CGPoint) -> CGFloat {
		return (self - point).length()
	}
	
	func length() -> CGFloat {
		return sqrt(self.x * self.x + self.y * self.y)
	}
	
	func midpoint(_ point: CGPoint) -> CGPoint {
		return (self + point) / 2
	}
	
	func friendlyString() -> String {
		return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))"
	}
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
	left = left + right
}

func -= (left: inout CGPoint, right: CGPoint) {
	left = left - right
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x / right, y: left.y / right)
}

func * (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x * right, y: left.y * right)
}

func /= (left: inout CGPoint, right: CGFloat) {
	left = left / right
}

func *= (left: inout CGPoint, right: CGFloat) {
	left = left * right
}

// MARK: - CGSize extensions

extension CGSize {
	
	init(_ point: CGPoint) {
		self.width = point.x
		self.height = point.y
	}
	
	func friendlyString() -> String {
		return "(\(String(format: "%.2f", width)), \(String(format: "%.2f", height)))"
	}
}

func + (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width + right.width, height: left.height + right.height)
}

func - (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width - right.width, height: left.height - right.height)
}

func += (left: inout CGSize, right: CGSize) {
	left = left + right
}

func -= (left: inout CGSize, right: CGSize) {
	left = left - right
}

func / (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width / right, height: left.height / right)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width * right, height: left.height * right)
}

func /= (left: inout CGSize, right: CGFloat) {
	left = left / right
}

func *= (left: inout CGSize, right: CGFloat) {
	left = left * right
}

// MARK: - CGRect extensions

extension CGRect {
	
	var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}

func rayIntersectionWithHorizontalPlane(rayOrigin: SCNVector3, direction: SCNVector3, planeY: Float) -> SCNVector3? {
	
	let direction = direction.normalized()
	
	// Special case handling: Check if the ray is horizontal as well.
	if direction.y == 0 {
		if rayOrigin.y == planeY {
			// The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
			// Therefore we simply return the ray origin.
			return rayOrigin
		} else {
			// The ray is parallel to the plane and never intersects.
			return nil
		}
	}
	
	// The distance from the ray's origin to the intersection point on the plane is:
	//   (pointOnPlane - rayOrigin) dot planeNormal
	//  --------------------------------------------
	//          direction dot planeNormal
	
	// Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
	let dist = (planeY - rayOrigin.y) / direction.y

	// Do not return intersections behind the ray's origin.
	if dist < 0 {
		return nil
	}
	
	// Return the intersection point.
	return rayOrigin + (direction * dist)
}

// MARK: - Simple geometries

func createAxesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
	let quiverThickness = (quiverLength / 50.0) * quiverThickness
	let chamferRadius = quiverThickness / 2.0
	
	let xQuiverBox = SCNBox(width: quiverLength, height: quiverThickness, length: quiverThickness, chamferRadius: chamferRadius)
	xQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.red, respondsToLighting: false)]
	let xQuiverNode = SCNNode(geometry: xQuiverBox)
	xQuiverNode.position = SCNVector3Make(Float(quiverLength / 2.0), 0.0, 0.0)
	
	let yQuiverBox = SCNBox(width: quiverThickness, height: quiverLength, length: quiverThickness, chamferRadius: chamferRadius)
	yQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.green, respondsToLighting: false)]
	let yQuiverNode = SCNNode(geometry: yQuiverBox)
	yQuiverNode.position = SCNVector3Make(0.0, Float(quiverLength / 2.0), 0.0)
	
	let zQuiverBox = SCNBox(width: quiverThickness, height: quiverThickness, length: quiverLength, chamferRadius: chamferRadius)
	zQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.blue, respondsToLighting: false)]
	let zQuiverNode = SCNNode(geometry: zQuiverBox)
	zQuiverNode.position = SCNVector3Make(0.0, 0.0, Float(quiverLength / 2.0))
	
	let quiverNode = SCNNode()
	quiverNode.addChildNode(xQuiverNode)
	quiverNode.addChildNode(yQuiverNode)
	quiverNode.addChildNode(zQuiverNode)
	quiverNode.name = "Axes"
	return quiverNode
}

func createCrossNode(size: CGFloat = 0.01, color: UIColor = UIColor.green, horizontal: Bool = true, opacity: CGFloat = 1.0) -> SCNNode {
	
	// Create a size x size m plane and put a grid texture onto it.
	let planeDimension = size
	
	var fileName = ""
	switch color {
	case UIColor.blue:
		fileName = "crosshair_blue"
	case UIColor.yellow:
		fallthrough
	default:
		fileName = "crosshair_yellow"
	}
	
	let path = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "Models.scnassets")!
	let image = UIImage(contentsOfFile: path)
	
	let planeNode = SCNNode(geometry: createSquarePlane(size: planeDimension, contents: image))
	if let material = planeNode.geometry?.firstMaterial {
		material.ambient.contents = UIColor.black
		material.lightingModel = .constant
	}
	
	if horizontal {
		planeNode.eulerAngles = SCNVector3Make(Float.pi / 2.0, 0, Float.pi) // Horizontal.
	} else {
		planeNode.constraints = [SCNBillboardConstraint()] // Facing the screen.
	}
	
	let cross = SCNNode()
	cross.addChildNode(planeNode)
	cross.opacity = opacity
	return cross
}

func createSquarePlane(size: CGFloat, contents: AnyObject?) -> SCNPlane {
	let plane = SCNPlane(width: size, height: size)
	plane.materials = [SCNMaterial.material(withDiffuse: contents)]
	return plane
}

func createPlane(size: CGSize, contents: AnyObject?) -> SCNPlane {
	let plane = SCNPlane(width: size.width, height: size.height)
	plane.materials = [SCNMaterial.material(withDiffuse: contents)]
	return plane
}
