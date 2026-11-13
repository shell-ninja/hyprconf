#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
    float mode;
    float sw;
    float sh;
    float fw;
    float fh;
    float lw;
    float lh;
    float glow;
    float lineW;
    float sdRange;
    float seed;
    vec4 cropOld;
    vec4 cropNew;
    vec4 ember;
    vec4 ink;
};

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
