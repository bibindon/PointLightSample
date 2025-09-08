// simple.fx — diffuse only (no specular)

float4x4 g_matWorldViewProj;
float4x4 g_matWorld;

struct PointLight
{
    float3 pos;
    float range; // 1 reg
    float3 color;
    float pad; // 1 reg
};

PointLight g_pointLights[10];
int g_numLights;

texture texture1;
sampler textureSampler = sampler_state
{
    Texture = (texture1);
    MipFilter = LINEAR;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = WRAP;
    AddressV = WRAP;
};

void VS(in float4 inPosition : POSITION,
        in float3 inNormal : NORMAL0,
        in float2 inTexCoord : TEXCOORD0,

        out float4 outPos : POSITION,
        out float3 outWorldPos : TEXCOORD0,
        out float3 outNormal : TEXCOORD1,
        out float2 outTex : TEXCOORD2)
{
    outPos = mul(inPosition, g_matWorldViewProj);
    outWorldPos = mul(inPosition, g_matWorld).xyz;

    // 等方スケール前提。非等方スケール時は逆転置行列で変換してください。
    outNormal = normalize(mul(inNormal, (float3x3) g_matWorld));
    outTex = inTexCoord;
}

void PS(in float3 inWorldPos : TEXCOORD0,
        in float3 inNormal : TEXCOORD1,
        in float2 inTex : TEXCOORD2,
        out float4 outColor : COLOR)
{
    float3 baseColor = tex2D(textureSampler, inTex).rgb;
    float3 N = normalize(inNormal);

    float3 diffuseSum = 0;

    // ループは固定10回。g_numLights によって有効/無効を切替。
    [unroll]
    for (int i = 0; i < 10; ++i)
    {
        float enabled = (i < g_numLights) ? 1.0 : 0.0;

        float3 Lvec = g_pointLights[i].pos - inWorldPos;
        float dist = length(Lvec);
        float attenuation = 2.f - sqrt(dist * 0.2f);

        if (attenuation < 0.0f)
        {
            attenuation = 0.0f;
        }

        diffuseSum += enabled * (baseColor * g_pointLights[i].color * attenuation);
    }

    float3 ambient = 0.20 * baseColor; // 環境光
    outColor = float4(ambient + diffuseSum, 1.0);
}

technique Technique1
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}

