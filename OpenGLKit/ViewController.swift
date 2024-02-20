//
//  ViewController.swift
//  OpenGLKit
//
//  Created by Gabriel Patané Todaro on 17/02/24.
//

import GLKit

class ViewController: GLKViewController, GLKViewControllerDelegate {
	override func viewDidLoad() {
		super.viewDidLoad()
		setupGL()
	}

	deinit {
		tearDownGL()
	}

	private var context: EAGLContext?

	/*
	 Here, you are using the Vertex structure to create an array of vertices for drawing.
	 Then, you create an array of GLubyte values. GLubyte is just a type alias for good old UInt8, and this array specifies the order in which to draw each of the three vertices that make up a triangle.
	 That is, the first three integers (0, 1, 2) indicate to draw the first triangle by using the 0th, the 1st and, finally, the 2nd verex.
	 The second three integers (2, 3, 0) indicate to draw the second triangle by using the 2nd, the 3rd and then the 0th vertex.
	 */
	var Vertices = [
		Vertex(x:  1, y: -1, z: 0, r: 1, g: 0, b: 0, a: 1),
		Vertex(x:  1, y:  1, z: 0, r: 0, g: 1, b: 0, a: 1),
		Vertex(x: -1, y:  1, z: 0, r: 0, g: 0, b: 1, a: 1),
		Vertex(x: -1, y: -1, z: 0, r: 0, g: 0, b: 0, a: 1),
	]

	var Indices: [GLubyte] = [
		0, 1, 2,
		2, 3, 0
	]

	private var ebo = GLuint() // Element Buffer Object (EBO)
	private var vbo = GLuint() // Vertex Buffer Object (VBO)
	private var vao = GLuint() // Vertex Array Object (VAO)

	private var effect = GLKBaseEffect()
	private var rotation: Float = 0.0

}

// MARK: - Open GL methods
extension ViewController {
	/*
	 Calls glClearColor to specify the RGB and alpha (transparency) values to use when clearing the screen. You set it to a light gray, here.
	 Calls glClear to actually perform the clearing. There can be different types of buffers like the render/color buffer you’re displaying right now, and others like the depth or stencil buffers. Here you use the GL_COLOR_BUFFER_BIT flag to specify that you want to clear the current render/color buffer.
	 */
	override func glkView(_ view: GLKView, drawIn rect: CGRect) {
		// 1
		glClearColor(0.85, 0.85, 0.85, 1.0)
		// 2
		glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

		/*
		 That single line of code binds and compiles shaders for you, and it does it all behind the scenes without writing any GLSL or OpenGL code. Pretty cool, huh? Build your project to ensure it compiles.
		 */
		effect.prepareToDraw()
		glBindVertexArrayOES(vao)

		/*
		 glDrawElements() is the call to perform drawing and it takes four parameters. Here’s what each of them does:
		 1. This tells OpenGL what you want to draw. Here, you specify triangles by using the GL_TRIANGLES parameter cast as a GLenum.
		 2. Tells OpenGL how many vertices you want to draw. It’s cast to GLsizei since this is what the method expects.
		 3. Specifies the type of values contained in each index. You use GL_UNSIGNED_BYTE because Indices is an array of GLubyte elements.
		 4. Specifies an offset within a buffer. Since you’re using an EBO, this value is nil.
		 */
		glDrawElements(GLenum(GL_TRIANGLES),     // 1
					   GLsizei(Indices.count),   // 2
					   GLenum(GL_UNSIGNED_BYTE), // 3
					   nil)                      // 4
		glBindVertexArrayOES(0)
	}

	private func setupGL() {
		/*
		 1. To do anything with OpenGL, you need to create an EAGLContext.
		 2. Specifies that the rendering context that you just created is the one to use in the current thread.
		 3. This sets the GLKView’s context. After unwrapping the necessary variables, you set the GLKView‘s context to this OpenGL ES 3.0 context that you created.
		 4. This sets the current class (ViewController) as the GLKViewController’s delegate. Whenever state and logic updates need to occur, the glkViewControllerUpdate(_ controller:) method will get called.
		 */
		// 1
		context = EAGLContext(api: .openGLES3)
		// 2
		EAGLContext.setCurrent(context)

		if let view = self.view as? GLKView, let context = context {
			// 3
			view.context = context
			// 4
			delegate = self
		}

		/*
		 1. When you generate your buffers, you will need to specify information about how to read colors and positions from your data structures. OpenGL expects a GLuint for the color vertex attribute. Here, you use the GLKVertexAttrib enum to get the color attribute as a raw GLint. You then cast it to GLuint — what the OpenGL method calls expect — and store it for use in this method.
		 2. As with the color vertex attribute, you want to avoid having to write that long code to store and read the position attribute as a GLuint.
		 3. Here, you take advantage of the MemoryLayout enum to get the stride, which is the size, in bytes, of an item of type Vertex when in an array.
		 4. To get the memory offset of the variables corresponding to a vertex color, you use the MemoryLayout enum once again except, this time, you specify that you want the stride of a GLfloat multiplied by three. This corresponds to the x, y and z variables in the Vertex structure.
		 5. Finally, you need to convert the offset into the required type: UnsafeRawPointer.
		 */
		// 1
		let vertexAttribColor = GLuint(GLKVertexAttrib.color.rawValue)
		// 2
		let vertexAttribPosition = GLuint(GLKVertexAttrib.position.rawValue)
		// 3
		let vertexSize = MemoryLayout<Vertex>.stride
		// 4
		let colorOffset = MemoryLayout<GLfloat>.stride * 3
		// 5
		let colorOffsetPointer = UnsafeRawPointer(bitPattern: colorOffset)

		/*
		 1. The first line asks OpenGL to generate, or create, a new VAO. The method expects two parameters: The first one is the number of VAOs to generate — in this case one — while the second expects a pointer to a GLuint wherein it will store the ID of the generated object.
		 2. In the second line, you are telling OpenGL to bind the VAO you that created and stored in the vao variable and that any upcoming calls to configure vertex attribute pointers should be stored in this VAO. OpenGL will use your VAO until you unbind it or bind a different one before making draw calls.
		 */
		// 1
		glGenVertexArraysOES(1, &vao)
		// 2
		glBindVertexArrayOES(vao)

		/*
		 The call to glBufferData is where you’re passing all your vertex information to OpenGL. There are four parameters that this method expects:
		 1. Indicates to what buffer you are passing data.
		 2. Specifies the size, in bytes, of the data. In this case, you use the size() helper method on Array that you wrote earlier.
		 3. The actual data you are going to use.
		 4. Tells OpenGL how you want the GPU to manage the data. In this case, you use GL_STATIC_DRAW because the data you are passing to the graphics card will rarely change, if at all. This allows OpenGL to further optimize for a given scenario.
		 */
		glGenBuffers(1, &vbo)
		glBindBuffer(GLenum(GL_ARRAY_BUFFER), vbo)
		glBufferData(GLenum(GL_ARRAY_BUFFER), // 1
					 Vertices.size(),         // 2
					 Vertices,                // 3
					 GLenum(GL_STATIC_DRAW))  // 4

		/*
		 The call to glEnableVertexAttribArray enables the vertex attribute for position so that, in the next line of code, OpenGL knows that this data is for the position of your geometry.
		 glVertexAttribPointer takes six parameters so that OpenGL understands your data. This is what each parameter does:
		 1. Specifies the attribute name to set. You use the constants that you set up earlier in the method.
		 2. Specifies how many values are present for each vertex. If you look back up at the Vertex struct, you’ll see that, for the position, there are three GLfloat (x, y, z) and, for the color, there are four GLfloat (r, g, b, a).
		 3. Specifies the type of each value, which is float for both position and color.
		 4. Specifies if you want the data to be normalized. This is almost always set to false.
		 5. The size of the stride, which is a fancy way of saying “the size of the data structure containing the per-vertex data, when it’s in an array.” You pass vertexSize, here.
		 6. The offset of the position data. The position data is at the very start of the Vertices array, which is why this value is nil.
		 The second set of calls to glEnableVertexttribArray and glVertexAttribPointer are identical except that you specify that there are four components for color (r, g, b, a), and you pass a pointer for the offset of the color memory of each vertex in the Vertices array.
		 With your VBO and its data ready, it’s time to tell OpenGL about your indices by using the EBO. This will tell OpenGL what vertices to draw and in what order.
		 */
		glEnableVertexAttribArray(vertexAttribPosition)
		glVertexAttribPointer(vertexAttribPosition,       // 1
							  3,                          // 2
							  GLenum(GL_FLOAT),           // 3
							  GLboolean(UInt8(GL_FALSE)), // 4
							  GLsizei(vertexSize),        // 5
							  nil)                        // 6

		glEnableVertexAttribArray(vertexAttribColor)
		glVertexAttribPointer(vertexAttribColor,
							  4,
							  GLenum(GL_FLOAT),
							  GLboolean(UInt8(GL_FALSE)),
							  GLsizei(vertexSize),
							  colorOffsetPointer)

		glGenBuffers(1, &ebo)
		glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), ebo)
		glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER),
					 Indices.size(),
					 Indices,
					 GLenum(GL_STATIC_DRAW))

		glBindVertexArrayOES(0)
		glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
		glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
	}

	private func tearDownGL() {
		EAGLContext.setCurrent(context)

		glDeleteBuffers(1, &vao)
		glDeleteBuffers(1, &vbo)
		glDeleteBuffers(1, &ebo)

		EAGLContext.setCurrent(nil)

		context = nil
	}
}

extension ViewController {
	func glkViewControllerUpdate(_ controller: GLKViewController) {

		/*
		 1. Calculates the aspect ratio of the GLKView.
		 2. Uses a built-in helper function in the GLKit math library to create a perspective matrix; all you have to do is pass in the parameters discussed above. You set the near plane to four units away from the eye, and the far plane to 10 units away.
		 3. Sets the projection matrix on the effect’s transform property.
		 */
		// 1
		let aspect = fabsf(Float(view.bounds.size.width) / Float(view.bounds.size.height))
		// 2
		let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 4.0, 10.0)
		// 3
		effect.transform.projectionMatrix = projectionMatrix

		/*
		 1. The first thing you need to do is move the objects backwards. In the first line, you use the GLKMatrix4MakeTranslation function to create a matrix that translates six units backwards.
		 2. Next, you want to make the cube rotate. You increment an instance variable, which you’ll add in a second, that keeps track of the current rotation and use the GLKMatrix4Rotate method to change the current transformation by rotating it as well. It takes radians, so you use the GLKMathDegreesToRadians method for the conversion.
		 3. Finally, you set the model view matrix on the effect’s transform property.
		 */
		// 1
		var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -6.0)
		// 2
		rotation += 90 * Float(timeSinceLastUpdate)
		modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(rotation), 0, 0, 1)
		// 3
		effect.transform.modelviewMatrix = modelViewMatrix

	}
}
