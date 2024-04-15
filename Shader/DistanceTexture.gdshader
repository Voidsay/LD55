shader_type spatial;
render_mode unshaded;

uniform sampler2D tex;
uniform float far = 100;
uniform float near = 1;
uniform vec2 scale = vec2(1.0);

void fragment() {
	vec2 uv = UV * scale;
	vec3 world_camera = (INV_VIEW_MATRIX * vec4(vec3(0.0), 1.0)).xyz;
	vec4 a = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 col = texture(tex, uv).rgb;
	col.g = clamp((distance(a.xyz, world_camera) - near) / (far - near), 0.0, 1.0);
	ALBEDO = col;
}
