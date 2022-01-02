#version 330 core 

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;
uniform int frame;

uniform vec4 mouse;

uniform sampler2D tex;

uniform int key_x;
uniform int key_z;
uniform int up;
uniform int dn;
uniform int lf;
uniform int ri;

#define SEED 1

#define AA 1
#define EPS 0.0001
#define STEPS 255
#define FOV 2.
#define VFOV 4.
#define NEAR 0.
#define FAR 100.

float dot2(vec2 v) { return dot(v,v); }
float dot2(vec3 v) { return dot(v,v); }
float ndot(vec2 a,vec2 b) { return a.x * b.x - a.y * b.y; }

vec2 cml(vec2 a,vec2 b) {
    return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);
}

vec2 csq(vec2 z) {
    float r = sqrt(length(z));
    float a = atan(z.y,z.x)*.5;
    return r * vec2(cos(a),sin(a));
}

float sine_wave(float x,float f,float a) {
    return a*sin(x/f);
}

float log_polar(vec2 p,float n) {
    p = vec2(log(length(p)),atan(p.y,p.y));
    p *= 6./radians(180.);
    p = fract(p*n)-.5;
    return length(p);
}

float petals(vec2 p,float n,float s) {
    float r = length(p)*s;
    float a = atan(p.y,p.x);
    return cos(a*n);
}

float polygon(vec2 p,float n,float s) {
    float a = atan(p.y,p.x);
    float r = (2.*radians(180.))/n;
    return cos(floor(.5+a/r) * r - a) * length(p)-s;
}

float spiral(vec2 p,float n,float h) {
     float ph = pow(length(p),1./n)*32.;
     p *= mat2(cos(ph),sin(ph),sin(ph),-cos(ph));
     return h-length(p) / 
     sin((atan(p.x,-p.y)
     + radians(180.)/radians(180.)/2.))*radians(180.);
}

float concentric(vec2 p,float h) {
    return cos(length(p))-h;
}

vec2 julia(vec2 p,float n,float b,float f) {
    float k = 0.;
    for(int i = 0; i < 64; i++) {
    p = vec2(p.x*p.x-p.y*p.y,(p.x*p.y))-f;
    if(dot(p,p) > b) {
        break;
    }
    return p;
    }
}

vec2 diag(vec2 uv) {
   vec2 r = vec2(0.);
   r.x = 1.1547 * uv.x;
   r.y = uv.y + .5 * r.x;
   return r;
}

vec3 simplexGrid(vec2 uv) {

    vec3 q = vec3(0.);
    vec2 p = fract(diag(uv));
    
    if(p.x > p.y) {
        q.xy = 1. - vec2(p.x,p.y-p.x);
        q.z = p.y;
    } else {
        q.yz = 1. - vec2(p.x-p.y,p.y);
        q.x = p.x;
    }
    return q;

}

float hyperbola(vec3 p) { 

vec2 l = vec2(length(p.xz) ,-p.y);
float a = 0.5;
float d = sqrt((l.x+l.y)*(l.x+l.y)- 4. *(l.x*l.y-a)) + 0.5; 
return (-l.x-l.y+d)/2.0;

}

uint rand(uint p) {
    uint st = p * 747796405u + 2891336453u; 
    uint wd = ((st >> ((st >> 28u) + 4u)) ^ st) * 277803737u;
    return (wd >> 22u) ^ wd;
}

#ifdef HASH_SINE

float h11(float p) {
    return fract(sin(p)*float(43758.5453+SEED));
}
#else

float h11(float p) {
    uvec2 n = uint(int(p)) * uvec2(1391674541U,SEED);
    uint h = (n.x ^ n.y) * 1391674541U;
    return float(h) * (1./float(0xffffffffU));
}
#endif

vec3 h33(vec3 p) {
   uvec3 h = uvec3(ivec3(  p)) * 
   uvec3(1391674541U,SEED,2860486313U);
   h = (h.x ^ h.y ^ h.z) * uvec3(1391674541U,SEED,2860486313U);
   return vec3(h) * (1.0/float(0xffffffffU));

}
 
vec2 mod289(vec2 p) { return p - floor(p * (1. / 289.)) * 289.; }
vec3 mod289(vec3 p) { return p - floor(p * (1. / 289.)) * 289.; }
vec3 permute(vec3 p) { return mod289(((p * 34.) + 1.) * p); } 

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
  
    p1 = permute(mod289(p1 + vec3(float(SEED))));

    vec3 m = max(.5 - 
    vec3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.);
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

float sin3(vec3 p,float h) {
    return sin(p.x*h)*sin(p.y*h)*sin(p.z*h);
}

float cell(vec3 x,float n) {
    x *= n;
    vec3 p = floor(x);
    vec3 f = fract(x);
 
    float min_dist = 1.0;
    
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            for(int k = -1; k <= 1; k++) { 

                vec3 b = vec3(float(k),float(j),float(i));
                vec3 r = h33( p + b );
                
                vec3 diff = (b + r - f);

                float d = length(diff);
                min_dist = min(min_dist,d);
    
            }
        }
    }
 
    return min_dist;  

}

float n(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f * f * (3.0 - 2.0 * f);
    float q = p.x + p.y * 157.0 + 113.0 * p.z;

    return mix(mix(mix(h11(q + 0.0),h11(q + 1.0),f.x),
           mix(h11(q + 157.0),h11(q + 158.0),f.x),f.y),
           mix(mix(h11(q + 113.0),h11(q + 114.0),f.x),
           mix(h11(q + 270.0),h11(q + 271.0),f.x),f.y),f.z);
}

float f(vec3 p) {
    float q = 1.;

    mat3 m = mat3(vec2(.8,.6),-.6,
                  vec2(-.6,.8),.6,
                  vec2(-.8,.6),.8);

    q += .5      * n(p); p = m*p*2.01;
    q += .25     * n(p); p = m*p*2.04;
    q += .125    * n(p); p = m*p*2.048;
    q += .0625   * n(p); p = m*p*2.05;
    q += .03125  * n(p); p = m*p*2.07; 
    q += .015625 * n(p); p = m*p*2.09;
    q += .007825 * n(p); p = m*p*2.1;
    q += .003925 * n(p);

    return q / .94;
}

float dd(vec3 p) {
    vec3 q = vec3(f(p+vec3(0.,1.,2.)),
                  f(p+vec3(4.,2.,3.)),
                  f(p+vec3(2.,5.,6.)));
    vec3 r = vec3(f(p + 4. * q + vec3(4.5,2.4,5.5)),
                  f(p + 4. * q + vec3(2.25,5.,2.)),
                  f(p + 4. * q + vec3(3.5,1.5,6.)));
    return f(p + 4. * r);
}

float expStep(float x,float k) {
    return exp((x*k)-k);
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
    float a = radians(180.) * (k * x - 1.0);
    return sin(a)/a;
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

vec3 fmCol(float t,vec3 a,vec3 b,vec3 c,vec3 d) {
    return a + b * cos((radians(180.)*2.0) * (c * t + d));
}

vec3 rgbHsv(vec3 c) {
    vec3 rgb = clamp(abs(
    mod(c.x * 6. + vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);

    rgb = rgb * rgb * (3. - 2. * rgb);
    return c.z * mix(vec3(1.),rgb,c.y);
}

vec3 wbar(vec2 uv,vec3 fcol,vec3 col,float y,float h) {
    return mix(fcol,col,step(abs(uv.y-y),h));
}

vec3 hbar(vec2 uv,vec3 fcol,vec3 col,float x,float w) {
    return mix(fcol,col,step(abs(uv.x-x),w));
}

vec2 boxBound(vec3 ro,vec3 rd,vec3 rad) {
    vec3 m =  1./rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    return vec2(max(max(t1.x,t1.y),t1.z),
                min(min(t2.x,t2.y),t2.z));
}

float bayer(vec2 rc,int n) {
    float c = 0.;
    for(int i = 0; i < n; i++) {
        vec2 s;
        if(i == 0) {
            s = vec2(2.);
        } else if(i == 1) {
            s = vec2(4.);
        } else if(i == 2) {
            s = vec2(8.);
        };

        vec2 t = mod(rc,s)/s;
        int d = int(dot(floor(t*2.),vec2(2.,1.)));
        float b = 0.;

        if(d == 0) {
            b = 0.; 
        } else if(d == 1) {
            b = 2.;
        } else if(d == 2) {
            b = 3.;
        } else {  b = 1.; }

        if(i == 0) {
            c += b * 16.;
        } else if(i == 1) {
            c += b * 4.;
        } else if(i == 2) {
            c += b * 1.;
        }
    }
return c / 64.;
}

float plot(vec2 p,float x,float h) {
    return smoothstep(x-h,x,p.y) -
           smoothstep(x,x+h,p.y);
}

float ls(float a,float b,float t,float n) {
     float f = mod(t,n);
     return clamp((f-a)/(b-a),0.,1.);
}

vec3 repLim(vec3 p,float c,vec3 l) { 
    vec3 q = p - c * clamp( floor((p/c)+0.5) ,-l,l);
    return q; 
}

vec3 rep(vec3 p,vec3 s) {
    vec3 q = mod(p,s) - 0.5 * s;
    return q;
} 

vec2 atanp(vec2 p,float r) {
    float n = radians(360.)/r;
    float a = atan(p.x,p.y)+n*.5;
    a = floor(a/n)*n;
    return p * mat2(cos(a),-sin(a),sin(a),cos(a));
}

vec2 u(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float smax(float d1,float d2,float k) {
    float h = clamp(0.5 - 0.5 * (d2+d1)/k,0.0,1.0);
    return mix(d2,-d1,h) + k * h * (1.0 - h);
}

float intersect(float d1,float d2,float k) {
    float h = clamp(0.5 + 0.5 * (d2-d1)/k,0.0,1.0);
    return mix(d2,d1,h) + k * h * (1.0 - h);
}

float smin(float d1,float d2,float k) {

    float h = clamp(0.5 + 0.5 * (d2-d1)/k,0.0,1.0);
    return mix(d2,d1,h) - k * h * (1.0 - h);
}

float smin_exp(float d1,float d2,float k) {
    float res = exp2(-k * d1) + exp2(-k * d2);
    return -log2(res)/k;
}

float smin_pow(float d1,float d2,float k) {
     d1 = pow(d1,k);
     d2 = pow(d2,k);
     return pow((d1*d2) / (d1+d2),1./k);
}  

vec2 blend(vec2 d1,vec2 d2,float k) {
    float d = smin(d1.x,d2.x,k);
    float m = mix(d1.y,d2.y,clamp(d1.x-d,0.,1.));
    return vec2(d,m);
}

vec4 el(vec3 p,vec3 h) {
    vec3 q = abs(p) - h;
    return vec4(max(q,0.),min(max(q.x,max(q.y,q.z)),0.));
}

float re(vec3 p,float d,float h) {
    vec2 w = vec2(d,abs(p.z) - h);
    return min(max(w.x,w.y),0.) + length(max(w,0.)); 
} 

vec2 rv(vec3 p,float w,float f) {
    return vec2(length(p.xz) - w * f,p.y);
} 

vec3 tw(vec3 p,float k) {
    
    float s = sin(k * p.y);
    float c = cos(k * p.y);
    mat2 m = mat2(c,-s,s,c);
    return vec3(m * p.xz,p.y);
}

float layer(float d,float h) {
    return abs(d) - h;
}

vec3 scatter(vec3 col,vec3 tf,vec3 ts,vec3 rd,vec3 l,float de) {
    float fog_depth  = 1. - exp(-0.000001 * de);
    float light_depth = max(dot(rd,l),0.);
    vec3 fog_col = mix(tf,ts,pow(light_depth,8.));
    return mix(col,fog_col,light_depth);
}

vec3 lightGlow(vec3 l,vec3 rd,vec3 a,vec3 b,vec3 c,vec3 d) {

    vec3 col = vec3(0.);
    float rad = dot(rd,l);
    col += col * vec3(.5,.12,.25) * expStep(rad,100.);
    col += col * vec3(.5,.1,.15) * expStep(rad,25.);
    col += col * vec3(.1,.5,.05) * expStep(rad,2.);
    col += col * vec3(.15) * expStep(rad,35.);
    return col;
}

vec3 refraction(vec3 a,vec3 n,float e) {
    if(dot(a,n) < 0.) { e = 1./e; }
    else { n = -n; }
    return refract(a,n,e);
}

float glowing(float d,float r,float i) {
    return pow(r/max(d,1e-5),i);
}

mat2 rot(float a) {
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
        oc * axis.z * axis.x + axis.y * s,0.,
    
        oc * axis.x * axis.y + axis.z * s,
        oc * axis.y * axis.y + c, 
        oc * axis.y * axis.z - axis.x * s,0.,

        oc * axis.z * axis.x - axis.y * s,
        oc * axis.y * axis.z + axis.x * s,
        oc * axis.z * axis.z + c,0.,0.,0.,0.,1.);

}

mat3 camera(vec3 ro,vec3 ta,float r) {
     
     vec3 w = normalize(ta - ro); 
     vec3 p = vec3(sin(r),cos(r),0.);           
     vec3 u = normalize(cross(w,p)); 
     vec3 v = normalize(cross(u,w));

     return mat3(u,v,w); 
} 

float circle(vec2 p,float r) {
    return length(p) - r;
}

float circleTan3(vec2 p,vec2 a,vec2 b,vec2 c) {
    float d = distance(a,b);
    float d1 = distance(b,c);
    float d2 = distance(c,a);

    float r = (d-d1+d2)*.5;                 
    float r1 = (d+d1-d2)*.5;
    float r2 = (-d+d1+d2)*.5;

    float de = .0005;
    de = min(de,abs(distance(p,a)-r));
    de = min(de,abs(distance(p,b)-r1));
    de = min(de,abs(distance(p,c)-r2));
    return de;
}

float conePetal(vec2 p,float r1,float r2,float h) {
    p.x = abs(p.x);
    float b = (r1-r2)/h;
    float a = sqrt(1.-b*b);
    float k = dot(p,vec2(-b,a));
    if(k < 0.) return length(p)-r1;
    if(k > a*h) return length(p-vec2(0.,h))-r2;
    return dot(p,vec2(a,b))-r1;
}

float arc(vec2 p,vec2 sca,vec2 scb,float ra,float rb) {
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p,scb) : length(p);
    return sqrt(dot(p,p)+ra*ra-2.*ra*k)-rb;
}

float arch(vec2 p,vec2 c,float r,vec2 w) {
    p.x = abs(p.x);
    float l = length(p);
    p = mat2(-c.x,c.y,c.y,c.x)*p;
    p = vec2((p.y>0.)?p.x:l*sign(-c.x),
             (p.x>0.)?p.y:l);
    p = vec2(p.x,abs(p.y-r))-w;
    return length(max(p,0.)) + min(0.,max(p.x,p.y));
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
    r.xy = (p.x > 0.) ? r.xy : r.zw;
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

float ellipsoid(vec3 p,vec3 r) {
    float k0 = length(p/r); 
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float cone(vec3 p,vec2 c,float h) {
    vec2 q = h*vec2(c.x/c.y,-1.);
    vec2 w = vec2(length(p.xz),p.y);
    vec2 a = w -q * clamp(dot(w,q)/dot(q,q),0.,1.);
    vec2 b = w -q * vec2(clamp(w.x/q.x,0.,1.),1.);
    float k = sign(q.y);
    float d = min(dot(a,a),dot(b,b));
    float s = max(k*(w.x*q.y-w.y*q.x),k*(w.y-q.y));
    return sqrt(d)*sign(s);

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
    return max(q.z - h.y,  
    max(q.x * 0.866025 + p.y * 0.5,-p.y) - h.x * 0.5); 
}

float box(vec3 p,vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float boxFrame(vec3 p,vec3 b,float e) {
    p = abs(p)-b;
    vec3 q = abs(p+e)-e;
 
    return min(min(
        length(max(vec3(p.x,q.y,q.z),0.)) 
        + min(max(p.x,max(q.y,q.z)),0.),
        length(max(vec3(q.x,p.y,q.z),0.))+ 
        min(max(q.x,max(p.y,q.z)),0.)),
        length(max(vec3(q.x,q.y,p.z),0.))+
        min(max(q.x,max(q.y,p.z)),0.));
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

float cylinder(vec3 p,vec3 c) {
    return length(p.xz-c.xy)-c.z;
}

float cylinder(vec3 p,float h,float r) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.) + length(max(d,0.));
}

float hexPrism(vec3 p,vec2 h) {
 
    const vec3 k = vec3(-0.8660254,0.5,0.57735);
    p = abs(p); 
    p.xy -= 2.0 * min(dot(k.xy,p.xy),0.0) * k.xy;
 
    vec2 d = vec2(length(p.xy 
           - vec2(clamp(p.x,-k.z * h.x,k.z * h.x),h.x))
           * sign(p.y-h.x),p.z-h.y);

    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float pyramid(vec3 p,float h) {
    float m2 = h*h + .25;
    p.xz = abs(p.xz);
    p.xz = (p.z>p.x) ? p.zx : p.xz;
    p.xz -= .5;
 
    vec3 q = vec3(p.z,h*p.y-.5*p.x,h*p.x+.5*p.y);
    float s = max(-q.x,0.);
    float t = clamp((q.y-.5*p.z)/(m2+.25),0.,1.);
    float a = m2*(q.x+s)*(q.x+s)+q.y*q.y;
    float b = m2*(q.x+.5*t)*(q.x+.5*t) +(q.y-m2*t)*(q.y-m2*t);
    float d2 = min(q.y,-q.x*m2-q.y*.5) > 0. ? 0. : min(a,b);
    return sqrt((d2+q.z*q.z)/m2) * sign(max(q.z,-p.y));
}

float tetrahedron(vec3 p,float h) {
     vec3 q = abs(p);
     float y = p.y;
     float d1 = q.z-max(y,0.);
     float d2 = max(q.x*.5+y*.5,0.)-min(h,h+y);
     return length(max(vec2(d1,d2),.005)) + min(max(d1,d2),0.);
}

float dodecahedron(vec3 p,float r) {
    vec4 v = vec4(0.,1.,-1.,0.5 + sqrt(1.25));
    v /= length(v.zw);

    float d;
    d = abs(dot(p,v.xyw))-r;
    d = max(d,abs(dot(p,v.ywx))-r);
    d = max(d,abs(dot(p,v.wxy))-r);
    d = max(d,abs(dot(p,v.xzw))-r);
    d = max(d,abs(dot(p,v.zwx))-r);
    d = max(d,abs(dot(p,v.wxz))-r);
    return d;
}
 
float icosahedron(vec3 p,float r) {
    float d;
    d = abs(dot(p,vec3(.577)));
    d = max(d,abs(dot(p,vec3(-.577,.577,.577))));
    d = max(d,abs(dot(p,vec3(.577,-.577,.577))));
    d = max(d,abs(dot(p,vec3(.577,.577,-.577))));
    d = max(d,abs(dot(p,vec3(0.,.357,.934))));
    d = max(d,abs(dot(p,vec3(0.,-.357,.934))));
    d = max(d,abs(dot(p,vec3(.934,0.,.357))));
    d = max(d,abs(dot(p,vec3(-.934,0.,.357))));
    d = max(d,abs(dot(p,vec3(.357,.934,0.))));
    d = max(d,abs(dot(p,vec3(-.357,.934,0.))));
    return d-r;
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

vec2 res = vec2(1.0,0.0);
res = u(res,vec2(icosahedron(p,1.),5.)); 

return res;

}

vec4 trace(vec3 ro,vec3 rd) { 
    float d = -1.0;
    float s = NEAR;
    float e = FAR; 

    for(int i = 0; i < STEPS; i++) {

        vec3 p = ro + s * rd;
        vec2 dist = scene(p);
   
        if(abs(dist.x) < EPS || e <  dist.x ) { break; }
        s += dist.x;
        d = dist.y;

        }

        if(e < s) { d = -1.0; }
        return vec4(s,d,1.,1.);

}

vec4 trace(vec3 ro,vec3 rd,vec3 col) {

float s = NEAR;
float e = FAR;

vec2 d = vec2(EPS,0.01);
float radius = 2. * tan(VFOV/2.) / resolution.y * 2.;

vec4 c = vec4(col,1.);
vec3 bgc = vec3(0.);
float alpha;

for(int i = 0; i < STEPS; i++) {
    float rad = s * radius + FOV * abs(s-.5);
    d.x = scene(ro + s * rd).x; 

    if(d.x < rad) {
        alpha = smoothstep(rad,-rad,d.x);

        c.rgb += c.a * (alpha * c.rgb);
        c.a *= (1.-alpha);

        if(d.x < EPS) break;
    
    }

    s += max(abs(d.x * .9),.001);
    if(s > e) break;
}

bgc = mix(c.rgb,bgc,c.a);
return vec4(bgc,alpha);

}

float glow(vec3 ro,vec3 rd,inout float glow) { 
    float depth = 0.;
    float dmax = 100.;

    for(int i = 0; i < 125; i++ ) {
        float h = scene(ro + rd * depth).x;
        glow += glowing(h,.005,.5);

        if(h < EPS) { return depth; }
        
        depth += h;
    }

    if(dmax <= depth ) { return dmax; }
    return dmax;
}

float reflection(vec3 ro,vec3 rd,inout float ref) { 
    float depth = 0.;
    float dmax = 100.;

    for(int i = 0; i < 125; i++ ) {
        float h = scene(ro + rd * depth).x;
        
        if(h < EPS) { return depth; }
        
        depth += h;
    }

    if(dmax <= depth ) { return dmax; }
    return dmax;
}

float shadow(vec3 ro,vec3 rd ) {
    float res = 1.0;
    float dmax = 2.;
    float t = 0.005;
    float ph = 1e10;
    
    const float maxh = 2.;
    float e = (maxh-ro.y)/rd.y;
    if(e > 0.) dmax = min(dmax,e);    

    for(int i = 0; i < 125; i++ ) {
        
        float h = scene(ro + rd * t  ).x;

        float y = h * h / (2. * ph);
        float d = sqrt(h*h-y*y);         
        res = min(res,100. * d/max(0.,t-y));
        ph = h;
        t += h;
    
        if(res < EPS || t*rd.y+ro.y > dmax) { break; }

        }
        return clamp(res,0.0,1.0);
}

float calcAO(vec3 p,vec3 n) {
    float o = 0.;
    float s = 1.;

    for(int i = 0; i < 15; i++) {
 
        float h = .01 + .125 * float(i) / 4.; 
        float d = scene(p + h * n).x;  
        o += (h-d) * s;
        s *= .9;
        if(o > .33) break;
    
     }
     return clamp(1. - 3. * o ,0.0,1.0) * (.5+.5*n.y);   
}

#ifdef GRADIENT 

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(EPS,0.);
    return normalize(vec3(
    scene(p + e.xyy).x - scene(p - e.xyy).x,
    scene(p + e.yxy).x - scene(p - e.yxy).x,
    scene(p + e.yyx).x - scene(p - e.yyx).x));
}

#else

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(1.0,-1.0) * EPS;
    return normalize(vec3(
    vec3(e.x,e.y,e.y) * scene(p + vec3(e.x,e.y,e.y)).x +
    vec3(e.y,e.x,e.y) * scene(p + vec3(e.y,e.x,e.y)).x +
    vec3(e.y,e.y,e.x) * scene(p + vec3(e.y,e.y,e.x)).x + 
    vec3(e.x,e.x,e.x) * scene(p + vec3(e.x,e.x,e.x)).x

    ));
    
}

#endif

void main() { 
vec3 color = vec3(0.);

vec3 ta = vec3(0.);
vec3 ro = vec3(1.,2.,5.);

#if AA > 1
for(int k = 0; k < AA; k++ ) {
   for(int l = 0; l < AA; l++) {
   
       vec2 o = vec2(float(k),float(l)) / float(AA) * .5;
       vec2 uv = (2.* (gl_FragCoord.xy+o) -
       resolution.xy)/resolution.y;
#else
       vec2 uv = (2.*(gl_FragCoord.xy) -
       resolution.xy)/resolution.y;

#endif

       vec3 c = vec3(0.5);

       mat3 cm = camera(ro,ta,0.);
       vec3 rd = cm * normalize(vec3(uv.xy,5.));
         
       vec4 d = trace(ro,rd);





       vec3 p = ro + rd * d.x;
       vec3 n = calcNormal(p);

       vec3 linear = vec3(0.);
       vec3 r = reflect(rd,n); 
       float ref = smoothstep(-2.,2.,r.y);
    
       float amb = sqrt(clamp(.5+.5*n.x,0.,1.));
       float fre = pow(clamp(1.+dot(n,rd),0.,1.),2.);    
    
       vec3 l = normalize(vec3(10.));
       vec3 h = normalize(l - rd);  

       float dif = clamp(dot(n,l),0.0,1.0);
       float spe = pow(clamp(dot(n,h),0.0,1.0),16.)
       * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

           if(d.y >= 0.) {

           c = .2+.2*sin(2.*d.y+vec3(2.,3.,4.)); 

           dif *= shadow(p,l);
           ref *= shadow(p,r);

           linear += dif * vec3(1.);
           linear += amb * vec3(0.5);
           linear += fre * vec3(.025,.01,.03);
           linear += .25 * spe * vec3(0.04,0.05,.05)*ref;
            
           }                   

       c = c * linear;
       
       #ifdef FOG
       c = mix(c,vec3(1.),1.-exp(-.001*d.x*d.x*d.x)); 
       #endif
      
       c = pow(c,vec3(.4545));
       color += c;
   
#if AA > 1 
   }
}   
   color /= float(AA*AA);
#endif
   fragColor = vec4(color,1.0);


}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}
#version 330 core

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

const int steps = 250;
const float eps = 0.0001;
const float far = 500.;
const float near = .1;

vec2 opu(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 

float sphere(vec3 p,float r) {
    return length(p) - r;
}

float roundCone(vec3 p,float r1,float r2,float h) {

    vec2 q = vec2(length(vec2(p.x,p.y)),p.z);
    float b = (r1-r2)/h;
    float a = sqrt(1.0 - b*b);
    float k = dot(q,vec2(-b,a));

    if( k < 0.0) return length(q) - r1;
    if( k > a*h) return length(q - vec2(0.0,h)) - r2;

    return dot(q,vec2(a,b)) - r1;
} 

vec2 scene(vec3 p) { 

vec3 q = p;

vec2 res = vec2(1.0,0.0);
float scale = float(45.) / radians(180.);

vec2 h = p.xz; 
float r = length(h); 
h = vec2(log(r),atan(h.y,h.x));
h *= scale;
h = mod(h,2.) - 1.;
float mul = r/scale;

float d = 0.;
d = max(roundCone(vec3(h,p.y/mul),1.,.5,2.),-sphere(q,2.1))* mul;
res = opu(res,vec2(d,1.));
res = opu(res,vec2(length(q)-1.,2.));

return res;

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

     vec3 vDir = normalize(uv.x * 
     camRight + uv.y * camUp + camForward * fPersp);  

     return vDir;
}

vec3 render(vec3 ro,vec3 rd,float dist) {

vec3 col = vec3(.5);
vec3 bgcol = vec3(1.) * max(0.,rd.y);

//ro += rd * (dist*.98); 
//vec3 p = ro;
vec3 p = ro + rd * dist;

vec3 n = calcNormal(p);
vec3 l = normalize(vec3(2.,10.,1.));
vec3 h = normalize(l - rd);
vec3 r = reflect(rd,n);

float amb = sqrt(clamp(0.5 + 0.5 * n.y,0.0,1.0));
float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.) * dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

vec3 linear = vec3(.5);

linear += dif * vec3(.15);
linear += amb * vec3(.03);

col = col * linear;
col += 25. * spe * vec3(.5);
col = mix(col,bgcol,1.-exp(.005*dist*dist));

return col;
}

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.);
ro = ta + vec3(cos(time*.1)-4.,2.,sin(time*.25)+3.);

vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;

float fov = 2.;
float vfov = 1.;

vec3 color = vec3(1.);
float dist = eps; 
float d = near;
float m;

float radius = 2. * tan(vfov/2.) / resolution.y * 1.5;
vec3 rd = rayCamDir(uv,ro,ta,fov);

vec4 col_alpha = vec4(0.,0.,0.,1.);
 
for(int i = 0; i < steps; i++ ) {
    float rad = d * radius;
    m    = scene(ro + d * rd).y;
    dist = scene(ro + d * rd).x; 

    if(dist < rad) {
        float alpha = smoothstep(rad,-rad,dist);
        vec3 col = render(ro,rd,d);




        if(m == 2.) {
            col += vec3(0.,.25,0.);
        } 

        col_alpha.rgb += col_alpha.a * (alpha * col.rgb);
        col_alpha.a *= (1. - alpha);


        if(col_alpha.a < eps) break;
    
    }

    d += max(abs(dist * .75 ), .001);
    if(d > far) break;
}

color = mix(col_alpha.rgb,color,col_alpha.a);

fragColor = vec4(pow(color,vec3(.4545)),1.0);
 
}