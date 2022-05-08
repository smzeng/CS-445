// Live autostereogram fragment shader
// CS 445 Final Project
// Michael Korenchan, Stacy Zeng, Surya Bandyopadhyay

uniform vec2 face_pos;  // uniform for face position (y component is currently mouse position)

// creates a 2x2 rotation matrix for a give angle
mat2x2 rot(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2x2(c, -s, s, c);
}

// describes the signed distance function to a box centered at (0,0,0)
// based on https://www.youtube.com/watch?v=62-pRVZuS5c
float sdf_box( vec3 point, vec3 dims ) {
  vec3 q = abs(point) - dims;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// describes the signed distance function to the scene, right now containing just a box
float sdf_scene(vec3 point) {
    mat2x2 rot_h = rot((face_pos.x+face_pos.y)/300.0);    // create rotation according to face position
    point.xz *= rot_h;                      			  // rotate box by rotating input point

    return sdf_box(point, vec3(0.3,0.3,0.3));
}

// perform ray marching to get distance to the scene
float rayMarch(vec3 start, vec3 dir) {
    vec3 curr_point = start;
    float total_dist = 0.0;
    
    // iterate until either too far or close enough to the scene
    while(true) {
        curr_point = start + dir*total_dist;
        float scene_dist = sdf_scene(curr_point);
        total_dist += scene_dist;
        if (scene_dist <= 0.001 || scene_dist >= 1000.0) {
            break;
        }
    }
    
    return total_dist;
}

float getDepth(vec2 frag_coord) {
    vec2 uv = (2.0*frag_coord - iResolution.xy) / iResolution.y; // get normalized coordinates
    vec3 cam_dir = normalize(vec3(uv.xy,-1.3));                  // image plane 1.3
    vec3 cam_pos = vec3(0.0,0.0,1.0);

    float depth = rayMarch(cam_pos, cam_dir);   // raymarch to get distance
    depth = 1.0-clamp(depth/1.5,0.0,1.0);       // adjust to range [0,1]

    return depth;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // initialize parameters
    float tile_width =  150.0; // repeat interval for zero depth
    float tile_height = 200.0; // repeat interval height-wise
    float max_offset =  40.0;  // maximum offset relative to repeat interval
     
    // initialize uv at current pixel position
    vec2 curr_coord = fragCoord.xy;
    // work backwards from current pixel position, computing dependent solutions of pixels to the left
    for(int i = 0; i < iResolution.x/tile_width; i++) {
        if(curr_coord.x < tile_width) break;                        // first column defines initial offset
        float depth = getDepth(curr_coord);                         // get depth from ray marching
        float backwards_offset = tile_width - (depth * max_offset); // depth at point gives previous solution location
        curr_coord.x -= backwards_offset;                           // goes backwards to previous column
    }
    vec2 sample_point = vec2(mod(curr_coord.x, tile_width), mod(curr_coord.y, tile_height)); // clamp sample point within texture bounds
    vec3 sample_color = texture( iChannel0, sample_point/vec2(tile_width, tile_height)).xyz; // sample texture with normalized coordinates
	fragColor = vec4(sample_color,1.0);
    
    // display depth map for reference
    float reference_size = 5;
    if (fragCoord.x < iResolution.x / reference_size && fragCoord.y < iResolution.y / reference_size) {
        fragColor = vec4(vec3(getDepth(fragCoord.xy * reference_size)),1.0);
    }
    
}
