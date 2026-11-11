shader_type canvas_item;

uniform vec4 tint_color : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

vec4 cubic(float v){
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 textureBicubic(sampler2D sampler, vec2 texCoords, float lod){
   vec2 texSize = vec2(textureSize(sampler, int(lod)));
   vec2 invTexSize = 1.0 / texSize;
   
   texCoords = texCoords * texSize - 0.5;

   
    vec2 fxy = fract(texCoords);
    texCoords -= fxy;

    vec4 xcubic = cubic(fxy.x);
    vec4 ycubic = cubic(fxy.y);

    vec4 c = texCoords.xxyy + vec2 (-0.5, +1.5).xyxy;
    
    vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
    vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;
    
    offset *= invTexSize.xxyy;
    
    vec4 sample0 = textureLod(sampler, offset.xz, lod);
    vec4 sample1 = textureLod(sampler, offset.yz, lod);
    vec4 sample2 = textureLod(sampler, offset.xw, lod);
    vec4 sample3 = textureLod(sampler, offset.yw, lod);

    float sx = s.x / (s.x + s.y);
    float sy = s.z / (s.z + s.w);

    return mix(
       mix(sample3, sample2, sx), mix(sample1, sample0, sx)
    , sy);
}

void fragment() {
    vec3 gammaColor = textureBicubic(TEXTURE, UV, 4.0).xyz;
    // ungamma (should be 2.2 but...)
    vec3 color = pow(gammaColor, vec3(2.0));
    // grayscale conversion
    float gray = dot(color, vec3(0.2126, 0.7152, 0.0722));
    // regamma
    float gammaGray = sqrt(gray);
	
	COLOR.rgb = vec3(gammaColor) * 0.5;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
