//
//  GameViewController.swift
//  Folledo3DFighter
//
//  Created by Samuel Folledo on 12/21/17.
//  Copyright © 2017 Samuel Folledo. All rights reserved.
//

import UIKit
//import QuartzCore
import SceneKit

class GameViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode! //property for camera
    var spawnTime: TimeInterval = 0
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
        setupScene()
        setupCamera()
        spawnShape()
        
        setupHUD()
        
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    func setUpView() {
        scnView = self.view as! SCNView //cast self.view to a SCNView and store it in the scnView property so you don’t have to re-cast it every time you need to reference the view in Main.storyboard
        
        scnView.showsStatistics = true //showStatistics enables a real-time statistics panel at the bottom of your scene
        scnView.allowsCameraControl = false //allowsCameraControl lets you manually control the active camera through simple gestures. Single finger swipe, two finger swipe, two finger pinch, and double tap
        scnView.autoenablesDefaultLighting = true //autoenablesDefaultLighting creates a generic omnidirectional light in your scene so you don’t have to worry about adding your own light sources
        
        scnView.delegate = self //this sets the delegate of the SceneKit view to self. Now the view can call the delegate methods you implement in GameViewController when the render loop runs.
        
        scnView.isPlaying = true //forces the scenekit view into an endless playing mode
    }
    
    func setupScene() {
        scnScene = SCNScene() //creates a new blank instance of SCNScene and stores it in scnScene
        scnView.scene = scnScene //sets this blank scene as the one for scnView to use
        
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png" //sets background to an image selected from a folder
    }
    
    func setupCamera() {
        cameraNode = SCNNode() //First, you create an empty SCNNode and assign it to cameraNode.
        cameraNode.camera = SCNCamera() //Next, you create a new SCNCamera object and assign it to the camera property of cameraNode.
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10) //Then, you set the position of the camera.
        scnScene.rootNode.addChildNode(cameraNode) //Finally, you add cameraNode to the scene as a child node of the scene’s root node.
        
    }
    
    func spawnShape() {
        var geometry: SCNGeometry //create a placeholder geometry variable
        
        switch ShapeType.random() { //define a switch statement to handle the returned shape from ShapeType.random()
        case .box:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        case .sphere:
            geometry = SCNSphere(radius: 0.5)
        case .pyramid:
            geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case .torus:
            geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.25)
        case .capsule:
            geometry = SCNCapsule(capRadius: 0.3, height: 2.5)
        case .cylinder:
            geometry = SCNCylinder(radius: 0.3, height: 2.5)
        case .cone:
            geometry = SCNCone(topRadius: 0.25, bottomRadius: 0.5, height: 1.0)
        case .tube:
            geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1.0)
        //default: HAVE TO BE COMMENTED OUT AS DEFAULT WILL NEVER BE EXECUTED
            //geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0) //create an SCNBox object and store it in geometry. You specify the width, height and length, along with the chamfer radius (which is a fancy way of saying rounded corners)
        }
        let color = UIColor.random()//generates a random color and attaching it to geometry
        geometry.materials.first?.diffuse.contents = color//sets the random color created to the geometryNode
        
        let geometryNode = SCNNode(geometry: geometry) // you create an instance of SCNNode named geometryNode. This time, you make use of the SCNNode initializer which takes a geometry parameter to create a node and automatically attach the supplied geometry.
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil) //to add a physicsBody to the node with its specified type and shape
        
        //1 creates two random float values that represent the x- and y-components of the force
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        //2 use those random components to create a vector to represent this force
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        //3 creates another vector that represents the position to which the force will be applied. The position is slightly off-center so as to create a spin on the object.
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        //4 apply the force to geometryNode’s physics body using applyForce(direction: at: asImpulse:).
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        
        let trailEmitter = createTrail(color: color, geometry: geometry)//create a particle system
        geometryNode.addParticleSystem(trailEmitter)//attach it to the geometryNode
        
        if color == UIColor.black {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }
        
        scnScene.rootNode.addChildNode(geometryNode) //add the node
        //Dont forget to call it in the viewDidLoad()
    }
    
    func cleanScene() {
        //1 First, you simply create a little for loop that steps through all available child nodes within the root node of the scene.
        for node in scnScene.rootNode.childNodes {
            //2 Since the physics simulation is in play at this point, you can’t simply look at the object’s position as this reflects the position before the animation started. SceneKit maintains a copy of the object during the animation and plays it out until the animation is done. It’s a strange concept to understand at first, but you’ll see how this works before long. To get the actual position of an object while it’s animating, you leverage the presentationNode property. This is purely read-only — don’t attempt to modify any values on this property!
            if node.presentation.position.y < -2 {
                //3 This line of code makes an object blink out of existence; it seems cruel to do this to your children, but hey, that’s just tough love.
                node.removeFromParentNode()
            }
        }
    }//end of cleanScene method
    
    //1 defines createTrail(_: geometry:) which takes in color and geometry parameters to set up the particle system
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem{
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)! //2 loads the particle system from the file you created earlier
        trail.particleColor = color //3 modify the particle’s tint color based on the parameter passed in.
        trail.emitterShape = geometry //4 uses the geometry parameter to specify the emitter’s shape
        return trail //5 returns newly created particle system
    }//end of createTrail
    
    func setupHUD() { //func that takes advantage of the GameHelper.swift
        game.hudNode.position = SCNVector3(x:0.0, y:10.0, z:0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    func handleTouchFor(node: SCNNode) {//this func checks the touched node, update the score and lives
        if node.name == "GOOD"{
            game.score += 1
            createExplosion(geometry: node.geometry!,
                            position: node.presentation.position,
                            rotation: node.presentation.rotation)
            node.removeFromParentNode()
        } else if node.name == "BAD"{
            game.lives -= 1
            createExplosion(geometry: node.geometry!,
                            position: node.presentation.position,
                            rotation: node.presentation.rotation)
            node.removeFromParentNode()
        }
    }
    
    //touchesBegan
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first! //1 Grab the first available touch. There can be more than one if the player uses multiple fingers.
        let location = touch.location(in: scnView)//2 Translate the touch location to a location relative to the coordinates of scnView.
        let hitResults = scnView.hitTest(location, options: nil) //3 hitTest(_: options:) gives you an array of SCNHitTestResult objects that represent any intersections of the ray starting from the spot inside the view the user touched, and going away from the camera.
        if let result = hitResults.first {//4 Check the first result from the hit test.
            handleTouchFor(node: result.node)//5 pass the first result node to your touch handler, which either increase your score or cost you a life!
        }
    }
    
    //1 createExplosion(_: position: rotation:) takes three parameters: geometry defines the shape of the particle effect, while position and rotation help place the explosion into the scene.
    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation:SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explode.scnp", inDirectory: nil)! //2 This loads Explode.scnp and uses it to create an emitter. The emitter uses geometry as emitterShape so the particles will emit from the surface of the shape.
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        //3 Enter the Matrix! :] Don’t be scared by these three lines; they simply provide a combined rotation and position (or translation) transformation matrix to addParticleSystem(_: withTransform:).
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix) //4 call addParticleSystem(_: wtihTransform) on scnScene to add the explosion to the scene.
    }

}

//1 This adds an extension to GameViewController for protocol conformance and lets you maintain protocol methods in separate blocks of code.
extension GameViewController:SCNSceneRendererDelegate {
    //2 This adds an implementation of the renderer(_: updateAtTime:) protocol method.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //-1 You check if time (the current system time) is greater than spawnTime. If so, spawn a new shape; otherwise, do nothing.
        if time > spawnTime {
            //3 Finally, you call spawnShape() to create a new shape inside the delegate method.
            spawnShape()
            
            //-2 After you spawn an object, update spawnTime with the next time to spawn a new object. The next spawn time is simply the current time incremented by a random amount. Since TimeInterval is in seconds, you spawn the next object between 0.2 seconds and 1.5 seconds after the current time.
            spawnTime = time + TimeInterval(Float.random(min: 0.2, max:1.2))
        }
        
        game.updateHUD()
        
        cleanScene() //to remove the node
        //Before the view can call this delegate method, it first needs to know that GameViewController will act as the delegate for the view. Done by adding scnView.delegate = self to setUpView
    }
    
}
