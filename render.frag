#version 430 core     

// dolson,2019

out vec4 FragColor;

uniform sampler2D tex;

uniform vec2 resolution;

uniform float time;
uniform float speed;

uniform int seed;

uniform vec3 cam_position;
uniform vec3 cam_target;
uniform float fov;

uniform float mouse;
uniform int mouse_pressed;

uniform int aa;

#define steps 100
#define eps 0.0001
#define dmin 0.0
#define dmax 225.
#define shsteps 45.
#define shmax 25.
#define shblur 10.
#define aosteps 5

const float E    =  2.7182818;
const float PI   =  radians(180.0); 
const float PI2  =  PI * 2.;
const float PHI  =  (1.0 + sqrt(5.0)) / 2.0;

const float fog_distance = 0.0001;
const float fog_density = 3.;

float fcos(float x) {
    float w = fwidth(x);
    return cos(x) * smoothstep(PI2,0.,w);
}

vec2 mod289(vec2 p) { return p - floor(p * (1. / 289.)) * 289.; }
vec3 mod289(vec3 p) { return p - floor(p * (1. / 289.)) * 289.; }
vec3 permute(vec3 p) { return mod289(((p * 34.) + 1.) * p); } 

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

vec3 hash3(vec3 p) {
   uvec3 h = uvec3(ivec3(  p)) *  
   uvec3(uint(int(seed)),2531151992.0,2860486313U);
   h = (h.x ^ h.y ^ h.z) * 
   uvec3(uint(int(seed)),2531151992U,2860486313U);
   return vec3(h) * (1.0/float(0xffffffffU));
}

vec2 rndPtCircle(float p) {
    float a = PI2 * hash(p);
    return vec2(cos(a),sin(a));
}

vec2 diag(vec2 p) {
   vec2 r = vec2(0.);
   r.x = 1.1547 * p.x;
   r.y = p.y + .5 * r.x;
   return r;
}

vec3 simplexGrid(vec2 p) {

    vec3 q = vec3(0.);
    vec2 l = fract(diag(p));
    
    if(l.x > l.y) {
        q.xy = 1. - vec2(l.x-l.y,l.x);
        q.z = l.y;
    } else {
        q.yz = 1. - vec2(l.x-l.y,l.y);
        q.x = l.x;
    }
    return q;

}

float radial(vec2 p,float b) {
    vec2 l = vec2(.5) - p;
    float a = atan(l.y,l.x);
    return cos(a * b);
}
 
float cell(vec3 x,float iterations,int type) {
 
    x *= iterations;

    vec3 p = floor(x);
    vec3 f = fract(x);
 
    float min_dist = 1.0;
    
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            for(int k = -1; k <= 1; k++) { 

                vec3 b = vec3(float(k),float(j),float(i));
                vec3 r = hash3( p + b );
                
                vec3 diff = (b + r - f);

                float d = length(diff);

                    if(type == 0) { 
                        min_dist = min(min_dist,d);
                    }
 
                    if(type == 1) {
                        min_dist = min(min_dist,abs(diff.x)+abs(diff.y)+abs(diff.z));
                    }

                    if(type == 2) {
                        min_dist = min(min_dist,max(abs(diff.x),max(abs(diff.y),abs(diff.z))));
                    }

            }
        }
    }
 
    return min_dist;  

}

float ns2(vec2 p) {

    const float k1 = (3. - sqrt(3.))/6.;
    const float k2 = .5 * (sqrt(3.) -1.);
    const float k3 = -.5773;
    const float k4 = 1./41.;

    const vec4 c = vec4(k1,k2,k3,k4);
    
    vec2 i = floor(p + dot(p,c.yy));
    vec2 x0 = p - i + dot(i,c.xx);
  
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.,0.) : vec2(0.,1.);
    vec4 x12 = x0.xyxy + c.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    
    vec3 p1 = permute(permute(i.y + vec3(0.,i1.y,1.))
        + i.x + vec3(0.,i1.x,1.));
        p1 = permute(mod289(p1 + vec3(float(seed))));

    vec3 m = max(.5 - vec3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.);
    m = m * m; 
    m = m * m;

    vec3 x = fract(p1 * c.www) - 1.;
    vec3 h = abs(x) - .5;
    vec3 ox = floor(x + .5);
    vec3 a0 = x - ox; 
    m *= 1.792842 - 0.853734 * (a0 * a0 + h * h);
     
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130. * dot(m,g);
}

float n3(vec3 x) {

    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 157.0 + 113.0 * p.z;

    return mix(mix(mix(hash(  n +   0.0) , hash(   n +   1.0)   ,f.x),
                   mix(hash(  n + 157.0) , hash(   n + 158.0)   ,f.x),f.y),
               mix(mix(hash(  n + 113.0) , hash(   n + 114.0)   ,f.x),
                   mix(hash(  n + 270.0) , hash(   n + 271.0)   ,f.x),f.y),f.z);
}

float f2(vec2 x,int octaves) {

    float f = 0.;

    for(int i = 1; i < octaves; i++) {
 
    float e = pow(2.,float(i));
    float s = (1./e);
    f += ns2(x*e)*s;   
    
    }    

    return f * .5 + .5;
}

float f3(vec3 x,int octaves,float hurst) {

    float s = 0.;
    float h = exp2(-hurst);
    float f = 1.;
    float a = .5;

    for(int i = 0; i < octaves; i++) {

        s += a * n3(f * x);  
        f *= 2.;
        a *= h;
    }
    return s;
}

float sin2(vec2 p,float s) {
    
    return sin(p.x*s) * sin(p.y*s);
}

float sin3(vec3 p,float s) {
    return sin(p.x * s) * sin(p.y * s) * sin(p.z * s);
}

float fib(float n) {

    return pow(( 1. + sqrt(5.)) /2.,n) -
           pow(( 1. - sqrt(5.)) /2.,n) / sqrt(5.); 

}

float envImp(float x,float k) {

    float h = k * x;
    return h * exp(1.0 - h);
}

float envSt(float x,float k,float n) {

    return exp(-k * pow(x,n));

}

float cubicImp(float x,float c,float w) {

    x = abs(x - c);
    if( x > w) { return 0.0; }
    x /= w;
    return 1.0 - x * x  * (3.0 - 2.0 * x);

}

float sincPh(float x,float k) {

    float a = PI * (k * x - 1.0);
    return sin(a)/a;

}

vec3 fmCol(float t,vec3 a,vec3 b,vec3 c,vec3 d) {
    
    return a + b * cos( (PI*2.0) * (c * t + d));
}

vec3 rgbHsv(vec3 c) {

    vec3 rgb = clamp(abs(mod(c.x * 6. + vec3(0.,4.,2.),
               6.)-3.)-1.,0.,1.);

    rgb = rgb * rgb * (3. - 2. * rgb);
    return c.z * mix(vec3(1.),rgb,c.y);

}

float easeIn4(float t) {

    return t * t;

}

float easeOut4(float t) {

    return -1.0 * t * (t - 2.0);

}

float easeInOut4(float t) {

    if((t *= 2.0) < 1.0) {
        return 0.5 * t * t;
    } else {
        return -0.5 * ((t - 1.0) * (t - 3.0) - 1.0);
    }
}

float easeIn3(float t) {

    return t * t * t;

}

float easeOut3(float t) {

    return (t = t - 1.0) * t * t + 1.0;

}

float easeInOut3(float t) {

    if((t *= 2.0) < 1.0) {
        return 0.5 * t * t * t;
    } else { 
        return 0.5 * ((t -= 2.0) * t * t + 2.0);

    }
}

mat2 rot2(float a) {

    float c = cos(a);
    float s = sin(a);
    
    return mat2(c,-s,s,c);
}

mat4 rotAxis(vec3 axis,float theta) {

axis = normalize(axis);

    float c = cos(theta);
    float s = sin(theta);

    float oc = 1.0 - c;

    return mat4(
 
        oc * axis.x * axis.x + c, 
        oc * axis.x * axis.y - axis.z * s,
        oc * axis.z * axis.x + axis.y * s, 
        0.0,
        oc * axis.x * axis.y + axis.z * s,
        oc * axis.y * axis.y + c, 
        oc * axis.y * axis.z - axis.x * s,
        0.0,
        oc * axis.z * axis.x - axis.y * s,
        oc * axis.y * axis.z + axis.x * s, 
        oc * axis.z * axis.z + c, 
        0.0,
        0.0,0.0,0.0,1.0);

}

mat4 translate(vec3 p) {
 
    return mat4(
        vec4(1,0,0,p.x),
        vec4(0,1,0,p.y),
        vec4(0,0,1,p.z),
        vec4(0,0,0,1)  
);
}

vec3 repLim(vec3 p,float c,vec3 l) {
  
    vec3 q = p - c * clamp( floor((p/c)+0.5) ,-l,l);
    return q; 
}

vec2 repeat(vec2 p,float s) {
     vec2 q = mod(p,s) - .5 * s;
     return q;
}

vec3 repeat(vec3 p,vec3 s) {
   
    vec3 q = mod(p,s) - 0.5 * s;
    return q;
} 

vec3 id(vec3 p,float s) {
    return floor(p/s);
}

vec2 opu(vec2 d1,vec2 d2) {

    return (d1.x < d2.x) ? d1 : d2;
} 

float opu(float d1,float d2) {
    
    return min(d1,d2);
}

float opi(float d1,float d2) {

    return max(d1,d2);
}

float opd(float d1,float d2) {

    return max(-d1,d2);
}

float smou(float d1,float d2,float k) {

    float h = clamp(0.5 + 0.5 * (d2-d1)/k,0.0,1.0);
    return mix(d2,d1,h) - k * h * (1.0 - h);
}

float smod(float d1,float d2,float k) {

    float h = clamp(0.5 - 0.5 * (d2+d1)/k,0.0,1.0);
    return mix(d2,-d1,h) + k * h * (1.0 - h);
}

float smoi(float d1,float d2,float k) {

    float h = clamp(0.5 + 0.5 * (d2-d1)/k,0.0,1.0);
    return mix(d2,d1,h) + k * h * (1.0 - h);

}

vec4 el(vec3 p,vec3 h) {
    vec3 q = abs(p) - h;
    return vec4(max(q,0.),min(max(q.x,max(q.y,q.z)),0.));
}

float extr(vec3 p,float d,float h) {
    vec2 w = vec2(d,abs(p.z) - h);
    return min(max(w.x,w.y),0.) + length(max(w,0.)); 
} 

vec2 rev(vec3 p,float w,float f) {
    return vec2(length(p.xz) - w * f,p.y);
} 

vec3 twist(vec3 p,float k) {
    
    float s = sin(k * p.y);
    float c = cos(k * p.y);
    mat2 m = mat2(c,-s,s,c);
    return vec3(m * p.xz,p.y);
}

float layer(float d,float h) {

    return abs(d) - h;
}

float dot2(vec2 v) { return dot(v,v); }
float dot2(vec3 v) { return dot(v,v); }
float ndot(vec2 a,vec2 b) { return a.x * b.x - a.y * b.y; }

float circle(vec2 p,float r) {
    return length(p) - r;
}

float ring(vec2 p,float r,float w) {
    return abs(length(p) - r) - w;
}

float eqTriangle(vec2 p,float r) { 

     const float k = sqrt(3.);

     p.x = abs(p.x) - 1.;
     p.y = p.y + 1./k;

     if(p.x + k * p.y > 0.) {
         p = vec2(p.x - k * p.y,-k * p.x - p.y)/2.;
     }

     p.x -= clamp(p.x,-2.,0.);
     return -length(p) * sign(p.y);    

} 
float rect(vec2 p,vec2 b) {
    vec2 d = abs(p)-b;
    return length(max(d,0.)) + min(max(d.x,d.y),0.);
}

float roundRect(vec2 p,vec2 b,vec4 r) {
    r.xy = (p.x > 0.) ? r.xy : r.xz;
    r.x  = (p.y > 0.) ? r.x  : r.y;
    vec2 q = abs(p) - b + r.x;
    return min(max(q.x,q.y),0.) + length(max(q,0.)) - r.x;
}

float rhombus(vec2 p,vec2 b) {
   vec2 q = abs(p);
   float h = clamp(-2. * ndot(q,b)+ndot(b,b) / dot(b,b),-1.,1.);
   float d = length(q - .5 * b * vec2(1.- h,1. + h));
   return d * sign(q.x*b.y + q.y*b.x - b.x*b.y);  
}

float segment(vec2 p,vec2 a,vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba),0.,1.);  
    return length(pa - ba * h);
}

float sphere(vec3 p,float r) { 
     
    return length(p) - r;
}

float nsphere(vec3 p,float r) {

    return abs(length(p)-r);
}

float ellipsoid(vec3 p,vec3 r) {

    float k0 = length(p/r); 
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float cone(vec3 p,vec2 c) {

    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.z)),p.y);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
}

float solidAngle(vec3 p,vec2 c,float ra) {
    
    vec2 q = vec2(length(vec2(p.x,p.z)),p.y);
    float l = length(q) - ra;
    float m = length(q - c * clamp(dot(q,c),0.0,ra));
    return max(l,m * sign(c.y * q.x - c.x * q.y));
}

float link(vec3 p,float le,float r1,float r2) {

    vec3 q = vec3(p.x,max(abs(p.y) -le,0.0),p.z);
    return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float plane(vec3 p,vec4 n) {

    return dot(p,n.xyz) + n.w;
}

float capsule(vec3 p,vec3 a,vec3 b,float r) {

    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
    return length(pa - ba * h) - r;
} 

float prism(vec3 p,vec2 h) {

    vec3 q = abs(p);
    return max(q.z - h.y,max(q.x * 0.866025 + p.y * 0.5,-p.y) - h.x * 0.5); 
}

float box(vec3 p,vec3 b) {

    vec3 d = abs(p) - b;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float roundbox(vec3 p,vec3 b,float r) {

    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float torus(vec3 p,vec2 t) {

    vec2 q = vec2(length(vec2(p.x,p.z)) - t.x,p.y);
    return length(q) - t.y; 
}

float capTorus(vec3 p,vec2 sc,float ra,float rb) {
    p.x = abs(p.x);
    float k = (sc.y * p.x > sc.x * p.y) ? dot(p.xy,sc) : length(p.xy);
    return sqrt(dot(p,p) + ra*ra - 2.*k*ra) - rb;
}

float cylinder(vec3 p,float h,float r) {
    
    float d = length(vec2(p.x,p.z)) - r;
    d = max(d, -p.y - h);
    d = max(d, p.y - h);
    return d; 
}

float hexPrism(vec3 p,vec2 h) {
 
    const vec3 k = vec3(-0.8660254,0.5,0.57735);
    p = abs(p); 
    p.xy -= 2.0 * min(dot(k.xy,p.xy),0.0) * k.xy;
 
    vec2 d = vec2(length(p.xy - vec2(clamp(p.x,-k.z * h.x,k.z * h.x),h.x)) * sign(p.y-h.x),p.z-h.y);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float octahedron(vec3 p,float s) {

    p = abs(p);

    float m = p.x + p.y + p.z - s;
    vec3 q;

    if(3.0 * p.x < m) {
       q = vec3(p.x,p.y,p.z);  
    } else if(3.0 * p.y < m) {
       q = vec3(p.y,p.z,p.x); 
    } else if(3.0 * p.z < m) { 
       q = vec3(p.z,p.x,p.y);
    } else { 
       return m * 0.57735027;
    }

    float k = clamp(0.5 *(q.z-q.y+s),0.0,s);
    return length(vec3(q.x,q.y-s+k,q.z - k)); 
}

float trefoil(vec3 p,vec2 t,float n,float l,float e) {

    vec2 q = vec2(length(p.xz)-t.x,p.y);     

    float a = atan(p.x,p.z);
    float c = cos(a*n);
    float s = sin(a*n);

    mat2 m = mat2(c,-s,s,c);    
    q *= m;

    q.y = abs(q.y)-l;

    return (length(q) - t.y)*e;

}

float gyroid(vec3 p,float s,float b,float v,float d) {

    p *= s;
    float g = abs(dot(sin(p),cos(p.zxy))-b)/s-v;
    return max(d,g*.5);

} 

float menger(vec3 p,int n,float s,float d) {

    for(int i = 0; i < n; i++) {

        vec3 a = mod(p * s,2.)-1.;
        s *= 3.;

        vec3 r = abs(1. - 3. * abs(a)); 
       
        float b0 = max(r.x,r.y);
        float b1 = max(r.y,r.z);
        float b2 = max(r.z,r.x);

        float c = (min(b0,min(b1,b2)) - 1.)/s;         
        d = max(d,c);
     }

     return d;
}

vec2 scene(vec3 p) {

    vec2 res = vec2(1.,0.);

    float d = 0.;     
    float s = 0.001;
    float t = time;  
    
    vec3 q = p;

    p.xz *= rot2(t*s);
    p.zy *= rot2(t*s);

    d = box(p,vec3(1.));
    d = menger(p,5,1.,box(p,vec3(1.)));
    d = gyroid(p,6.,.5,.05,box(p,vec3(1.)));
    d = menger(p,4,2.,octahedron(p,1.));
    d = menger(p,4,1.,box(p,vec3(1.))); 
    d = gyroid(p,5.,.35,.015,sphere(p,1.));
    d = gyroid(p,6.,.5,.05,box(p,vec3(1.)));
    d = trefoil(p,vec2(1.5,.25),3.,.25,.5); 
    d = circle(rev(p,0.,pow(2.,1./3.)),1.);

    //d = max(-plane(q*.5,vec4(1.,-1.,-1.,0.)),d);

    res = opu(res,vec2(d,2.)); 

    float pl = plane(q+vec3(0.,1.5,0.),vec4(0.,1.,0.,1.));
    res = opu(res,vec2(pl,1.));
  
  return res;

}

vec2 rayScene(vec3 ro,vec3 rd) {
    
    float d = -1.0;
    float s = dmin;
    float e = dmax;  

    for(int i = 0; i < steps; i++) {

        vec3 p = ro + s * rd;
        vec2 dist = scene(p);
   
        if(abs(dist.x) < eps || e <  dist.x ) { break; }
        s += dist.x;
        d = dist.y;

        }
 
        if(e < s) { d = -1.0; }
        return vec2(s,d);

}

vec3 fog(vec3 col,vec3 fog_col) {
    float fog_depth = 1. - exp(-fog_distance * fog_density);
    return mix(col,fog_col,fog_depth);
}

vec3 scatter(vec3 col,vec3 tf,vec3 ts,vec3 rd,vec3 l) {
    float fog_depth  = 1. - exp(-fog_distance * fog_density);
    float light_depth = max(dot(rd,l),0.);
    vec3 fog_col = mix(tf,ts,pow(light_depth,8.));
    return mix(col,fog_col,light_depth);
}

float ao(vec3 p,vec3 n) {

    float o = 0.;
    float s = 1.;

    for(int i = 0; i < aosteps; i++) {
 
        float h = .01 + .125 * float(i) / 4.; 
        float d = scene(p + h * n).x;  
        o += (h-d) * s;
        s *= .9;
        if(o > .33) break;
    
     }

     return clamp(1. + 3. * o ,0.0,1.0) * (.5+.5*n);   
}


float shadow(vec3 ro,vec3 rd ) {

    float res = 1.0;
    float t = 0.005;
    float ph = 1e10;
    
    for(int i = 0; i < shsteps; i++ ) {
        
        float h = scene(ro + rd * t  ).x;

        float y = h * h / (2. * ph);
        float d = sqrt(h*h-y*y);         
        res = min(res,shblur * d/max(0.,t-y));
        ph = h;
        t += h;
    
        if(res < eps || t > shmax) { break; }

        }

        return clamp(res,0.0,1.0);

}

vec3 calcNormal(vec3 p) {

    vec2 e = vec2(1.0,-1.0) * eps;

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


     vec3 vDir = normalize(uv.x * camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 renderPhong(vec2 uv,vec3 n,vec3 light_pos,vec3 ambc,vec3 difc) {

     vec3 ld = normalize(vec3(light_pos - vec3(uv,0.)));
     float dif = max(0.,dot(n,ld));
     vec3 ref = normalize(reflect(-ld,n));
     float spe = pow(max(0.,dot(n,ref)),8.); 
     return min(vec3(1.),ambc + difc * dif + spe);
}

vec3 renderNormals(vec3 ro,vec3 rd) {

   vec2 d = rayScene(ro,rd);
   vec3 p = ro + rd * d.x;
   vec3 n = calcNormal(p);   
   vec3 col = vec3(n);
   
   return col;
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

if(d.y == 1.) {

    linear += dif * vec3(.5);
    linear += amb * vec3(.05);
    linear += ref * vec3(4.);
    linear += fre * vec3(.25);

    col = vec3(.5);

}

if(d.y == 2.) {

    linear += dif * vec3(hash(135.),hash(34.),hash(344.));
    linear += amb * vec3(.05);
    linear += ref * vec3(hash(245.),hash(123.),hash(335.)) * .04;
    linear += fre * vec3(hash(126.),hash(45.),hash(646.))  * .6; 

    float nl;
    nl = f3(p+f3(p,5,.5),6,.5);
    nl = f3(p+sin3(p,10.),5,cos(p.y));

    col += fmCol(p.y + nl,vec3(hash(112.),hash(33.),hash(21.)),
                          vec3(hash(12.),hash(105.),hash(156.)), 
                          vec3(hash(32.),hash(123.),hash(25.)),         
                          vec3(hash(10.),hash(15.),hash(27.)));               
                        
}

col = col * linear;
col += 5. * spe * vec3(hash(146.),hash(925.),hash(547.));

col = mix(col,vec3(1.),1. - exp(-.0001 * d.x * d.x * d.x));

} 

return col;
}

void main() {
 
vec3 color = vec3(0.);

vec3 cam_tar = cam_target;
vec3 cam_pos = cam_position;

for(int k = 0; k < aa; ++k) {
    for(int l = 0; l < aa; ++l) {

    vec2 o = vec2(float(l),float(k)) / float(aa) * .5;

    vec2 uv = -1. + 2. * (gl_FragCoord.xy + o) / resolution.xy; 
    uv.x *= resolution.x/resolution.y; 

    vec3 dir = rayCamDir(uv,cam_pos,cam_tar,fov); 
    vec3 col = render(cam_pos,dir);  
    color += col;
    }

color /= float(aa*aa);
color = pow(color,vec3(.4545));
FragColor = vec4(color,1.0);
}

}
