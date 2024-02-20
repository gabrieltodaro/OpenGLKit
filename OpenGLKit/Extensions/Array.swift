//
//  Array.swift
//  OpenGLKit
//
//  Created by Gabriel Patané Todaro on 19/02/24.
//

import Foundation

extension Array {

	/*
	 An important subtlety here is that, in order to determine the memory occupied by an array, we need to add up the stride, not the size, of its constituent elements.
	 An element’s stride is, by definition, the amount of memory the element occupies when it is in an array. This can be larger than the element’s size because of padding, which is basically a technical term for “extra memory that we use up to keep the CPU happy.”
	 */
	func size() -> Int {
		return MemoryLayout<Element>.stride * self.count
	}
}
