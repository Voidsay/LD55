shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen: hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D colorpalet: repeat_disable, filter_nearest;
uniform float random: hint_range(0, 1);
uniform float scale1 = 5;
uniform float scale2 = 30;//Should be bigger than scale1
uniform vec2 offset;
uniform float timefactor;
uniform float minSize1;

struct voronoi{
	vec2 center;//center of circle
	float dist;//distance from center
	float radius;//maximum radius until touch
};

vec3 paletlookup(vec2 c){
	return texture(colorpalet, c).rgb;
}

vec2 randomPoint(vec2 p){
	vec3 a = fract(p.xyx * vec3(420.69, 123.45, 777.15));
	a += dot(a, a + 33.55);
	vec2 point = fract(vec2(a.x * a.y * a.z));
	float time = TIME * timefactor + 100.0;
	point.x = sin(point.x * time) * 0.5;
	point.y = cos(point.y * time) * 0.5;
	return point;
}

voronoi make_voronoi(vec2 uv, float scale, float rand, float aspectratio){
	voronoi output;
	float time = TIME * timefactor;
	uv *= scale;
	
	vec2 cellPosition = floor(uv);
	vec2 localPosition = uv - cellPosition;
	
	vec2 closestPoint;
	vec2 closestPointOffset;
	
	output.dist = 1000.0;//TODO should be infinity
	for(float j = -1.0; j <= 1.0; j++){
		for(float i = -1.0; i <= 1.0; i++){
			vec2 cellOffset = vec2(i, j);
			vec2 pointPosition = cellOffset + randomPoint(cellPosition + cellOffset)* rand;
			float distanceToPoint = distance(pointPosition, localPosition);
			if(distanceToPoint < output.dist){
				output.dist = distanceToPoint;
				closestPoint = pointPosition;
				closestPointOffset = cellOffset;
			}
		}
	}
	
	float minDistance2 = 1000.0;//TODO should be infinity
	vec2 closestPointToClosestPoint;
	for(float j = -1.0; j <= 1.0; j++){
		for(float i = -1.0; i <= 1.0; i++){
			if(i == 0.0 && j == 0.0){
				continue;
			}
			vec2 cellOffset = vec2(i, j) + closestPointOffset;
			vec2 pointPosition = cellOffset + randomPoint(cellPosition + cellOffset) * rand;
			float distanceToPoint = distance(closestPoint, pointPosition);
			if(distanceToPoint < minDistance2){
				minDistance2 = distanceToPoint;
				closestPointToClosestPoint = pointPosition;
			}
		}
	}
	
	output.radius = distance(closestPointToClosestPoint, closestPoint) / 2.0 / scale;
	output.center = vec2(cellPosition + closestPoint) / scale;
	output.dist /= scale;
	return output;
}

void vertex() {
	
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspectratio = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	uv.x *= aspectratio;
	uv += offset;
	
	//voronoi bigBubble = make_voronoi(uv, scale1, random, aspectratio);
	voronoi smallBubble = make_voronoi(uv, scale2, random, aspectratio);
	voronoi overlapCheck = make_voronoi(smallBubble.center, scale1, random, aspectratio);
	voronoi bigBubble = make_voronoi(uv, scale1, random, aspectratio);
	
	vec3 col;
	float mul;
	vec2 coord = bigBubble.center - offset;
	coord.x /= aspectratio;
	col = paletlookup(textureLod(screen, coord, 0.0).rg);
	mul = clamp(800.0 * (bigBubble.radius - bigBubble.dist), 0, 1);//light antialiasing
	if(distance(overlapCheck.center, smallBubble.center) > overlapCheck.radius + smallBubble.radius){//TODO bug circles still overlap
		if(smallBubble.radius - smallBubble.dist > 0.0){
			vec2 coord2 = smallBubble.center - offset;
			coord2.x /= aspectratio;
			col = paletlookup(textureLod(screen, coord2, 0.0).rg);
			mul = clamp(800.0 * (smallBubble.radius - smallBubble.dist), 0, 1);//light antialiasing
		}
	}
	col *= mul;
	
	COLOR = vec4(col, 1.0);
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
