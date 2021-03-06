/**
* Post-Processing pass shader to render User Interfaces
*/
module dash.graphics.shaders.glsl.userinterface;
import dash.graphics.shaders.glsl;

package:

///
/// User interface shader
/// Just for transferring a texture (from awesomium) to the screen
///
immutable string userinterfaceVS = glslVersion ~ q{
    in vec3 vPosition;
    in vec2 vUV;

    out vec2 fUV;

    uniform mat4 worldProj;

    void main( void )
    {
        gl_Position = worldProj * vec4( vPosition, 1.0f );

        fUV = vUV;
    }
    
};

/// Put the texture on the screen.
immutable string userinterfaceFS = glslVersion ~ q{
    in vec2 fUV;

    out vec4 color;

    uniform sampler2D uiTexture;

    void main( void )
    {
        color = texture( uiTexture, fUV );
    }
    

};