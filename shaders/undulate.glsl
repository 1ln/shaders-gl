#version 330 core     

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

//undulate
//2021
//do

const float PI   =  radians(180.0); 
const int seed = 3434;

float hash(float p) {
    uvec2 n = uint(int(p)) * uvec2(uint(int(seed)),2531151992.0);
    uint h = (n.x ^ n.y) * uint(int(seed));
    return float(h) * (1./float(0xffffffffU));
}

float hash(vec2 p) {
    uvec2 n = uvec2(ivec2(p)) * uvec2(uint(int(seed)),2531151992.0);
    uint h = (n.x ^ n.y) * uint(int(seed));
    return float(h) * (1./float(0xffffffffU));
}

float n3(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 157.0 + 113.0 * p.z;

    return mix(mix(mix(hash(  n +   0.0) , 
                       hash(   n +   1.0)  ,f.x),
                   mix(hash(  n + 157.0) ,  
                       hash(   n + 158.0)   ,f.x),f.y),
               mix(mix(hash(  n + 113.0) ,
                       hash(   n + 114.0)   ,f.x),
                   mix(hash(  n + 270.0) ,
                       hash(   n + 271.0)   ,f.x),f.y),f.z);
}

float f3(vec3 x,float hurst) {
    float s = 0.;
    float h = exp2(-hurst);
    float f = 1.;
    float a = .5;

    for(int i = 0; i < 5; i++) {

        s += a * n3(f * x);  
        f *= 2.;
        a *= h;
    }
    return s;
}

vec3 fmCol(float t,vec3 a,vec3 b,vec3 c,vec3 d) {
    return a + b * cos( (PI*2.0) * (c * t + d));
}

float easeInOut4(float t) {
    if((t *= 2.0) < 1.0) {
        return 0.5 * t * t;
    } else {
        return -0.5 * ((t - 1.0) * (t - 3.0) - 1.0);
    }
}

float easeOut3(float t) {
    return (t = t - 1.0) * t * t + 1.0;
}

mat2 rot2(float a) {
    float c = cos(a);
    float s = sin(a);
    
    return mat2(c,-s,s,c);
}

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) { 
    return length(p) - r;
}

float plane(vec3 p,vec4 n) {
   return dot(p,n.xyz) + n.w;
}

float box(vec3 p,vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

vec2 scene(vec3 p) {

    vec2 res = vec2(1.,0.);

    float d = 0.;     
    float s = 1.25;

    float t = time;  
    
    vec3 q = p;
    vec3 l = p;

    p.xz *= rot2(easeOut3(t*s*.06)*0.0015);
    q.yx *= rot2(.5*cos(easeInOut4(t*s)*0.005));

    d = mix(sphere(p,0.25),box(q,vec3(1.)),
    sin(s*t)*0.5+0.5); 

    d += n3(p+n3(p)*0.25+t*s)*0.25; 

    res = opu(res,vec2(d,2.));
    float pl = plane(l+vec3(0.,1.5,0.),vec4(0.,1.,1.,1.));

    res = opu(res,vec2(pl,1.));
  
  return res;

}

vec2 rayScene(vec3 ro,vec3 rd) {
    
    float d = -1.0;
    float s = 1.;
    float e = 12.;  

    for(int i = 0; i < 155; i++) {

        vec3 p = ro + s * rd;
        vec2 dist = scene(p);
   
        if(abs(dist.x) < 0.0001 || e <  dist.x ) { break; }
        s += dist.x;
        d = dist.y;

        }
 
        if(e < s) { d = -1.0; }
        return vec2(s,d);

}

float shadow(vec3 ro,vec3 rd ) {

    float res = 1.0;
    float t = 0.005;
    float ph = 1e10;
    
    for(int i = 0; i < 100; i++ ) {
        
        float h = scene(ro + rd * t  ).x;

        float y = h * h / (2. * ph);
        float d = sqrt(h*h-y*y);         
        res = min(res,235. * d/max(0.,t-y));
        ph = h;
        t += h;
    
        if(res < 0.01 ||t > 5.) { break; }

        }

        return clamp(res,0.0,1.0);

}

vec3 calcNormal(vec3 p) {

    vec2 e = vec2(1.,-1.) * 0.0001;

    return normalize(vec3(
    vec3(e.x,e.y,e.y) * scene(p + vec3(e.x,e.y,e.y)).x +
    vec3(e.y,e.x,e.y) * scene(p + vec3(e.y,e.x,e.y)).x +
    vec3(e.y,e.y,e.x) * scene(p + vec3(e.y,e.y,e.x)).x + 
    vec3(e.x,e.x,e.x) * scene(p + vec3(e.x,e.x,e.x)).x

    ));
    
}

vec3 rayCamDir(vec2 uv,vec3 camPosition,vec3 camTarget,float fPersp) {

     vec3 camForward = normalize(camTarget - camPosition);
     vec3 camRight = normalize(cross(vec3(0.0,1.0,0.0),camForward));
     vec3 camUp = normalize(cross(camForward,camRight));

     vec3 vDir = normalize(uv.x * camRight + uv.y * 
     camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd) {
 
vec2 d = rayScene(ro, rd);

vec3 col = vec3(1.) - max(rd.y,0.);

if(d.y >= 0.) { 

vec3 p = ro + rd * d.x;
vec3 n = calcNormal(p);
vec3 l = normalize(vec3(0.,10.,10.));

vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);

float spe = pow(clamp(dot(n,h),0.0,1.0),16.)
* dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

float fre = pow(clamp(1. + dot(n,rd),0.0,1.0),2.0);
float ref = smoothstep(-.2,.2,r.y);

vec3 linear = vec3(0.);

dif *= shadow(p,l);
ref *= shadow(p,r);

linear += dif * vec3(1.);
linear += amb * vec3(.05,0.01,0.01);
linear += ref * vec3(0.004,0.005,0.11);
linear += fre * vec3(0.04,0.12,0.005);

if(d.y == 2.) {

    float nl = f3(p+f3(p,sin(p.y)),hash(122.)); 

    col += fmCol(p.y + nl,vec3(hash(112.),hash(33.),hash(21.)),
                          vec3(hash(12.),hash(105.),hash(156.)), 
                          vec3(hash(32.),hash(123.),hash(25.)),                                  vec3(hash(10.),hash(15.),hash(27.)));  
}

col = col * linear;
col += 5. * spe * vec3(0.0001);

} 

return col;
}

void main() {
 
vec3 color = vec3(0.);

vec3 cam_tar = vec3(0.);
vec3 cam_pos = vec3(0.,2.,5.);

vec2 uv = (2.*gl_FragCoord.xy-resolution)/resolution.y;  

vec3 dir = rayCamDir(uv,cam_pos,cam_tar,2.); 
color = render(cam_pos,dir);  
fragColor = vec4(color,1.0);

}
