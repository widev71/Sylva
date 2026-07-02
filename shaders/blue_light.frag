precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    // Deep focus / Night Shift filter
    // Significantly reduce blue light, slightly reduce green to warm the screen up.
    color.r *= 1.0;
    color.g *= 0.85;
    color.b *= 0.65;
    
    // Add a slight contrast boost for better readability in focus mode
    color.rgb = ((color.rgb - 0.5) * 1.05) + 0.5;
    
    gl_FragColor = color;
}
