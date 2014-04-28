/**
* Pair of shaders for detecting edges in 
*/
module graphics.shaders.glsl.edgedetection;

package:

/// Vertex Shader which simply passes in the Texel for interpolation
immutable string edgedetectionVS = q{
#version 400
    
    layout(location = 0) in vec3 vPosition_s;
    layout(location = 1) in vec2 vUV;
    
    out vec2 fUV;
    
    void main( void )
    {
        gl_Position = vec4( vPosition_s, 1.0f );
        fUV = vUV;
    }
};

/// Fragment shader for edge detection used in Tabula Rasa
immutable string edgedetectionFS = q{
#version 400

    in vec2 fUV;

    uniform sampler2D normalTexture;
    uniform sampler2D depthTexture;
    uniform vec2 pixelOffsets; //x = 1 / Width, y = 1 / Height

    out float color;

    const vec2 offsets[9] = vec2[](
        vec2( 0.0, 0.0 ), //Center        0
        vec2( -1.0, 1.0 ), //Top Left     1
        vec2( 0.0, 1.0 ), //Top           2
        vec2( 1.0, 1.0 ), //Top Right     3
        vec2( 1.0, 0.0 ), //right         4
        vec2( 1.0, -1.0 ), //Bottom right 5
        vec2( 0.0, -1.0 ), //Bottom       6
        vec2( -1.0, -1.0 ), //Bottom left 7
        vec2( -1.0, 0.0 ) //left          8
    );

    // Function for decoding normals
    vec3 decode( vec2 enc )
    {
        float t = ( ( enc.x * enc.x ) + ( enc.y * enc.y ) ) / 4;
        float ti = sqrt( 1 - t );
        return vec3( ti * enc.x, ti * enc.y, -1 + t * 2 );
    }

    void main( void )
    {
        float depths[9];
        vec3 normals[9];

        for( int i = 0; i < 9; i++ )
        {
            vec2 uv = fUV;
            uv.x += offsets[i].x * pixelOffsets.x;
            uv.y += offsets[i].y * pixelOffsets.y;
            depths[i] = texture( depthTexture, uv ).x;
            normals[i] = decode( texture( normalTexture, uv ).xy );
        }

        vec4 deltas1;
        vec4 deltas2;
        deltas1.x = depths[1];
        deltas1.y = depths[2];
        deltas1.z = depths[3];
        deltas1.w = depths[4];
        deltas2.x = depths[5];
        deltas2.y = depths[6];
        deltas2.z = depths[7];
        deltas2.w = depths[8];

        //Compute gradients from center
        deltas1 = abs( deltas1 - depths[0] );
        deltas2 = abs( depths[0] - deltas2 );

        //Find min and max gradient, ensuring min != 0
        vec4 maxDeltas = max( deltas1, deltas2 );
        vec4 minDeltas = max( min( deltas1, deltas2 ), 0.00001 );

        // compare change in gradients, flagging ones that change significantly.
        // How severe the change must be to get flagged is a function of the minimum gradient.
        // It is not resolution dependent.  The constant number here would change based on how depth is stored
        // and how sensitive the edge detection should be.
        vec4 depthResults = step( minDeltas * 25, maxDeltas );

        // Compute change in cosine of the angle between normals
        deltas1.x = dot( normals[1], normals[0] );
        deltas1.y = dot( normals[2], normals[0] );
        deltas1.z = dot( normals[3], normals[0] );
        deltas1.w = dot( normals[4], normals[0] );
        deltas2.x = dot( normals[5], normals[0] );
        deltas2.y = dot( normals[6], normals[0] );
        deltas2.z = dot( normals[7], normals[0] );
        deltas2.w = dot( normals[8], normals[0] );
        deltas1 = abs( deltas1 - deltas2 );

        // Compare change in the cosine of the angles, flagging changes  
        // above some constant threshold. The cosine of the angle is not a  
        // linear function of the angle, so to have the flagging be  
        // independent of the angles involved, an arccos function would be required.  
        vec4 normalResults = step( 0.4, deltas1 );
        normalResults = max( normalResults, depthResults );
        color = ( normalResults.x + normalResults.y + normalResults.z + normalResults.w ) * .25;
    }
};