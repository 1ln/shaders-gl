#version 330 core 

out vec4 fragColor;

uniform vec2 resolution;
uniform float time;
uniform int frame;

//align
//2022

#define FC gl_FragCoord.xy
#define RE resolution
#define T time
#define S smoothstep

#define SEED 1

#define AA 2

#define EPS 0.00001
#define STEPS 255

//zero for no gamma
#define GAMMA .4545

#define PI radians(180.)
#define TAU radians(180.)*2.

#ifdef HASH_INT

float h(float p) {
    uint st = uint(p) * 747796405u + 2891336453u + uint(SEED);
    uint wd = ((st >> ((st >> 28u) + 4u)) ^ st) * 277803737u;
    uint h = (wd >> 22u) ^ wd;
    return float(h) * (1./float(uint(0xffffffff)));
}

#else

float h(float p) {
    return fract(sin(p)*float(43758.5453+SEED));
}

#endif

                        

float expstep(float x,float k) {
    return exp((x*k)-k);
}

vec2 fm(float t,vec2 a,vec2 b,vec2 c,vec2 d) {
    return a + b * cos(TAU * (c * t + d));
}

void main() { 

vec3 c = vec3(0.);
vec3 fc = vec3(0.);

float m_dist = 0.;

for(int i = 0; i < AA; i++ ) {
   for(int k = 0; k < AA; k++) {
   
       vec2 o = vec2(float(i),float(k)) / float(AA) * .5;
       vec2 uv = (2.* (FC+o) -
       RE.xy)/RE.y;

       float d = cell(uv,12.,m_dist); 
       vec2 h = fract(uv); 


    vec2 p = floor(x);
    vec2 f = fract(x);
     
    for(int i = -1; i <= 1; i++) {
        for(int k = -1; k <= 1; k++) {

                vec2 b = vec2(float(k),float(i));

                vec2 r = vec2(h(p.x+b.x+h(p.y+b.y)));
                r = .5 + .5*sin(TAU+T*r);                

                vec2 diff = (b + r - f);

                float d = length(diff);

                md = .5 *
                1./
                max(min(md,2.*d),
                p.x-p.y);                               
                        
        }
    }
 


       c += vec3(d);    
       c += 1.-step(.02,m_dist); 
       c.g += step(.98,h.x) + step(.98,h.y);
       c.rg += fm(c.y,
            vec2(.1,5.),
            vec2(.2,.1),
            vec2(2.,.1),
            vec2(.5,-.5));



       c = pow(c,vec3(GAMMA));
       fc += c;
   }
}   
  
   fc /= float(AA*AA);

   fragColor = vec4(fc,1.0);


}
