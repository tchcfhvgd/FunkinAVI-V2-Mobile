package backend.embeddedFiles;

/**
 * hardcoded shaders fragment code
 * 
 * @see [The Shadertoy page](https://shadertoy.com)
 */
enum abstract Shaders(String) from String to String
{

	var malfunctionBGEffect = 
	"
	 #pragma header
    
    uniform float iTime;
    #define iChannel0 bitmap
    #define iChannel1 bitmap
    #define iChannel2 bitmap
    #define iChannelResolution bitmap
    #define texture flixel_texture2D
    #define fragColor gl_FragColor
    #define mainImage main
    uniform float uTime;
    uniform vec4 iMouse;

	void mainImage()
{
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    vec2 iResolution = openfl_TextureSize;
    
    float POWER = 0.01; // How much the effect can spread horizontally
    float VERTICAL_SPREAD = 10.0; // How vertically is the sin wave spread
    float ANIM_SPEED = 0.1; // Animation speed
    
	vec2 uv = fragCoord.xy / iResolution.xy;
    float y = (uv.y + iTime * ANIM_SPEED) * VERTICAL_SPREAD;
    
    uv.x += ( 
        // This is the heart of the effect, feel free to modify
        // The sin functions here or add more to make it more complex 
        // and less regular
        sin(y) 
        + sin(y * 10.0) * 0.2 
        + sin(y * 50.0) * 0.03
    ) 
        * POWER // Limit by maximum spread
        * sin(uv.y * 3.14) // Disable on edges / make the spread a bell curve
        * sin(iTime); // And make the power change in time
    
	fragColor = texture(iChannel0, uv);
}
	";
	var freakyGlitch =
	"
	 #pragma header
    
    vec2 iResolution;
    uniform float iTime;
    #define iChannel0 bitmap
    #define iChannel1 bitmap
    #define iChannel2 bitmap
    #define iChannelResolution bitmap
    #define texture flixel_texture2D
    #define fragColor gl_FragColor
    #define mainImage main
    uniform float uTime;
    uniform vec4 iMouse;

	#define PI 3.14159265
#define TILE_SIZE 16.0

precision highp float;

float wow;
float Amount = 1.0;

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 posterize(vec3 color, float steps)
{
    return floor(color * steps) / steps;
}

float quantize(float n, float steps)
{
    return floor(n * steps) / steps;
}

vec4 downsample(sampler2D sampler, vec2 uv, float pixelSize)
{
    return texture(sampler, uv - mod(uv, vec2(pixelSize) / iResolution.xy));
}

float rand(float n)
{
    return fract(sin(n) * 43758.5453123);
}

float noise(float p)
{
    float fl = floor(p);
  	float fc = fract(p);
    return mix(rand(fl), rand(fl + 1.0), fc);
}

float rand(vec2 n) 
{ 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0,1.0)), rand(ip + vec2(1.0,1.0)), u.x), u.y);
    return res * res;
}

vec3 edge(sampler2D sampler, vec2 uv, float sampleSize)
{
    float dx = sampleSize / iResolution.x;
    float dy = sampleSize / iResolution.y;
    return (
    mix(downsample(sampler, uv - vec2(dx, 0.0), sampleSize), downsample(sampler, uv + vec2(dx, 0.0), sampleSize), mod(uv.x, dx) / dx) +
    mix(downsample(sampler, uv - vec2(0.0, dy), sampleSize), downsample(sampler, uv + vec2(0.0, dy), sampleSize), mod(uv.y, dy) / dy)    
    ).rgb / 2.0 - texture(sampler, uv).rgb;
}

vec3 distort(sampler2D sampler, vec2 uv, float edgeSize)
{
    vec2 pixel = vec2(1.0) / iResolution.xy;
    vec3 field = rgb2hsv(edge(sampler, uv, edgeSize));
    vec2 distort = pixel * sin((field.rb) * PI * 2.0);
    float shiftx = noise(vec2(quantize(uv.y + 31.5, iResolution.y / TILE_SIZE) * iTime, fract(iTime) * 300.0));
    float shifty = noise(vec2(quantize(uv.x + 11.5, iResolution.x / TILE_SIZE) * iTime, fract(iTime) * 100.0));
    vec3 rgb = texture(sampler, uv + (distort + (pixel - pixel / 2.0) * vec2(shiftx, shifty) * (50.0 + 100.0 * Amount)) * Amount).rgb;
    vec3 hsv = rgb2hsv(rgb);
    hsv.y = mod(hsv.y + shifty * pow(Amount, 5.0) * 0.25, 1.0);
    return posterize(hsv2rgb(hsv), floor(mix(256.0, pow(1.0 - hsv.z - 0.5, 2.0) * 64.0 * shiftx + 4.0, 1.0 - pow(1.0 - Amount, 5.0))));
}

void mainImage()
{
	vec2 uv = openfl_TextureCoordv.xy;
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    iResolution = openfl_TextureSize;
    Amount = uv.x; // Just erase this line if you want to use the control at the top
    wow = clamp(mod(noise(iTime + uv.y), 1.0), 0.0, 1.0) * 2.0 - 1.0;    
    vec3 finalColor;
    finalColor += distort(iChannel0, uv, 8.0);
    fragColor = vec4(finalColor, 1.0);
}
	";

    /**
     * Aberration shader
     * 
     * @param aberration aberration value
     * @param effectTime the effect time to set to the shader
     */
    var aberration =
    "
   #pragma header
    /*
    https://www.shadertoy.com/view/wtt3z2
    */

    uniform float aberration;
    uniform float effectTime;

    vec3 tex2D(sampler2D _tex,vec2 _p)
    {
        vec3 col=texture2D(_tex,_p).xyz;
        if(.5<abs(_p.x-.5)){
            col=vec3(.1);
        }
        return col;
    }

    void main() {
        vec2 uv = openfl_TextureCoordv; //openfl_TextureCoordv.xy*2. / openfl_TextureSize.xy-vec2(1.);
        vec2 ndcPos = uv * 2.0 - 1.0;
        float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
        
        //float u_angle = -2.4;
        
        float u_angle = -2.4 * sin(effectTime * 2.0);
        
        float eye_angle = abs(u_angle);
        float half_angle = eye_angle/2.0;
        float half_dist = tan(half_angle);

        vec2  vp_scale = vec2(aspect, 1.0);
        vec2  P = ndcPos * vp_scale; 
        
        float vp_dia = length(vp_scale);
        vec2  rel_P = normalize(P) / normalize(vp_scale);

        vec2 pos_prj = ndcPos;

        float beta = abs(atan((length(P) / vp_dia) * half_dist) * -abs(cos(effectTime - 0.25 + 0.5)));
        pos_prj = rel_P * beta / half_angle;

        vec2 uv_prj = (pos_prj * 0.5 + 0.5);

        vec2 trueAberration = aberration * pow((uv_prj.st - 0.5), vec2(3.0, 3.0));
        // vec4 texColor = tex2D(bitmap, uv_prj.st);
        gl_FragColor = vec4(
            texture2D(bitmap, uv_prj.st + trueAberration).r, 
            texture2D(bitmap, uv_prj.st).g, 
            texture2D(bitmap, uv_prj.st - trueAberration).b, 
            1.0
        );
    }
    ";

    /**
     * Shader which turns everything into black and white
     * 
     * no values needed
     */
    var grayScale = 
    "
   #pragma header
    
    #define fragColor gl_FragColor
    #define mainImage main

        void mainImage() {
            vec2 uv = openfl_TextureCoordv.xy;
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    vec2 iResolution = openfl_TextureSize;
            vec4 color = texture2D(bitmap, openfl_TextureCoordv);
            float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
            fragColor = vec4(vec3(gray), color.a);
        }
    ";

    /**
     * sets a glitch shader to the camera
     * 
     * @param time shader time
     * @param prob to be honest i don't know what does it do
     * @param vignetteIntensity intensity of the glitch, default is by 0.75
     */
    var vignetteGlitch =
    "
   // https://www.shadertoy.com/view/XtyXzW

    #pragma header

    uniform float time;
    uniform float prob;
    uniform float vignetteIntensity;

    float _round(float n) {
        return floor(n + .5);
    }

    vec2 _round(vec2 n) {
        return floor(n + .5);
    }

    vec3 tex2D(sampler2D _tex,vec2 _p)
    {
        vec3 col=texture2D(_tex,_p).xyz;
        if(.5<abs(_p.x-.5)){
            col=vec3(.1);
        }
        return col;
    }

    #define PI 3.14159265359
    #define PHI (1.618033988749895)

    // --------------------------------------------------------
    // Glitch core
    // --------------------------------------------------------

    float rand(vec2 co){
        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    }

    const float glitchScale = .5;

    vec2 glitchCoord(vec2 p, vec2 gridSize) {
        vec2 coord = floor(p / gridSize) * gridSize;;
        coord += (gridSize / 2.);
        return coord;
    }

    struct GlitchSeed {
        vec2 seed;
        float prob;
    };
        
    float fBox2d(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
    }

    GlitchSeed glitchSeed(vec2 p, float speed) {
        float seedTime = floor(time * speed);
        vec2 seed = vec2(
            1. + mod(seedTime / 100., 100.),
            1. + mod(seedTime, 100.)
        ) / 100.;
        seed += p; 
        return GlitchSeed(seed, prob);
    }

    float shouldApply(GlitchSeed seed) {
        return _round(
            mix(
                mix(rand(seed.seed), 1., seed.prob - .5),
                0.,
                (1. - seed.prob) * .5
            )
        );
    }

    // gamma again 
    const float GAMMA = 1.0;

    vec3 gamma(vec3 color, float g) {
        return pow(color, vec3(g));
    }

    vec3 linearToScreen(vec3 linearRGB) {
        return gamma(linearRGB, 1.0 / GAMMA);
    }

    // --------------------------------------------------------
    // Glitch effects
    // --------------------------------------------------------

    // Swap

    vec4 swapCoords(vec2 seed, vec2 groupSize, vec2 subGrid, vec2 blockSize) {
        vec2 rand2 = vec2(rand(seed), rand(seed+.1));
        vec2 range = subGrid - (blockSize - 1.);
        vec2 coord = floor(rand2 * range) / subGrid;
        vec2 bottomLeft = coord * groupSize;
        vec2 realBlockSize = (groupSize / subGrid) * blockSize;
        vec2 topRight = bottomLeft + realBlockSize;
        topRight -= groupSize / 2.;
        bottomLeft -= groupSize / 2.;
        return vec4(bottomLeft, topRight);
    }

    float isInBlock(vec2 pos, vec4 block) {
        vec2 a = sign(pos - block.xy);
        vec2 b = sign(block.zw - pos);
        return min(sign(a.x + a.y + b.x + b.y - 3.), 0.);
    }

    vec2 moveDiff(vec2 pos, vec4 swapA, vec4 swapB) {
        vec2 diff = swapB.xy - swapA.xy;
        return diff * isInBlock(pos, swapA);
    }

    void swapBlocks(inout vec2 xy, vec2 groupSize, vec2 subGrid, vec2 blockSize, vec2 seed, float apply) {
        
        vec2 groupOffset = glitchCoord(xy, groupSize);
        vec2 pos = xy - groupOffset;
        
        vec2 seedA = seed * groupOffset;
        vec2 seedB = seed * (groupOffset + .1);
        
        vec4 swapA = swapCoords(seedA, groupSize, subGrid, blockSize);
        vec4 swapB = swapCoords(seedB, groupSize, subGrid, blockSize);
        
        vec2 newPos = pos;
        newPos += moveDiff(pos, swapA, swapB) * apply;
        newPos += moveDiff(pos, swapB, swapA) * apply;
        pos = newPos;
        
        xy = pos + groupOffset;
    }


    // Static

    void staticNoise(inout vec2 p, vec2 groupSize, float grainSize, float contrast) {
        GlitchSeed seedA = glitchSeed(glitchCoord(p, groupSize), 5.);
        seedA.prob *= .5;
        if (shouldApply(seedA) == 1.) {
            GlitchSeed seedB = glitchSeed(glitchCoord(p, vec2(grainSize)), 5.);
            vec2 offset = vec2(rand(seedB.seed), rand(seedB.seed + .1));
            offset = _round(offset * 2. - 1.);
            offset *= contrast;
            p += offset;
        }
    }

    // --------------------------------------------------------
    // Glitch compositions
    // --------------------------------------------------------

    void glitchSwap(inout vec2 p) {
        vec2 pp = p;
        
        float scale = glitchScale;
        float speed = 5.;
        
        vec2 groupSize;
        vec2 subGrid;
        vec2 blockSize;    
        GlitchSeed seed;
        float apply;
        
        groupSize = vec2(.6) * scale;
        subGrid = vec2(2);
        blockSize = vec2(1);

        seed = glitchSeed(glitchCoord(p, groupSize), speed);
        apply = shouldApply(seed);
        swapBlocks(p, groupSize, subGrid, blockSize, seed.seed, apply);
        
        groupSize = vec2(.8) * scale;
        subGrid = vec2(3);
        blockSize = vec2(1);
        
        seed = glitchSeed(glitchCoord(p, groupSize), speed);
        apply = shouldApply(seed);
        swapBlocks(p, groupSize, subGrid, blockSize, seed.seed, apply);

        groupSize = vec2(.2) * scale;
        subGrid = vec2(6);
        blockSize = vec2(1);
        
        seed = glitchSeed(glitchCoord(p, groupSize), speed);
        float apply2 = shouldApply(seed);
        swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 1.), apply * apply2);
        swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 2.), apply * apply2);
        swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 3.), apply * apply2);
        swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 4.), apply * apply2);
        swapBlocks(p, groupSize, subGrid, blockSize, (seed.seed + 5.), apply * apply2);
        
        groupSize = vec2(1.2, .2) * scale;
        subGrid = vec2(9,2);
        blockSize = vec2(3,1);
        
        seed = glitchSeed(glitchCoord(p, groupSize), speed);
        apply = shouldApply(seed);
        swapBlocks(p, groupSize, subGrid, blockSize, seed.seed, apply);
    }

    void glitchStatic(inout vec2 p) {
        staticNoise(p, vec2(.5, .25/2.) * glitchScale, .2 * glitchScale, 2.);
    }


    void main() {
        // time = mod(time, 1.);
        float alpha = openfl_Alphav;
        vec2 p = openfl_TextureCoordv.xy;
        vec3 basecolor = texture2D(bitmap, openfl_TextureCoordv).rgb;
        
        glitchSwap(p);
        glitchStatic(p);

        vec3 color = texture2D(bitmap, p).rgb;

        float amount = (0.5 * sin(time * PI) + vignetteIntensity);
        float vignette = distance(openfl_TextureCoordv, vec2(0.5));
        //
        vignette = mix(1.0, 1.0 - amount, vignette);
        //
        gl_FragColor = vec4(mix(color.rgb, basecolor.rgb, vignette), 1.0);
    }
    ";

    /**
     * The truly overrated & overused Andromeda Engine shader, used for legacy songs
     * 
     * @param iTime the time to set to the shader
     * @param glitchModifier the glitch modifer to set to the shader
     * @param perspectiveOn sets a perspective to the shader
     * @param vignetteMoving sets if the shader's viggete should move
     * @param scanlinesOn sets if the scanlines are on
     * @param distortionOn sets if the shader should have distortion on
     */
    var andromedaVCR = 
    "
    #pragma header

    uniform float iTime;
    uniform bool vignetteOn;
    uniform bool perspectiveOn;
    uniform bool distortionOn;
    uniform bool scanlinesOn;
    uniform bool vignetteMoving;
   // uniform sampler2D noiseTex;
    uniform float glitchModifier;
    

    float onOff(float a, float b, float c)
    {
    	return step(c, sin(iTime + a*cos(iTime*b)));
    }

    float ramp(float y, float start, float end)
    {
    	float inside = step(start,y) - step(end,y);
    	float fact = (y-start)/(end-start)*inside;
    	return (1.-fact) * inside;

    }

    vec4 getVideo(vec2 uv)
      {
      	vec2 look = uv;
        if(distortionOn){
        	float window = 1./(1.+20.*(look.y-mod(iTime/4.,1.))*(look.y-mod(iTime/4.,1.)));
        	look.x = look.x + (sin(look.y*10. + iTime)/50.*onOff(4.,4.,.3)*(1.+cos(iTime*80.))*window)*(glitchModifier*2.0);
        	float vShift = 0.4*onOff(2.,3.,.9)*(sin(iTime)*sin(iTime*20.) +
        										 (0.5 + 0.1*sin(iTime*200.)*cos(iTime)));
        	look.y = mod(look.y + vShift*glitchModifier, 1.);
        }
      	vec4 video = flixel_texture2D(bitmap,look);

      	return video;
      }

    vec2 screenDistort(vec2 uv)
    {
      if(perspectiveOn){
        uv = (uv - 0.5) * 2.0;
      	uv *= 1.1;
      	uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
      	uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
      	uv  = (uv / 2.0) + 0.5;
      	uv =  uv *0.92 + 0.04;
      	return uv;
      }
    	return uv;
    }
    float random(vec2 uv)
    {
     	return fract(sin(dot(uv, vec2(15.5151, 42.2561))) * 12341.14122 * sin(iTime * 0.03));
    }
    float noise(vec2 uv)
    {
     	vec2 i = floor(uv);
        vec2 f = fract(uv);

        float a = random(i);
        float b = random(i + vec2(1.,0.));
    	float c = random(i + vec2(0., 1.));
        float d = random(i + vec2(1.));

        vec2 u = smoothstep(0., 1., f);

        return mix(a,b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;

    }


    vec2 scandistort(vec2 uv) {
    	float scan1 = clamp(cos(uv.y * 2.0 + iTime), 0.0, 1.0);
    	float scan2 = clamp(cos(uv.y * 2.0 + iTime + 4.0) * 10.0, 0.0, 1.0) ;
    	float amount = scan1 * scan2 * uv.x;

    	//uv.x -= 0.05 * mix(flixel_texture2D(noiseTex, vec2(uv.x, amount)).r * amount, amount, 0.9);

    	return uv;

    }
    void main()
    {
    	vec2 iResolution = openfl_TextureSize;
    	vec2 uv = openfl_TextureCoordv;
      vec2 curUV = screenDistort(uv);
    	uv = scandistort(curUV);
    	vec4 video = getVideo(uv);
      float vigAmt = 1.0;
      float x =  0.;


      video.r = getVideo(vec2(x+uv.x+0.001,uv.y+0.001)).x+0.05;
      video.g = getVideo(vec2(x+uv.x+0.000,uv.y-0.002)).y+0.05;
      video.b = getVideo(vec2(x+uv.x-0.002,uv.y+0.000)).z+0.05;
      video.r += 0.08*getVideo(0.75*vec2(x+0.025, -0.027)+vec2(uv.x+0.001,uv.y+0.001)).x;
      video.g += 0.05*getVideo(0.75*vec2(x+-0.022, -0.02)+vec2(uv.x+0.000,uv.y-0.002)).y;
      video.b += 0.08*getVideo(0.75*vec2(x+-0.02, -0.018)+vec2(uv.x-0.002,uv.y+0.000)).z;

      video = clamp(video*0.6+0.4*video*video*1.0,0.0,1.0);
      if(vignetteMoving)
    	  vigAmt = 3.+.3*sin(iTime + 5.*cos(iTime*5.));

    	float vignette = (1.-vigAmt*(uv.y-.5)*(uv.y-.5))*(1.-vigAmt*(uv.x-.5)*(uv.x-.5));

      if(vignetteOn)
    	 video *= vignette;


      gl_FragColor = mix(video,vec4(noise(uv * 75.)),.05);

      if(curUV.x<0.0 || curUV.x>1.0 || curUV.y<0.0 || curUV.y>1.0){
        gl_FragColor = vec4(0.0,0.0,0.0,0.0);
      }

    }
    ";
    
    /**
     * Ditto as ```aberration```, but it doesn't have ```effectTime``` meaning that it does not have a zoom on it
     * 
     * @param rOffset the red color offset to set
     * @param gOffset same as ```rOffset``` but green
     * @param bOffset same as ```rOffset``` but blue
     */
    var aberrationDefault = 
    "
    #pragma header

    uniform float rOffset;
    uniform float gOffset;
    uniform float bOffset;

    void main()
    {
        vec4 col1 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(rOffset, 0.0));
        vec4 col2 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(gOffset, 0.0));
        vec4 col3 = texture2D(bitmap, openfl_TextureCoordv.st - vec2(bOffset, 0.0));
        vec4 toUse = texture2D(bitmap, openfl_TextureCoordv);
        toUse.r = col1.r;
        toUse.g = col2.g;
        toUse.b = col3.b;
        //float someshit = col4.r + col4.g + col4.b;

        gl_FragColor = toUse;
    }
    ";

    /**
     * **Modified version of a tilt shift shader from Martin Jonasson (http://grapefrukt.com/)**
     * 
     * Sets a Tilt Shift shader which is also declarated as a Blur shader
     * 
     * @param bluramount the blur amount to set
     * @param center how centered the shader should be
     * @param steps steps to set
     * @param stepSize sets the ```steps``` value size
     */
    var tiltShift =
    "
    #pragma header

		// Modified version of a tilt shift shader from Martin Jonasson (http://grapefrukt.com/)
		// Read http://notes.underscorediscovery.com/ for context on shaders and this file
		// License : MIT
		 
			/*
				Take note that blurring in a single pass (the two for loops below) is more expensive than separating
				the x and the y blur into different passes. This was used where bleeding edge performance
				was not crucial and is to illustrate a point. 
		 
				The reason two passes is cheaper? 
				   texture2D is a fairly high cost call, sampling a texture.
		 
				   So, in a single pass, like below, there are 3 steps, per x and y. 
		 
				   That means a total of 9 'taps', it touches the texture to sample 9 times.
		 
				   Now imagine we apply this to some geometry, that is equal to 16 pixels on screen (tiny)
				   (16 * 16) * 9 = 2304 samples taken, for width * height number of pixels, * 9 taps
				   Now, if you split them up, it becomes 3 for x, and 3 for y, a total of 6 taps
				   (16 * 16) * 6 = 1536 samples
			
				   That\'s on a *tiny* sprite, let\'s scale that up to 128x128 sprite...
				   (128 * 128) * 9 = 147,456
				   (128 * 128) * 6 =  98,304
		 
				   That\'s 33.33..% cheaper for splitting them up.
				   That\'s with 3 steps, with higher steps (more taps per pass...)
		 
				   A really smooth, 6 steps, 6*6 = 36 taps for one pass, 12 taps for two pass
				   You will notice, the curve is not linear, at 12 steps it\'s 144 vs 24 taps
				   It becomes orders of magnitude slower to do single pass!
				   Therefore, you split them up into two passes, one for x, one for y.
			*/
		 
		// I am hardcoding the constants like a jerk
			
		uniform float bluramount;
		uniform float center;
		const float stepSize    = 0.004;
		const float steps       = 3.0;
		 
		const float minOffs     = (float(steps-1.0)) / -2.0;
		const float maxOffs     = (float(steps-1.0)) / +2.0;
		 
		void main() {
			float amount;
			vec4 blurred;
				
			// Work out how much to blur based on the mid point 
			amount = pow((openfl_TextureCoordv.y * center) * 2.0 - 1.0, 2.0) * bluramount;
				
			// This is the accumulation of color from the surrounding pixels in the texture
			blurred = vec4(0.0, 0.0, 0.0, 1.0);
				
			// From minimum offset to maximum offset
			for (float offsX = minOffs; offsX <= maxOffs; ++offsX) {
				for (float offsY = minOffs; offsY <= maxOffs; ++offsY) {
		 
					// copy the coord so we can mess with it
					vec2 temp_tcoord = openfl_TextureCoordv.xy;
		 
					//work out which uv we want to sample now
					temp_tcoord.x += offsX * amount * stepSize;
					temp_tcoord.y += offsY * amount * stepSize;
		 
					// accumulate the sample 
					blurred += texture2D(bitmap, temp_tcoord);
				}
			} 
				
			// because we are doing an average, we divide by the amount (x AND y, hence steps * steps)
			blurred /= float(steps * steps);
		 
			// return the final blurred color
			gl_FragColor = blurred;
		}
    ";

    /**
     * Sets a bloom shader made by BBPanzu
     * 
     * @param amount the amount of the bloom
     * @param Directions The directions of the shader
     * @param Quality the quality to set
     * @param Size the bloom shader size 
     */
    var bloom =
    "
    #pragma header
    
    uniform float iTime;
    #define iChannel0 bitmap
    #define iChannel1 bitmap
    #define iChannel2 bitmap
    #define iChannelResolution bitmap
    #define texture flixel_texture2D
    #define fragColor gl_FragColor
    #define mainImage main
    uniform float uTime;
    uniform vec4 iMouse;

    //BLOOM SHADER BY BBPANZU

    const float amount = 1.0;

    // GAUSSIAN BLUR SETTINGS
    float dim = 1.8;
    float Directions = 20.0;
    float Quality = 20.0; 
    float Size = 20.0; 

    void mainImage()
    { 
        vec2 uv = openfl_TextureCoordv.xy;
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    vec2 iResolution = openfl_TextureSize;
    vec2 Radius = Size/openfl_TextureSize.xy;

    float Pi = 6.28318530718; // Pi*2
        
    vec4 Color = texture2D( bitmap, uv);
    
    for( float d=0.0; d<Pi; d+=Pi/Directions){
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality){
    float ex = (cos(d)*Size*i)/openfl_TextureSize.x;
    float why = (sin(d)*Size*i)/openfl_TextureSize.y;

    Color += flixel_texture2D( bitmap, uv+vec2(ex,why));	
        }
    }
        
    Color /= (dim * Quality) * Directions - 15.0;
    vec4 bloom =  (flixel_texture2D( bitmap, uv)/ dim)+Color;

    gl_FragColor = bloom;

    }
    ";

	// gaussian bloom shader but no lag yay
    @:noCompletion var bloom_alt = 
    "
    #pragma header
    
    uniform float iTime;
    #define iChannel0 bitmap
    #define iChannel1 bitmap
    #define iChannel2 bitmap
    #define iChannelResolution bitmap
    #define texture flixel_texture2D
    #define fragColor gl_FragColor
    #define mainImage main
    uniform float uTime;
    uniform vec4 iMouse;

   void mainImage()
{
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
    vec2 iResolution = openfl_TextureSize;
    float Pi = 6.28318530718;
    
    //Gaussian blur settings
    float Directions = 30.0;
    float Quality = 6.0;
    float Size = 4.0;
    
    // Sample the input texture
    
    // Stupid guassian setup shit
    vec2 Radius = Size/iResolution.xy;
    vec2 uv = fragCoord/iResolution.xy;
    vec4 color = texture(iChannel0, uv);

    // Calcuate shitty blur
    for(float d=0.0; d<Pi; d+=Pi/Directions)
    {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
        {
            float ex = (cos(d)*Size*i)/iResolution.x;
            float why = (sin(d)*Size*i)/iResolution.y;
            color += texture(iChannel0, uv+vec2(ex,why));
        }
    }
    
    color /= (1.0 * Quality) * Directions - 15.0;
    
    // Calculate the bloom effect
    vec3 blur = vec3(-1.0);
    for (int i = -4; i <= 4; i++) {
        blur += texture(iChannel0, (fragCoord + vec2(i, 1.0))/iResolution.xy).rgb;
        blur += texture(iChannel0, (fragCoord + vec2(1.0, i))/iResolution.xy).rgb;
    }
    blur /= 50.0;
    
    vec3 bloom = mix(color.rgb, blur, 0.75);

    // Apply the glow effect
    vec3 glow = vec3(1.0) - exp(-bloom);
    fragColor = vec4(glow + bloom, color.a);
}
    ";

    /*
    * Filter used for Credits Menu
    */
    var filter1990 =
    "
    #pragma header
    
	uniform float iTime;
	#define iChannel0 bitmap
	#define iChannel1 bitmap
	#define iChannel2 bitmap
	#define iChannelResolution bitmap
	#define texture flixel_texture2D
	#define fragColor gl_FragColor
	#define mainImage main
	uniform float uTime;
	uniform vec4 iMouse;
	
	#define V vec2(0.,1.)
	#define PI 3.14159265
	#define HUGE 1E9
	#define VHSRES vec2(1280.0,720.0)
	#define saturate(i) clamp(i,0.,1.)
	#define lofi(i,d) floor(i/d)*d
	#define validuv(v) (abs(v.x-0.5)<0.5&&abs(v.y-0.5)<0.5)
	
	float v2random( vec2 uv ) {
	  return texture( iChannel1, mod( uv, vec2( 1.0 ) ) ).x;
	}
	
	mat2 rotate2D( float t ) {
	  return mat2( cos( t ), sin( t ), -sin( t ), cos( t ) );
	}
	
	vec3 rgb2yiq( vec3 rgb ) {
	  return mat3( 0.299, 0.596, 0.211, 0.587, -0.274, -0.523, 0.114, -0.322, 0.312 ) * rgb;
	}
	
	vec3 yiq2rgb( vec3 yiq ) {
	  return mat3( 1.000, 1.000, 1.000, 0.956, -0.272, -1.106, 0.621, -0.647, 1.703 ) * yiq;
	}
	
	#define SAMPLES 6
	
	vec3 vhsTex2D( vec2 uv, float rot ) {
	  if ( validuv( uv ) ) {
	    vec3 yiq = vec3( 0.0 );
	    for ( int i = 0; i < SAMPLES; i ++ ) {
	      yiq += (
	        rgb2yiq( texture( iChannel0, uv - vec2( float( i ), 0.0 ) / VHSRES ).xyz ) *
	        vec2( float( i ), float( SAMPLES - 1 - i ) ).yxx / float( SAMPLES - 1 )
	      ) / float( SAMPLES ) * 2.0;
	    }
	    if ( rot != 0.0 ) { yiq.yz = rotate2D( rot ) * yiq.yz; }
	    return yiq2rgb( yiq );
	  }
	  return vec3( 0.1, 0.1, 0.1 );
	}
	
	void mainImage(  ) {
    vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;
	  vec2 uv = fragCoord.xy / VHSRES;
	  float time = iTime;
	
	  vec2 uvn = uv;
	  vec3 col = vec3( 0.0, 0.0, 0.0 );
	
	  // tape wave
	  uvn.x += ( v2random( vec2( uvn.y / 10.0, time / 10.0 ) / 1.0 ) - 0.5 ) / VHSRES.x * 1.0;
	  uvn.x += ( v2random( vec2( uvn.y, time * 10.0 ) ) - 0.5 ) / VHSRES.x * 1.0;
	
	  // tape crease
	  float tcPhase = smoothstep( 0.9, 0.96, sin( uvn.y * 8.0 - ( time + 0.14 * v2random( time * vec2( 0.67, 0.59 ) ) ) * PI * 1.2 ) );
	  float tcNoise = smoothstep( 0.3, 1.0, v2random( vec2( uvn.y * 4.77, time ) ) );
	  float tc = tcPhase * tcNoise;
	  uvn.x = uvn.x - tc / VHSRES.x * 8.0;
	
	  // switching noise
	  float snPhase = smoothstep( 6.0 / VHSRES.y, 0.0, uvn.y );
	  uvn.y += snPhase * 0.3;
	  uvn.x += snPhase * ( ( v2random( vec2( uv.y * 100.0, time * 10.0 ) ) - 0.5 ) / VHSRES.x * 24.0 );
	
	  // fetch
	  col = vhsTex2D( uvn, tcPhase * 0.2 + snPhase * 2.0 );
	
	  // crease noise
	  float cn = tcNoise * ( 0.3 + 0.7 * tcPhase );
	  if ( 0.29 < cn ) {
	    vec2 uvt = ( uvn + V.yx * v2random( vec2( uvn.y, time ) ) ) * vec2( 0.1, 1.0 );
	    float n0 = v2random( uvt );
	    float n1 = v2random( uvt + V.yx / VHSRES.x );
	    if ( n1 < n0 ) {
	      col = mix( col, 2.0 * V.yyy, pow( n0, 10.0 ) );
	    }
	  }
	
	  // ac beat
	  col *= 1.0 + 0.1 * smoothstep( 0.4, 0.6, v2random( vec2( 0.0, 0.1 * ( uv.y + time * 0.2 ) ) / 10.0 ) );
	
	  // color noise
	  col *= 0.9 + 0.1 * texture( iChannel1, mod( uvn * vec2( 1.0, 1.0 ) + time * vec2( 5.97, 4.45 ), vec2( 1.0 ) ) ).xyz;
	  col = saturate( col );
	
	  // yiq
	  col = rgb2yiq( col );
	  col = vec3( 0.1, -0.1, 0.0 ) + vec3( 0.9, 1.1, 1.5 ) * col;
	  col = yiq2rgb( col );
	
	  fragColor = vec4( col, 1.0 );
	}
    ";

    /*
    * Don't Cross Freeplay Shader
    */
    var theBlurOf87 =
    "
	//source: https://www.shadertoy.com/view/fsV3R3

	#pragma header
	
	uniform float iTime;
	
	uniform float amount;
	
	const float pi = radians(180.);
	const int samples = 20;
	const float sigma = float(samples) * 0.25;
	
	// we don't need to recalculate these every time
	const float sigma2 = 2. * sigma * sigma;
	const float pisigma2 = pi * sigma2;
	
	float gaussian(vec2 i) {
	    float top = exp(-((i.x * i.x) + (i.y * i.y)) / sigma2);
	    float bot = pisigma2;
	    return top / bot;
	}
	
	vec3 blur(sampler2D sp, vec2 uv, vec2 scale) {
	    vec2 offset;
	    float weight = gaussian(offset);
	    vec3 col = texture2D(sp, uv).rgb * weight;
	    float accum = weight * amount;
	    
	    // we need to use x <= samples / 2
	    // to ensure symmetry
	    for (int x = 0; x <= samples / 2; ++x) {
	        for (int y = 1; y <= samples / 2; ++y) {
	            offset = vec2(x, y);
	            weight = gaussian(offset);
	            col += texture2D(sp, uv + scale * offset).rgb * weight;
	            accum += weight;
	
	            // since values are symmetrical
	            // we can re-use the 'weight' value, saving 3 function calls
	
	            col += texture2D(sp, uv - scale * offset).rgb * weight;
	            accum += weight;
	
	            offset = vec2(-y, x);
	            col += texture2D(sp, uv + scale * offset).rgb * weight;
	            accum += weight;
	
	            col += texture2D(sp, uv - scale * offset).rgb * weight;
	            accum += weight;
	        }
	    }
	    
	    return col / accum;
	}
	
	void main() {
	    vec2 iResolution = openfl_TextureSize;
	    vec2 fragCoord = openfl_TextureCoordv * iResolution;
	
	    vec2 ps = vec2(1.0) / iResolution.xy;
	    vec2 uv = fragCoord * ps;
	
	    gl_FragColor = vec4(blur(bitmap, uv, ps * amount), texture2D(bitmap,uv).a);
	}
    ";

    /*
    * For Dramatic Effect on the Cam movement
    */
    var cameraMovement = 
    "
	#pragma header

	uniform float time;
	
	vec2 ShakeUV(vec2 uv, float time) {
	    uv.x += 0.002 * sin(time*3.141) * sin(time*14.14);
	    uv.y += 0.002 * sin(time*1.618) * sin(time*17.32);
	    return uv;
	}
	
	void main() {
	    gl_FragColor = texture2D(bitmap, ShakeUV(openfl_TextureCoordv, time / 2.0));
	}
    ";

    /*
    * The Shader that's used on basically everything in the game except for certain songs
    */
    var monitorFilter =
    "
    	#pragma header

	float zoom = 1.0;
	void main()
	{
	    vec2 uv = openfl_TextureCoordv;
	    uv = (uv-.5)*2.;
	    uv *= zoom;
	    
	    uv.x *= 1. + pow(abs(uv.y/2.),3.);
	    uv.y *= 1. + pow(abs(uv.x/2.),3.);
	    uv = (uv + 1.)*.5;
	    
	    vec4 tex = vec4( 
	        texture2D(bitmap, uv+.001).r,
	        texture2D(bitmap, uv).g,
	        texture2D(bitmap, uv-.001).b, 
	        1.0
	    );
	    
	    tex *= smoothstep(uv.x,uv.x+0.01,1.)*smoothstep(uv.y,uv.y+0.01,1.)*smoothstep(-0.01,0.,uv.x)*smoothstep(-0.01,0.,uv.y);
	    
	    float avg = (tex.r+tex.g+tex.b)/3.;
	    gl_FragColor = tex + pow(avg,3.);
	}
    ";

    /*
    * Dark Filter used for Main Menu
    */
    var dimScreen =
    "
	#pragma header
	
	uniform float iTime;
	#define iChannel0 bitmap
	#define iChannel1 bitmap
	#define texture flixel_texture2D
	#define fragColor gl_FragColor
	#define mainImage main
	
	float noise(float x) {
	 
	    return fract(sin(x) * 100000.);
	    
	}
	
	float tape(vec2 uv) {
	 
		float t = iTime / 4.;
	    vec3 tex = texture(iChannel1, vec2(uv.x, uv.y - t)).xyz;
	    
	    float nx = (tex.x + tex.y + tex.z) / 3.;
	    vec3 amn = tex * noise(uv.y + t);
	    
	    return (amn.x + amn.y + amn.z) / 3.;
	    
	}
	
	void mainImage(  )
	{
	    vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;
	    
	    float t = tape(uv) * tape(-uv);
		vec3 noise = vec3(t) * 1.;
	                      
	 	fragColor = mix(texture(iChannel0, uv), vec4(noise,1.), .45);
	}
    ";

    /*
    * It's the desaturation shader, it's in a nutshell,
    * the greyscale shader but you have control on how strong
    * you want the effect to be, plus, can be altered with,
    * useful for doing transitions from color to greyscale.
    *
    * @param desaturationAmount - controls the visibility of colors on-screen
    * @param distortionTime - unknown
    * @param amplitude - unknown
    * @param frequency - unknown
    */
    var greyScaleButControllable =
    "
	#pragma header

	uniform float desaturationAmount;
	uniform float distortionTime;
	uniform float amplitude;
	uniform float frequency;
	
	void main() {
	    vec4 desatTexture = texture2D(bitmap, vec2(openfl_TextureCoordv.x + sin((openfl_TextureCoordv.y * frequency) + distortionTime) * amplitude, openfl_TextureCoordv.y));
	    gl_FragColor = vec4(mix(vec3(dot(desatTexture.xyz, vec3(.2126, .7152, .0722))), desatTexture.xyz, desaturationAmount), desatTexture.a);
	}
    ";

    var tvStatic =
    "
	#pragma header
	
	uniform float iTime;
	#define iChannel0 bitmap
	#define iChannel1 bitmap
	#define iChannel2 bitmap
	#define iChannelResolution bitmap
	#define texture flixel_texture2D
	#define fragColor gl_FragColor
	#define mainImage main
	uniform float uTime;
	uniform vec4 iMouse;
	
	// change these values to 0.0 to turn off individual effects
	float vertJerkOpt = 0.0;
	float vertMovementOpt = 0.03;
	float bottomStaticOpt = 0.5;
	float scalinesOpt = 2.3;
	float rgbOffsetOpt = 0.2;
	float horzFuzzOpt = 1.0;
	
	// Noise generation functions borrowed from: 
	// https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl
	
	vec3 mod289(vec3 x) {
	  return x - floor(x * (1.0 / 289.0)) * 289.0;
	}
	
	vec2 mod289(vec2 x) {
	  return x - floor(x * (1.0 / 289.0)) * 289.0;
	}
	
	vec3 permute(vec3 x) {
	  return mod289(((x*34.0)+1.0)*x);
	}
	
	float snoise(vec2 v)
	  {
	  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
	                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
	                     -0.577350269189626,  // -1.0 + 2.0 * C.x
	                      0.024390243902439); // 1.0 / 41.0
	// First corner
	  vec2 i  = floor(v + dot(v, C.yy) );
	  vec2 x0 = v -   i + dot(i, C.xx);
	
	// Other corners
	  vec2 i1;
	  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
	  //i1.y = 1.0 - i1.x;
	  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	  // x0 = x0 - 0.0 + 0.0 * C.xx ;
	  // x1 = x0 - i1 + 1.0 * C.xx ;
	  // x2 = x0 - 1.0 + 2.0 * C.xx ;
	  vec4 x12 = x0.xyxy + C.xxzz;
	  x12.xy -= i1;
	
	// Permutations
	  i = mod289(i); // Avoid truncation effects in permutation
	  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
			+ i.x + vec3(0.0, i1.x, 1.0 ));
	
	  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
	  m = m*m ;
	  m = m*m ;
	
	// Gradients: 41 points uniformly over a line, mapped onto a diamond.
	// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
	
	  vec3 x = 2.0 * fract(p * C.www) - 1.0;
	  vec3 h = abs(x) - 0.5;
	  vec3 ox = floor(x + 0.5);
	  vec3 a0 = x - ox;
	
	// Normalise gradients implicitly by scaling m
	// Approximation of: m *= inversesqrt( a0*a0 + h*h );
	  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
	
	// Compute final noise value at P
	  vec3 g;
	  g.x  = a0.x  * x0.x  + h.x  * x0.y;
	  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	  return 130.0 * dot(m, g);
	}
	
	float staticV(vec2 uv) {
	    float staticHeight = snoise(vec2(9.0,iTime*1.2+3.0))*0.3+5.0;
	    float staticAmount = snoise(vec2(1.0,iTime*1.2-6.0))*0.1+0.3;
	    float staticStrength = snoise(vec2(-9.75,iTime*0.6-3.0))*2.0+2.0;
		return (1.0-step(snoise(vec2(5.0*pow(iTime,2.0)+pow(uv.x*7.0,1.2),pow((mod(iTime,100.0)+100.0)*uv.y*0.3+3.0,staticHeight))),staticAmount))*staticStrength;
	}
	
	void mainImage()
	{
	    vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;
		
		float jerkOffset = (1.0-step(snoise(vec2(iTime*1.3,5.0)),0.8))*0.05;
		
		float fuzzOffset = snoise(vec2(iTime*15.0,uv.y*80.0))*0.003;
		float largeFuzzOffset = snoise(vec2(iTime*1.0,uv.y*25.0))*0.004;
	    
	    float vertMovementOn = (1.0-step(snoise(vec2(iTime*0.2,8.0)),0.4))*vertMovementOpt;
	    float vertJerk = (1.0-step(snoise(vec2(iTime*1.5,5.0)),0.6))*vertJerkOpt;
	    float vertJerk2 = (1.0-step(snoise(vec2(iTime*5.5,5.0)),0.2))*vertJerkOpt;
	    float yOffset = abs(sin(iTime)*4.0)*vertMovementOn+vertJerk*vertJerk2*0.3;
	    float y = mod(uv.y+yOffset,1.0);
	    
		
		float xOffset = (fuzzOffset + largeFuzzOffset) * horzFuzzOpt;
	    
	    float staticVal = 0.0;
	   
	    for (float y = -1.0; y <= 1.0; y += 1.0) {
	        float maxDist = 5.0/200.0;
	        float dist = y/200.0;
	    	staticVal += staticV(vec2(uv.x,uv.y+dist))*(maxDist-abs(dist))*1.5;
	    }
	        
	    staticVal *= bottomStaticOpt;
		
		float red 	=   texture(	iChannel0, 	vec2(uv.x + xOffset -0.01*rgbOffsetOpt,y)).r+staticVal;
		float green = 	texture(	iChannel0, 	vec2(uv.x + xOffset,	  y)).g+staticVal;
		float blue 	=	texture(	iChannel0, 	vec2(uv.x + xOffset +0.01*rgbOffsetOpt,y)).b+staticVal;
		
		vec3 color = vec3(red,green,blue);
		float scanline = sin(uv.y*800.0)*0.04*scalinesOpt;
		color -= scanline;
		
		fragColor = vec4(color,1.0);
	}
    ";

    /*
    * An overused shader within the FNF D&B community, you know the drill...
    */
    var acidTrip =
    "
	#pragma header
	//uniform float tx, ty; // x,y waves phase
	
	//modified version of the wave shader to create weird garbled corruption like messes
	uniform float uTime;
	    
	/**
	* How fast the waves move over time
	*/
	uniform float uSpeed;
	    
	/**
	* Number of waves over time
	*/
	uniform float uFrequency;
	    
	/**
	* How much the pixels are going to stretch over the waves
	*/
	uniform float uWaveAmplitude;
	
	vec2 sineWave(vec2 pt)
	{
	float x = 0.0;
	float y = 0.0;
	        
	float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
	float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
	pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
	pt.y += offsetY;
	
	return vec2(pt.x + x, pt.y + y);
	}
	
	void main()
	{
	vec2 uv = sineWave(openfl_TextureCoordv);
	gl_FragColor = texture2D(bitmap, uv);
	}
    ";

    /*
    * This shader is used on the menu buttons so they look like
    * they flash when you select them, kinda like in Indie Cross tbh
    */
    var flashyFlash =
    "
	#pragma header

	uniform float progress;

	void main(void)
	{
		vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
		gl_FragColor = mix(color, vec4(color.a), progress);
	}
    ";

    /*
    * HAHAHAHA, FUNNY RED VIGNETTE OVERLAY THING, SOOOOO FUNNY
    */
    var redFromAngryBirds =
    "
	#pragma header

	#define PI 3.14159265
	uniform float time;
	uniform float vignetteIntensity;
	
	void main() {
	    float amount = (0.25 * sin(time * PI) + vignetteIntensity);
	    vec4 color = texture2D(bitmap, openfl_TextureCoordv);
	    float vignette = distance(openfl_TextureCoordv, vec2(0.5));
	    vignette = mix(1.0, 1.0 - amount, vignette);
		gl_FragColor = vec4(mix(vec3(1.0, 0.0, 0.0), color.rgb, vignette), 1.0 - vignette);
	}
    ";

    var vhsFilter =
    "
    // Based on a shader by FMS_Cat.
	// https://www.shadertoy.com/view/XtBXDt
	// Modified to support OpenFL.
	
	#pragma header
	#define PI 3.14159265
	
	uniform float time;
	
	vec3 tex2D(sampler2D _tex,vec2 _p)
	{
	    vec3 col=texture2D(_tex,_p).xyz;
	    if(.5<abs(_p.x-.5)){
	        col=vec3(.1);
	    }
	    return col;
	}
	
	float hash(vec2 _v)
	{
	    return fract(sin(dot(_v,vec2(89.44,19.36)))*22189.22);
	}
	
	float iHash(vec2 _v,vec2 _r)
	{
	    float h00=hash(vec2(floor(_v*_r+vec2(0.,0.))/_r));
	    float h10=hash(vec2(floor(_v*_r+vec2(1.,0.))/_r));
	    float h01=hash(vec2(floor(_v*_r+vec2(0.,1.))/_r));
	    float h11=hash(vec2(floor(_v*_r+vec2(1.,1.))/_r));
	    vec2 ip=vec2(smoothstep(vec2(0.,0.),vec2(1.,1.),mod(_v*_r,1.)));
	    return(h00*(1.-ip.x)+h10*ip.x)*(1.-ip.y)+(h01*(1.-ip.x)+h11*ip.x)*ip.y;
	}
	
	float noise(vec2 _v)
	{
	    float sum=0.;
	    for(int i=1;i<9;i++)
	    {
	        sum+=iHash(_v+vec2(i),vec2(2.*pow(2.,float(i))))/pow(2.,float(i));
	    }
	    return sum;
	}
	
	void main()
	{
	    vec2 uv=openfl_TextureCoordv;
	    vec2 uvn=uv;
	    vec3 col=vec3(0.);
	    
	    // tape wave
	    uvn.x+=(noise(vec2(uvn.y,time))-.5)*.005;
	    uvn.x+=(noise(vec2(uvn.y*100.,time*10.))-.5)*.01;
	    
	    // tape crease
	    float tcPhase=clamp((sin(uvn.y*8.-time*PI*1.2)-.92)*noise(vec2(time)),0.,.01)*10.;
	    float tcNoise=max(noise(vec2(uvn.y*100.,time*10.))-.5,0.);
	    uvn.x=uvn.x-tcNoise*tcPhase;
	    
	    // switching noise
	    float snPhase=smoothstep(.03,0.,uvn.y);
	    uvn.y+=snPhase*.3;
	    uvn.x+=snPhase*((noise(vec2(uv.y*100.,time*10.))-.5)*.2);
	    
	    col=tex2D(bitmap,uvn);
	    col*=1.-tcPhase;
	    col=mix(
	        col,
	        col.yzx,
	        snPhase
	    );
	    
	    // bloom
	    for(float x=-4.;x<2.5;x+=1.){
	        col.xyz+=vec3(
	            tex2D(bitmap,uvn+vec2(x-0.,0.)*7E-3).x,
	            tex2D(bitmap,uvn+vec2(x-2.,0.)*7E-3).y,
	            tex2D(bitmap,uvn+vec2(x-4.,0.)*7E-3).z
	        )*.1;
	    }
	    col*=.6;
	    
	    // ac beat
	    col*=1.+clamp(noise(vec2(0.,uv.y+time*.2))*.6-.25,0.,.1);
	    
	    gl_FragColor=vec4(col,1.);
	}
    ";

    var delusionalShift =
    "
    //definitions and stuff
	#pragma header
	
	uniform float iTime;
	#define iChannel0 bitmap
	#define iChannel1 bitmap
	#define iChannel2 bitmap
	#define iChannelResolution bitmap
	#define texture flixel_texture2D
	#define fragColor gl_FragColor
	#define mainImage main
	uniform float uTime;
	uniform vec4 iMouse;
	
	
	//
	// Description : Array and textureless GLSL 2D simplex noise function.
	//      Author : Ian McEwan, Ashima Arts.
	//  Maintainer : stegu
	//     Lastmod : 20110822 (ijm)
	//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
	//               Distributed under the MIT License. See LICENSE file.
	//               https://github.com/ashima/webgl-noise
	//               https://github.com/stegu/webgl-noise
	// 
	
	vec3 mod289(vec3 x) {
	  return x - floor(x * (1.0 / 289.0)) * 289.0;
	}
	
	vec2 mod289(vec2 x) {
	  return x - floor(x * (1.0 / 289.0)) * 289.0;
	}
	
	vec3 permute(vec3 x) {
	  return mod289(((x*34.0)+1.0)*x);
	}
	
	float snoise(vec2 v)
	  {
	  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
	                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
	                     -0.577350269189626,  // -1.0 + 2.0 * C.x
	                      0.024390243902439); // 1.0 / 41.0
	// First corner
	  vec2 i  = floor(v + dot(v, C.yy) );
	  vec2 x0 = v -   i + dot(i, C.xx);
	
	// Other corners
	  vec2 i1;
	  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
	  //i1.y = 1.0 - i1.x;
	  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	  // x0 = x0 - 0.0 + 0.0 * C.xx ;
	  // x1 = x0 - i1 + 1.0 * C.xx ;
	  // x2 = x0 - 1.0 + 2.0 * C.xx ;
	  vec4 x12 = x0.xyxy + C.xxzz;
	  x12.xy -= i1;
	
	// Permutations
	  i = mod289(i); // Avoid truncation effects in permutation
	  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
			+ i.x + vec3(0.0, i1.x, 1.0 ));
	
	  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
	  m = m*m ;
	  m = m*m ;
	
	// Gradients: 41 points uniformly over a line, mapped onto a diamond.
	// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
	
	  vec3 x = 2.0 * fract(p * C.www) - 1.0;
	  vec3 h = abs(x) - 0.5;
	  vec3 ox = floor(x + 0.5);
	  vec3 a0 = x - ox;
	
	// Normalise gradients implicitly by scaling m
	// Approximation of: m *= inversesqrt( a0*a0 + h*h );
	  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
	
	// Compute final noise value at P
	  vec3 g;
	  g.x  = a0.x  * x0.x  + h.x  * x0.y;
	  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	  return 130.0 * dot(m, g);
	}
	
	float rand(vec2 co)
	{
	   return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
	}
	
	
	void mainImage()
	{
		vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;  
	    float time = iTime * 2.0;
	    
	    // Create large, incidental noise waves
	    float noise = max(0.0, snoise(vec2(time, uv.y * 0.1)) - 0.54) * (1.0 / 0.9); // apparently, this is the key to modifying the jittering bullshit
	    
	    // Offset by smaller, constant noise waves
	    noise = noise + (snoise(vec2(time*10.0, uv.y * 2.4)) - 0.5) * 0.15; //WHY THE FUCK IS THIS A THING????? (don)
	    
	    // Apply the noise as x displacement for every line
	    float xpos = uv.x - noise * noise * 0.15;
		fragColor = texture(iChannel0, vec2(xpos, uv.y));
	    
	    // Mix in some random interference for lines
	    fragColor.rgb = mix(fragColor.rgb, vec3(rand(vec2(uv.y * time))), noise * 0.3).rgb;
	    
	    // Apply a line pattern every 4 pixels
	    if (floor(mod(fragCoord.y * 0.25, 2.0)) == 0.0)
	    {
	        fragColor.rgb *= 1.0 - (0.15 * noise);
	    }
	    
	    // Shift green/blue channels (using the red channel)
	    fragColor.g = mix(fragColor.r, texture(iChannel0, vec2(xpos + noise * 0.05, uv.y)).g, 0.25);
	    fragColor.b = mix(fragColor.r, texture(iChannel0, vec2(xpos - noise * 0.05, uv.y)).b, 0.25);
	}
    ";

	var unregisteredHyperCam2Quality =
	"
    //SHADERTOY PORT FIX (thx bb)
	#pragma header
	
	uniform float iTime;
	#define iChannel0 bitmap
	#define texture flixel_texture2D
	#define fragColor gl_FragColor
	#define mainImage main
	//SHADERTOY PORT FIX

	uniform float size;

	void mainImage() {
		vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;
		vec2 coordinates = fragCoord.xy/iResolution.xy;
		vec2 pixelSize = vec2(size/iResolution.x, size/iResolution.y);
		vec2 position = floor(coordinates/pixelSize)*pixelSize;
		vec4 finalColor = texture(iChannel0, position);
		fragColor = finalColor;
	}
	";

	var heatWave =
	"
	#pragma header
	
	uniform float iTime;
	#define iChannel0 bitmap
	#define iChannel1 bitmap
	#define iChannel2 bitmap
	#define iChannelResolution bitmap
	#define texture flixel_texture2D
	#define fragColor gl_FragColor
	#define mainImage main
	uniform float uTime;
	uniform vec4 iMouse;
	
	void mainImage()
	{
		// Normalized pixel coordinates (from 0 to 1)
	   vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;
	
		// Time varying pixel color
		float jacked_time = 5.5*iTime;
		const vec2 scale = vec2(.5);
		   
		uv += 0.01*sin(scale*jacked_time + length( uv )*10.0);
		fragColor = texture(iChannel0, uv).rgba;
	}
	";

	var blessBlur =
	"
	#pragma header
	
	uniform float iTime;
	#define iChannel0 bitmap
	#define texture flixel_texture2D
	#define fragColor gl_FragColor
	#define mainImage main

	// https://www.shadertoy.com/view/Xltfzj

	void mainImage()
	{
		vec2 uv = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;
		
		float Pi = 6.28318530718; // Pi*2
		
		// GAUSSIAN BLUR SETTINGS {{{
		float Directions = 16.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
		float Quality = 3.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
		float Size = 8.0; // BLUR SIZE (Radius)
		// GAUSSIAN BLUR SETTINGS }}}
	
		vec2 Radius = Size/iResolution.xy;
		
		// Normalized pixel coordinates (from 0 to 1)
		// Pixel colour
		vec4 Color = texture(iChannel0, uv);
		
		// Blur calculations
		for( float d=0.0; d<Pi; d+=Pi/Directions)
		{
			for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
			{
				Color += texture( iChannel0, uv+vec2(cos(d),sin(d))*Radius*i);		
			}
		}
		
		// Output to screen
		Color /= Quality * Directions - 15.0;
		gl_FragColor =  Color;
	}
	";

	var blessLightsShit =
	"
	#pragma header
	
	uniform float iTime;
	#define iChannel0 bitmap
	#define texture flixel_texture2D
	#define mainImage main

	// https://www.shadertoy.com/view/MdyGzR

	vec3 mod289(vec3 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
	}

	vec4 mod289(vec4 x) {
	return x - floor(x * (1.0 / 289.0)) * 289.0;
	}

	vec4 permute(vec4 x) {
		return mod289(((x*34.0)+1.0)*x);
	}

	vec4 taylorInvSqrt(vec4 r)
	{
	return 1.79284291400159 - 0.85373472095314 * r;
	}

	float snoise(vec3 v)
	{ 
	const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
	const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

	// First corner
	vec3 i  = floor(v + dot(v, C.yyy) );
	vec3 x0 =   v - i + dot(i, C.xxx) ;

	// Other corners
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 i1 = min( g.xyz, l.zxy );
	vec3 i2 = max( g.xyz, l.zxy );

	//   x0 = x0 - 0.0 + 0.0 * C.xxx;
	//   x1 = x0 - i1  + 1.0 * C.xxx;
	//   x2 = x0 - i2  + 2.0 * C.xxx;
	//   x3 = x0 - 1.0 + 3.0 * C.xxx;
	vec3 x1 = x0 - i1 + C.xxx;
	vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
	vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

	// Permutations
	i = mod289(i); 
	vec4 p = permute( permute( permute( 
				i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
			+ i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
			+ i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

	// Gradients: 7x7 points over a square, mapped onto an octahedron.
	// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
	float n_ = 0.142857142857; // 1.0/7.0
	vec3  ns = n_ * D.wyz - D.xzx;

	vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

	vec4 x_ = floor(j * ns.z);
	vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

	vec4 x = x_ *ns.x + ns.yyyy;
	vec4 y = y_ *ns.x + ns.yyyy;
	vec4 h = 1.0 - abs(x) - abs(y);

	vec4 b0 = vec4( x.xy, y.xy );
	vec4 b1 = vec4( x.zw, y.zw );

	//vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
	//vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
	vec4 s0 = floor(b0)*2.0 + 1.0;
	vec4 s1 = floor(b1)*2.0 + 1.0;
	vec4 sh = -step(h, vec4(0.0));

	vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
	vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

	vec3 p0 = vec3(a0.xy,h.x);
	vec3 p1 = vec3(a0.zw,h.y);
	vec3 p2 = vec3(a1.xy,h.z);
	vec3 p3 = vec3(a1.zw,h.w);

	//Normalise gradients
	vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
	p0 *= norm.x;
	p1 *= norm.y;
	p2 *= norm.z;
	p3 *= norm.w;

	// Mix final noise value
	vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
	m = m * m;
	return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
									dot(p2,x2), dot(p3,x3) ) );
	}

	float normnoise(float noise) {
		return 0.5*(noise+1.0);
	}

	float clouds(vec2 uv) {
		uv += vec2(iTime*0.05, + iTime*0.01);
		
		vec2 off1 = vec2(50.0,33.0);
		vec2 off2 = vec2(0.0, 0.0);
		vec2 off3 = vec2(-300.0, 50.0);
		vec2 off4 = vec2(-100.0, 200.0);
		vec2 off5 = vec2(400.0, -200.0);
		vec2 off6 = vec2(100.0, -1000.0);
		float scale1 = 3.0;
		float scale2 = 6.0;
		float scale3 = 12.0;
		float scale4 = 24.0;
		float scale5 = 48.0;
		float scale6 = 96.0;
		return normnoise(snoise(vec3((uv+off1)*scale1,iTime*0.5))*0.8 + 
						snoise(vec3((uv+off2)*scale2,iTime*0.4))*0.4 +
						snoise(vec3((uv+off3)*scale3,iTime*0.1))*0.2 +
						snoise(vec3((uv+off4)*scale4,iTime*0.7))*0.1 +
						snoise(vec3((uv+off5)*scale5,iTime*0.2))*0.05 +
						snoise(vec3((uv+off6)*scale6,iTime*0.3))*0.025);
	}


	void mainImage()
	{
		vec2 realUV = openfl_TextureCoordv.xy;
	vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
	vec2 iResolution = openfl_TextureSize;
		vec2 uv =  fragCoord.xy/iResolution.x;
		
		vec4 tex = texture(iChannel0, realUV);
		
		vec2 center = vec2(0.5,0.5*(iResolution.y/iResolution.x));
		
		vec2 light1 = vec2(sin(iTime*0.2+50.0)*1.0 + cos(iTime*0.4+10.0)*0.6,sin(iTime*1.2+100.0)*0.8 + cos(iTime*0.2+20.0)*-0.2)*0.2+center;
		vec3 lightColor1 = vec3(0.6, 0.6, 1.0);
		
		vec2 light2 = vec2(sin(iTime+3.0)*-2.0,cos(iTime+7.0)*1.0)*0.2+center;
		vec3 lightColor2 = vec3(0.8, 0.8, 1.0);
		
		vec2 light3 = vec2(sin(iTime+2.0)*2.0,cos(iTime+14.0)*-1.0)*0.22+center;
		vec3 lightColor3 = vec3(0.7, 0.7, 1.0);

		vec2 light4 = vec2(sin(iTime+3.0)*2.0,cos(iTime-20.0)*-1.0)*0.2+center;
		vec3 lightColor4 = vec3(0.5, 0.5, 1.0);
		
		vec2 light5 = vec2(sin(iTime+4.0)*2.0,cos(iTime+30.0)*-1.0)*0.14+center;
		vec3 lightColor5 = vec3(1.0, 1.0, 1.0);
		
		float cloudIntensity1 = 0.12*(1.0-(2.5*distance(uv, light1)));
		float lighIntensity1 = 1.0/(350.0*distance(uv,light1));

		float cloudIntensity2 = 0.12*(1.0-(2.5*distance(uv, light2)));
		float lighIntensity2 = 1.0/(300.0*distance(uv,light2));
		
		float cloudIntensity3 = 0.12*(1.0-(2.5*distance(uv, light3)));
		float lighIntensity3 = 1.0/(250.0*distance(uv,light3));
		
		float cloudIntensity4 = 0.12*(1.0-(2.5*distance(uv, light4)));
		float lighIntensity4 = 1.0/(380.0*distance(uv,light4));
		
		float cloudIntensity5 = 0.12*(1.0-(2.5*distance(uv, light5)));
		float lighIntensity5 = 1.0/(400.0*distance(uv,light5));
		
		tex.rgb += vec3(cloudIntensity1*clouds(uv))*lightColor1 + lighIntensity1*lightColor1 +
						vec3(cloudIntensity2*clouds(uv))*lightColor2 + lighIntensity2*lightColor2 +
						vec3(cloudIntensity3*clouds(uv))*lightColor3 + lighIntensity3*lightColor3 +
						vec3(cloudIntensity4*clouds(uv))*lightColor4 + lighIntensity4*lightColor4 +
						vec3(cloudIntensity5*clouds(uv))*lightColor5 + lighIntensity5*lightColor5;
		
		
		gl_FragColor = tex;
	}
	";
}
