shader_type spatial;
render_mode unshaded;

uniform vec3 color: source_color;
uniform float far = 100;
uniform float near = 1;

void fragment() {
	vec3 world_camera = (INV_VIEW_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
	vec4 a = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 col = color;
	col.g = clamp((distance(a.xyz, world_camera) - near) / (far - near), 0.0, 1.0);
	ALBEDO = col;
}
