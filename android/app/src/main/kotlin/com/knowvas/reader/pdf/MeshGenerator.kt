package com.knowvas.reader.pdf

import android.graphics.PointF
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.nio.ShortBuffer

/**
 * MeshGenerator - Generates deformable grid meshes for page curl effects
 * 
 * This class creates a grid of vertices that can be deformed to create realistic
 * page curl animations. The mesh is generated with proper texture coordinates
 * and triangle indices for efficient OpenGL rendering.
 * 
 * Requirements: 3.1, 3.2, 3.4
 * 
 * @param gridWidth Number of vertices along the width (minimum 20)
 * @param gridHeight Number of vertices along the height (minimum 30)
 */
class MeshGenerator(
    private val gridWidth: Int = 20,
    private val gridHeight: Int = 30
) {
    companion object {
        private const val TAG = "MeshGenerator"
        private const val MIN_GRID_WIDTH = 20
        private const val MIN_GRID_HEIGHT = 30
    }
    
    init {
        require(gridWidth >= MIN_GRID_WIDTH) {
            "Grid width must be at least $MIN_GRID_WIDTH, got $gridWidth"
        }
        require(gridHeight >= MIN_GRID_HEIGHT) {
            "Grid height must be at least $MIN_GRID_HEIGHT, got $gridHeight"
        }
        
        Log.d(TAG, "MeshGenerator created with grid size: ${gridWidth}x${gridHeight}")
    }
    
    /**
     * Generate a deformable page mesh
     * 
     * Creates a grid mesh with the specified dimensions. The mesh is initially flat
     * and can be deformed later using curl mathematics.
     * 
     * Requirements: 3.1, 3.2, 3.4
     * 
     * @return PageMesh containing vertices, texture coordinates, and indices
     */
    fun generateMesh(): PageMesh {
        Log.d(TAG, "Generating mesh with ${gridWidth}x${gridHeight} vertices")
        
        val vertexCount = gridWidth * gridHeight
        val triangleCount = (gridWidth - 1) * (gridHeight - 1) * 2
        val indexCount = triangleCount * 3
        
        // Allocate arrays for mesh data
        val vertices = FloatArray(vertexCount * 3)  // x, y, z for each vertex
        val texCoords = FloatArray(vertexCount * 2) // u, v for each vertex
        val indices = ShortArray(indexCount)        // 3 indices per triangle
        
        // Generate vertices and texture coordinates
        // Requirements: 3.2 - Calculate vertex positions and texture coordinates
        var vertexIndex = 0
        var texCoordIndex = 0
        
        for (row in 0 until gridHeight) {
            for (col in 0 until gridWidth) {
                // Calculate normalized position (0 to 1)
                val u = col.toFloat() / (gridWidth - 1)
                val v = row.toFloat() / (gridHeight - 1)
                
                // Convert to normalized device coordinates (-1 to 1)
                // x: left (-1) to right (1)
                // y: bottom (-1) to top (1)
                val x = u * 2.0f - 1.0f
                val y = 1.0f - v * 2.0f  // Flip Y to match texture coordinates
                val z = 0.0f  // Initially flat
                
                // Store vertex position
                vertices[vertexIndex++] = x
                vertices[vertexIndex++] = y
                vertices[vertexIndex++] = z
                
                // Store texture coordinates
                // u: left (0) to right (1)
                // v: top (0) to bottom (1) - OpenGL texture coordinates
                texCoords[texCoordIndex++] = u
                texCoords[texCoordIndex++] = v
            }
        }
        
        // Generate triangle indices with counter-clockwise winding
        // Requirements: 3.4 - Generate triangle indices with correct winding order
        var indexPos = 0
        
        for (row in 0 until gridHeight - 1) {
            for (col in 0 until gridWidth - 1) {
                // Calculate vertex indices for the current quad
                val topLeft = (row * gridWidth + col).toShort()
                val topRight = (row * gridWidth + col + 1).toShort()
                val bottomLeft = ((row + 1) * gridWidth + col).toShort()
                val bottomRight = ((row + 1) * gridWidth + col + 1).toShort()
                
                // First triangle (counter-clockwise winding)
                // Top-left -> Bottom-left -> Bottom-right
                indices[indexPos++] = topLeft
                indices[indexPos++] = bottomLeft
                indices[indexPos++] = bottomRight
                
                // Second triangle (counter-clockwise winding)
                // Top-left -> Bottom-right -> Top-right
                indices[indexPos++] = topLeft
                indices[indexPos++] = bottomRight
                indices[indexPos++] = topRight
            }
        }
        
        Log.d(TAG, "Mesh generated: $vertexCount vertices, $triangleCount triangles")
        
        return PageMesh(
            vertices = vertices,
            texCoords = texCoords,
            indices = indices,
            vertexCount = vertexCount,
            gridWidth = gridWidth,
            gridHeight = gridHeight
        )
    }
    
    /**
     * Update mesh vertices with curl deformation
     * 
     * Applies cylindrical curl transformation to all mesh vertices using
     * the CurlMathematics class. Vertices inside the curl radius are deformed,
     * while vertices outside remain flat.
     * 
     * Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
     * 
     * @param mesh The mesh to update
     * @param curlParams Curl parameters (position, direction, radius, angle)
     */
    fun updateMeshWithCurl(mesh: PageMesh, curlParams: CurlParameters) {
        val curlMath = CurlMathematics()
        
        // Validate curl parameters
        if (!curlMath.validateCurlParameters(curlParams)) {
            Log.w(TAG, "updateMeshWithCurl: Invalid curl parameters, skipping update")
            return
        }
        
        // Apply curl transformation to each vertex
        var vertexIndex = 0
        for (i in 0 until mesh.vertexCount) {
            val x = mesh.vertices[vertexIndex]
            val y = mesh.vertices[vertexIndex + 1]
            val z = mesh.vertices[vertexIndex + 2]
            
            // Apply 3D curl transformation
            val transformed = curlMath.applyCurlToVertex3D(x, y, z, curlParams)
            
            // Update vertex position
            mesh.vertices[vertexIndex] = transformed[0]
            mesh.vertices[vertexIndex + 1] = transformed[1]
            mesh.vertices[vertexIndex + 2] = transformed[2]
            
            vertexIndex += 3
        }
        
        // Update the OpenGL vertex buffer with the new positions
        mesh.updateVertexBuffer()
        
        Log.d(TAG, "updateMeshWithCurl: Applied curl to ${mesh.vertexCount} vertices")
    }
}

/**
 * PageMesh - Represents a deformable page mesh
 * 
 * Contains all the data needed to render a page with OpenGL:
 * - Vertex positions (x, y, z)
 * - Texture coordinates (u, v)
 * - Triangle indices
 * 
 * Requirements: 3.1, 3.2, 3.4
 */
data class PageMesh(
    val vertices: FloatArray,      // x, y, z positions for each vertex
    val texCoords: FloatArray,     // u, v texture coordinates for each vertex
    val indices: ShortArray,       // Triangle indices (3 per triangle)
    val vertexCount: Int,          // Total number of vertices
    val gridWidth: Int,            // Number of vertices along width
    val gridHeight: Int            // Number of vertices along height
) {
    val triangleCount: Int get() = indices.size / 3
    
    // OpenGL buffers for efficient rendering
    private var vertexBuffer: FloatBuffer? = null
    private var texCoordBuffer: FloatBuffer? = null
    private var indexBuffer: ShortBuffer? = null
    
    /**
     * Get or create vertex buffer for OpenGL rendering
     */
    fun getVertexBuffer(): FloatBuffer {
        if (vertexBuffer == null) {
            vertexBuffer = ByteBuffer.allocateDirect(vertices.size * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer()
            vertexBuffer!!.put(vertices)
            vertexBuffer!!.position(0)
        }
        return vertexBuffer!!
    }
    
    /**
     * Get or create texture coordinate buffer for OpenGL rendering
     */
    fun getTexCoordBuffer(): FloatBuffer {
        if (texCoordBuffer == null) {
            texCoordBuffer = ByteBuffer.allocateDirect(texCoords.size * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer()
            texCoordBuffer!!.put(texCoords)
            texCoordBuffer!!.position(0)
        }
        return texCoordBuffer!!
    }
    
    /**
     * Get or create index buffer for OpenGL rendering
     */
    fun getIndexBuffer(): ShortBuffer {
        if (indexBuffer == null) {
            indexBuffer = ByteBuffer.allocateDirect(indices.size * 2)
                .order(ByteOrder.nativeOrder())
                .asShortBuffer()
            indexBuffer!!.put(indices)
            indexBuffer!!.position(0)
        }
        return indexBuffer!!
    }
    
    /**
     * Update vertex buffer with modified vertex data
     * 
     * Call this after modifying the vertices array to update the OpenGL buffer
     */
    fun updateVertexBuffer() {
        vertexBuffer?.let { buffer ->
            buffer.position(0)
            buffer.put(vertices)
            buffer.position(0)
        }
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false
        
        other as PageMesh
        
        if (!vertices.contentEquals(other.vertices)) return false
        if (!texCoords.contentEquals(other.texCoords)) return false
        if (!indices.contentEquals(other.indices)) return false
        if (vertexCount != other.vertexCount) return false
        if (gridWidth != other.gridWidth) return false
        if (gridHeight != other.gridHeight) return false
        
        return true
    }
    
    override fun hashCode(): Int {
        var result = vertices.contentHashCode()
        result = 31 * result + texCoords.contentHashCode()
        result = 31 * result + indices.contentHashCode()
        result = 31 * result + vertexCount
        result = 31 * result + gridWidth
        result = 31 * result + gridHeight
        return result
    }
}

// CurlParameters is defined in CurlParameters.kt
