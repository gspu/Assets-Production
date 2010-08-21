
#define inCloudCoord gl_TexCoord[0]
#define inGroundCoord gl_TexCoord[1]
#define inShadowCoord gl_TexCoord[2]
#define inNoiseCoord gl_TexCoord[3]
#define inCityCoord gl_TexCoord[4]

varying vec3 varTSLight;
varying vec3 varTSView;
varying vec3 varWSNormal;

uniform vec4 fGroundContrast_SelfShadowFactor_MinMaxScatterFactor;

#define fGroundContrast fGroundContrast_SelfShadowFactor_MinMaxScatterFactor.x
#define fSelfShadowFactor fGroundContrast_SelfShadowFactor_MinMaxScatterFactor.y
#define fMinScatterFactor fGroundContrast_SelfShadowFactor_MinMaxScatterFactor.z
#define fMaxScatterFactor fGroundContrast_SelfShadowFactor_MinMaxScatterFactor.w

uniform vec4 fAtmosphereType_Thickness_Contrast_LAOffs; 
    //type indexes the t coordinate on cosAngleToDepth, cosAngleToAbsorption, cosAngleToScatter
    //thickness scales cosAngleToDepth
    //contrast is a lighting parameter

#define fAtmosphereType fAtmosphereType_Thickness_Contrast_LAOffs.x
#define fAtmosphereThickness fAtmosphereType_Thickness_Contrast_LAOffs.y
#define fAtmosphereContrast fAtmosphereType_Thickness_Contrast_LAOffs.z
#define fAtmosphereAbsorptionOffset fAtmosphereType_Thickness_Contrast_LAOffs.w

uniform vec4 fvCityLightColor;
uniform vec4 fCityLightTriggerBias;
uniform vec4 fFresnelEffect;
uniform vec4 fShadowRelHeight;

uniform vec4 fAtmosphereAbsorptionColor;
uniform vec4 fAtmosphereScatterColor;

uniform vec4 fReyleighRate_Amount;

#define fReyleighRate fReyleighRate_Amount.x
#define fReyleighAmount fReyleighRate_Amount.y

uniform vec4 fvCloudSelfShadowColor;
uniform vec4 fvCloudColor;
uniform vec4 fvCloudLayerDrift;
uniform vec4 fvCloudLayerMix;
uniform vec4 fvCityLightCloudDiffusion;

uniform vec4 fCloud_Dens_Thick_CLF_SSF;

#define fCloudLayerDensity      fCloud_Dens_Thick_CLF_SSF.x
#define fCloudLayerThickness    fCloud_Dens_Thick_CLF_SSF.y
#define fCityLightFactor        fCloud_Dens_Thick_CLF_SSF.z
#define fCloudSelfShadowFactor  fCloud_Dens_Thick_CLF_SSF.w

uniform sampler2D cosAngleToDepth_20;
uniform sampler2D cloudMap_20;
uniform sampler2D noiseMap_20;
uniform sampler2D cityLights_20;
uniform samplerCube envMap;

/**********************************/
//  CUSTOMIZATION  (EDITABLE)
/**********************************/
#define SHININESS_FROM       GLOSS_IN_SPEC_ALPHA
#define NORMALMAP_TYPE       CINEMUT_NM
#define DEGAMMA              1
#define DEGAMMA_ENVIRONMENT  1
#define DEGAMMA_TEXTURES     1
#define SANITIZE             0
/**********************************/


#if DEGAMMA
vec4  degamma( in vec4 a ) { return a*a; }
vec3  degamma( in vec3 a ) { return a*a; }
float degamma( in float a) { return a*a; }
vec4  regamma( in vec4 a ) { return sqrt(a); }
vec3  regamma( in vec3 a ) { return sqrt(a); }
float regamma( in float a) { return sqrt(a); }
#else
vec4  degamma( in vec4 a ) { return a; }
vec3  degamma( in vec3 a ) { return a; }
float degamma( in float a) { return a; }
vec4  regamma( in vec4 a ) { return a; }
vec3  regamma( in vec3 a ) { return a; }
float regamma( in float a) { return a; }
#endif

#if DEGAMMA_ENVIRONMENT
    #define degamma_env degamma
#else
    #define degamma_env 
#endif

#if DEGAMMA_TEXTURES
    #define degamma_tex degamma
#else
    #define degamma_tex
#endif

vec4 degamma_glow(vec4 glow)
{
    glow.rgb = degamma_tex(degamma_tex(glow.rgb));
    return glow;
}


float lerp(float a, float b, float t) { return a+t*(b-a); }
vec2 lerp(vec2 a, vec2 b, float t) { return a+t*(b-a); }
vec3 lerp(vec3 a, vec3 b, float t) { return a+t*(b-a); }
vec4 lerp(vec4 a, vec4 b, float t) { return a+t*(b-a); }


float  saturatef(float x) { return clamp(x,0.0,1.0); }
vec2   saturate(vec2 x) { return clamp(x,0.0,1.0); }
vec3   saturate(vec3 x) { return clamp(x,0.0,1.0); }
vec4   saturate(vec4 x) { return clamp(x,0.0,1.0); }

float  luma(vec3 color) { return dot( color, vec3(1.0/3.0, 1.0/3.0, 1.0/3.0) ); }
float  sqr(float x)       { return x*x; }
vec4 expand(vec4 x)   { return x*2.0-1.0; }
vec3 expand(vec3 x)   { return x*2.0-1.0; }
vec2 expand(vec2 x)   { return x*2.0-1.0; }
float  expand(float  x)   { return x*2.0-1.0; }
vec4 bias(vec4 x)     { return x*0.5+0.5; }
vec3 bias(vec3 x)     { return x*0.5+0.5; }
vec2 bias(vec2 x)     { return x*0.5+0.5; }
float  bias(float  x)     { return x*0.5+0.5; }
float  self_shadow(float x) { return (x>0.0)?1.0:0.0; }
float  self_shadow_smooth(float x) { return saturatef(2.0*x); }
float  cityLightTrigger(float fNDotLB) { return saturatef(4.0*fNDotLB); }
float  self_shadow_smooth_ex(float x) { return saturatef(4.0*x); }

float fresnel(float fNDotV)
{
   return degamma(1.0-lerp(0.0,fNDotV,fFresnelEffect.x));
}

float expandPrecision(vec4 src)
{
   return dot(src,(vec4(1.0,256.0,65536.0,0.0)/131072.0));
}

float cosAngleToDepth(float fNDotV)
{
   vec2 res = vec2(1.0) / vec2(1024.0,128.0);
   vec2 mn = res * 0.5;
   vec2 mx = vec2(1.0)-res * 0.5;
   return expandPrecision(texture2DLod(cosAngleToDepth_20,clamp(vec2(fNDotV,fAtmosphereType),mn,mx),0.0)) * fAtmosphereThickness;
}

float cosAngleToAlpha(float fNDotV)
{
   vec2 res = vec2(1.0) / vec2(1024.0,128.0);
   vec2 mn = res * 0.5;
   vec2 mx = vec2(1.0)-res * 0.5;
   return texture2D(cosAngleToDepth_20,clamp(vec2(fNDotV,fAtmosphereType),mn,mx)).a;
}

float soft_min(float m, float x)
{
   return min(m,x);
}

float  atmosphereLighting(float fNDotL) { return saturatef(soft_min(1.0,2.0*fAtmosphereContrast*fNDotL)); }
float  groundLighting(float fNDotL) { return saturatef(soft_min(1.0,2.0*fGroundContrast*fNDotL)); }

vec4 atmosphericScatter(vec3 amb, vec4 dif, float fNDotV, float fNDotL, float fVDotL)
{
   float  vdepth     = cosAngleToDepth(fNDotV) * sqr(saturatef(1.0-fShadowRelHeight.x));
   float  ldepth     = cosAngleToDepth(fNDotL+fAtmosphereAbsorptionOffset) * sqr(saturatef(1.0-fShadowRelHeight.x));
   float  alpha      = cosAngleToAlpha(fNDotV);
   
   vec3  labsorption = pow(fAtmosphereAbsorptionColor.rgb,vec3(fAtmosphereAbsorptionColor.a*ldepth));
   vec3  vabsorption = pow(fAtmosphereAbsorptionColor.rgb,vec3(fAtmosphereAbsorptionColor.a*vdepth*2.0));
   vec3  lscatter    = gl_LightSource[0].diffuse.rgb 
                       * fAtmosphereScatterColor.rgb 
                       * pow(labsorption,vec3(fSelfShadowFactor)) 
                       * (fMinScatterFactor+soft_min(fMaxScatterFactor-fMinScatterFactor,vdepth*2.0));
   
   vec4 rv;
   rv.rgb = regamma( amb + dif.rgb*labsorption*vabsorption 
                  + atmosphereLighting(fNDotL)
                    *lscatter );
   rv.a = dif.a * alpha;
   return rv;
}

vec3 ambientMapping( in vec3 direction )
{
   return degamma_env(textureCubeLod(envMap, direction, 8.0).rgb);
}


void main()
{    
   vec2 CloudCoord = inCloudCoord.xy;
   vec2 GroundCoord = inGroundCoord.xy;
   vec2 ShadowCoord = inShadowCoord.xy;
   vec2 NoiseCoord = inNoiseCoord.xy;
   vec2 CityCoord = inCityCoord.xy;

   vec3 L = normalize(varTSLight);
   vec3 V = normalize(varTSView);
   vec3 N = varWSNormal;
   
   float  fNDotL           = saturatef( L.z ); 
   float  fNDotLB          = saturatef(-L.z + fCityLightTriggerBias.x);
   float  fNDotV           = saturatef( V.z );
   float  fVDotL           = dot(L, V);

   // Attack angle density adjustment   
   vec3 CloudLayerDensitySVC;
   float  fCloudLayerDensityL = fCloudLayerDensity / (abs(L.z)+0.01);
   float  fCloudLayerDensityV = fCloudLayerDensity / (abs(V.z)+0.01);
   CloudLayerDensitySVC.x     = fCloudLayerDensityL * fCloudSelfShadowFactor;
   CloudLayerDensitySVC.y     = fCloudLayerDensityV;
   CloudLayerDensitySVC.z     = fCloudLayerDensity * fCloudSelfShadowFactor;
  
   // Sample cloudmap
   vec2 gc1              =      CloudCoord                                         ;
   vec2 gc2              = lerp(CloudCoord,GroundCoord,0.25 * fCloudLayerThickness);
   vec2 gc4              = lerp(CloudCoord,GroundCoord,0.75 * fCloudLayerThickness);
   vec4 fvCloud1         = texture2D( cloudMap_20, gc1 );
   vec4 fvCloud2         = texture2D( cloudMap_20, gc2 );
   vec4 fvCloud4         = texture2D( cloudMap_20, gc4 );
   
   vec2 sc2              = lerp(gc2,ShadowCoord,0.25 * fCloudLayerThickness);
   vec2 sc4              = lerp(gc4,ShadowCoord,0.75 * fCloudLayerThickness);
   float  fCloudShadow2  = texture2D( cloudMap_20, sc2, 0.5 ).a;
   float  fCloudShadow4  = texture2D( cloudMap_20, sc4, 1.5 ).a;
   
   // Mask heights
   fvCloud1.a            = saturatef((fvCloud1.a-0.5000)*1.0); // 0.5000 - 1.0000
   fvCloud2.a            = saturatef((fvCloud2.a-0.2500)*4.0); // 0.2500 - 0.5000
   fvCloud4.a            = saturatef((fvCloud4.a       )*4.0); // 0.0000 - 0.2500
   
   // Simplified for ps2.a
   const vec2 shadowStep2 = vec2(0.500, 0.800);
   const vec2 shadowStep4 = vec2(0.125, 0.708);
   vec2 fvCloudShadow    = vec2(fCloudShadow2,fCloudShadow4);
   fCloudShadow2         = saturatef( dot(fvCloudShadow - shadowStep2, vec2(0.75)) );
   fCloudShadow4         = saturatef( dot(fvCloudShadow - shadowStep4, vec2(0.75)) );
   
   // Compute self-shadowed cloud color
   vec3 fvAmbient         = gl_Color.rgb * ambientMapping(varWSNormal) * 0.5;
   vec4 fvBaseColor       = vec4(gl_Color.rgb * atmosphereLighting(fNDotL), gl_Color.a);
   vec3 fvCloud1s,fvCloud2s,fvCloud4s;
   vec4 fvCloud, fvCloudE;
   fvCloud1s               = fvCloud1.rgb;
   fvCloud2s               = fvCloud2.rgb*lerp(vec3(1.0),fvCloudSelfShadowColor.rgb,saturatef(fCloudShadow2*CloudLayerDensitySVC.x));
   fvCloud4s               = fvCloud4.rgb*lerp(vec3(1.0),fvCloudSelfShadowColor.rgb,saturatef(fCloudShadow4*CloudLayerDensitySVC.x));
   fvCloud.a               = fvBaseColor.a*dot(fvCloudLayerMix,vec4(fvCloud1.a,fvCloud2.a,fvCloud4.a,fvCloud4.a));
   fvCloud.rgb             = fvCloud4s*fvBaseColor.rgb;
   fvCloud.rgb             = lerp(fvCloud.rgb,fvCloud2s*fvBaseColor.rgb,saturatef(fvCloud2.a*CloudLayerDensitySVC.y));
   fvCloud.rgb             = lerp(fvCloud.rgb,fvCloud1s*fvBaseColor.rgb,saturatef(fvCloud1.a*CloudLayerDensitySVC.y));

   gl_FragColor = atmosphericScatter( fvAmbient, fvCloud, fNDotV, fNDotL, fVDotL );
}

