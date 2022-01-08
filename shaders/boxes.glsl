#version 330 core 

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;

#define SEED 1

#define EPS 0.0001
#define STEPS 75
#define FOV 2.
#define VFOV 1.
#define NEAR 0.
#define FAR 12.

float concentric(vec2 p,float h) {
    return cos(length(p))-h;
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

vec3 fmCol(float t,vec3 a,vec3 b,vec3 c,vec3 d) {
    return a + b * cos((radians(180.)*2.0) * (c * t + d));
}

vec3 rl(vec3 p,float c,vec3 l) { 
    vec3 q = p - c * clamp( floor((p/c)+0.5) ,-l,l);
    return q; 
}

vec3 rp(vec3 p,vec3 s) {
    vec3 q = mod(p,s) - 0.5 * s;
    return q;
} 

vec2 u(vec2 d1,vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
} 


mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    
    return mat2(c,-s,s,c);
}

mat3 camera(vec3 ro,vec3 ta,float r) {
     
     vec3 w = normalize(ta - ro); 
     vec3 p = vec3(sin(r),cos(r),0.);           
     vec3 u = normalize(cross(w,p)); 
     vec3 v = normalize(cross(u,w));

     return mat3(u,v,w); 
} 

float box(vec3 p,vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
}

float boxf(vec3 p,vec3 b,float e) {
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

//table or shelf
float boxf2(vec3 p,vec3 b,float e) {
    p = abs(p)-b;
    vec3 q = abs(p+e)-e;
 
    return min(min(
        length(max(vec3(p.x,q.y,p.z),0.)) 
        + min(max(p.x,max(q.y,q.z)),0.),
        length(max(vec3(q.x,p.y,q.z),0.))+ 
        min(max(q.x,max(p.y,q.z)),0.)),
        length(max(vec3(q.x,q.y,p.z),0.))+
        min(max(q.x,max(q.y,p.z)),0.));
}

//slip or cover
float boxf3(vec3 p,vec3 b,float e) {
    p = abs(p)-b;
    vec3 q = abs(p+e)-e;
 
    return min(min(
        length(max(vec3(p.x,q.y,p.z),0.)) 
        + min(max(p.x,max(q.y,q.z)),0.),
        length(max(vec3(q.x,p.y,p.z),0.))+ 
        min(max(q.x,max(p.y,q.z)),0.)),
        length(max(vec3(q.x,q.y,p.z),0.))+
        min(max(q.x,max(q.y,p.z)),0.));
}

//structure
float boxf4(vec3 p,vec3 b,float e) {
    p = abs(p)-b;
    vec3 q = abs(p+e)-e;
 
    return min(min(
        length(max(vec3(q.x,q.y,p.z),0.)) 
        + min(max(p.x,max(q.y,q.z)),0.),
        length(max(vec3(p.x+q.y,p.y,q.z),0.))+ 
        min(max(q.x,max(p.y,q.z)),0.)),
        length(max(vec3(q.x,q.y,q.z)-.025,0.))+
        min(max(q.x,max(q.y,p.z)),0.));
}

float cylinder(vec3 p,float h,float r) {
    vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
    return min(max(d.x,d.y),0.) + length(max(d,0.));
}

vec2 scene(vec3 p) { 

vec2 res = vec2(1.0,0.0);

if(box(p,vec3(2.,1.6,1.2)) < res.x) {   

   res = u(res,vec2(box(p-vec3(1.1,0.,.25),vec3(.25)),-1.)); 

   res = u(res,vec2(boxf(p-vec3(-1.1,0.,.25),
         vec3(.25),.01),4.));

   res = u(res,vec2(boxf2(p-vec3(-1.1,0.,0.),
         vec3(.5),.01),1.));

   res = u(res,vec2(boxf3(p-vec3(1.1,0.,0.),
         vec3(.5),.01),3.));
   
   res = u(res,vec2(boxf4(p,vec3(.5),.01),2.));

   float scl = .04;

   vec3 q = p;
   q = rl(q/scl,1.5,vec3(5.))*scl;
   res = u(res,vec2(length(q)-.02,4.));

   vec3 l = p;
   l = rp(l,vec3(.05,0.,.05));
   float c = cylinder(l,.024,1e20);
   res = u(res,vec2(max(box(p-vec3(1.,.61,0.),
         vec3(.5,0.,.5)),-c),5.));

}

res = u(res,vec2(p.y+1.,12.));

return res;

}

float shadow(vec3 ro,vec3 rd ) {
    float res = 1.0;
    float dmax = 2.;
    float t = 0.005;
    float ph = 1e10;

    for(int i = 0; i < 25; i++ ) {
        
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

vec3 render(vec3 ro,vec3 rd,float d) {

vec3 p = ro+rd*d;
vec3 n = calcNormal(p);

vec3 linear = vec3(0.);
vec3 r = reflect(rd,n); 
float ref = smoothstep(-2.,2.,r.y);
    
float amb = sqrt(clamp(.5+.5*n.x,0.,1.));
float fre = pow(clamp(1.+dot(n,rd),0.,1.),2.);    
    
vec3 l = normalize(vec3(-2.,5.,-2.));
vec3 h = normalize(l - rd);

float dif = clamp(dot(n,l),0.0,1.0);
float spe = pow(clamp(dot(n,h),0.0,1.0),16.)
* dif * (.04 + 0.9 * pow(clamp(1. + dot(h,rd),0.,1.),5.));

dif *= shadow(p,l);

linear += dif * vec3(.5);
linear += amb * vec3(0.1);
linear += fre * vec3(.25,.01,.01);
linear += spe * vec3(0.4,0.5,.05);
return linear+ref;

} 

void main() {

vec3 ta = vec3(0.);
vec3 ro = vec3(1.,3.,2.);
ro.xz *= rot(time*.1);

vec2 uv = (2.*(gl_FragCoord.xy) -
resolution.xy)/resolution.y;

mat3 cm = camera(ro,ta,0.);
vec3 rd = cm * normalize(vec3(uv.xy,FOV));
        
vec2 d = vec2(EPS,-1.);

float radius = 2. * tan(VFOV/2.) / resolution.y * 1.5;

vec4 fc = vec4(0.,0.,0.,1.);
vec3 c = vec3(.5);

float s = NEAR;
float e = FAR; 

for(int i = 0; i < STEPS; i++ ) {
    float rad = s * radius + .003 * abs(s-.5);
    d = scene(ro + s * rd); 

    if(d.x < rad) {
        float alpha = smoothstep(rad,-rad,d.x);
        c = render(ro,rd,s);

         if(d.y >= 0.) {

            if(d.y == 1.) {
            c *= vec3(0.,0.,.5);
            } 

            if(d.y == 2.) {
            c *= vec3(0.,.05,0.);
            }

            if(d.y == 3.) {
            c *= vec3(.5,0.,0.);
            }

            if(d.y == 4.) {
            c *= vec3(.5);
            }

            if(d.y == 5.) {
            c *= vec3(.01);
            }

            if(d.y == 12.) {
            c *= vec3(.7);
            }

        } 

        fc.rgb += fc.a * (alpha * c.rgb);
        fc.a *= (1. - alpha);

        if(fc.a < EPS) break;
    
    }

    s += max(abs(d.x * .79),EPS);
    if(s > e) break;
}

fc.rgb = mix(fc.rgb,c,fc.a);
fragColor = vec4(pow(fc.rgb,vec3(.4545)),1.0);

}

