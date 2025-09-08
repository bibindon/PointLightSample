float4x4 g_matWorldViewProj;
float4x4 g_matWorld;
float4 g_eyePos; // 視点（ワールド）

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

    // スケールは等方なので float3x3 でOK（非等方なら逆転置行列を使用）
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

    float3 ambient = 0.20 * baseColor; // 環境光

    float3 V = normalize(g_eyePos.xyz - inWorldPos); // 視線ベクトル

    float3 sum = 0;

    [unroll]
    for (int i = 0; i < g_numLights; i++)
    {
        float3 Lvec = g_pointLights[i].pos - inWorldPos;
        float dist = length(Lvec);

        if (dist < g_pointLights[i].range)
        {
            float3 L = Lvec / dist;
            float NdotL = max(dot(N, L), 0);

            // 距離減衰（線形）
            float atten = 1.0 - (dist / g_pointLights[i].range);
            atten = saturate(atten);

            // 簡易スペキュラ（Blinn-Phong）
            float3 H = normalize(L + V);
            float spec = pow(max(dot(N, H), 0), 32.0);

            float3 diff = baseColor * g_pointLights[i].color * NdotL * 3;
            float3 specC = g_pointLights[i].color * spec * 10.25; // 強すぎないよう係数

            sum += (diff + specC) * atten;
        }
    }

    outColor = float4(ambient + sum, 1.0);
}

technique Technique1
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
