//////////////////////////////////////////////////////////////////////
// HLSL File:
// This example is compiled using the fxc shader compiler.
// It is possible directly compile HLSL in VS2013
//////////////////////////////////////////////////////////////////////

// This first constant buffer is special.
// The framework looks for particular variables and sets them automatically.
// See the CommonApp comments for the names it looks for.
cbuffer CommonApp
{
	float4x4 g_WVP;
	float4 g_lightDirections[MAX_NUM_LIGHTS];
	float3 g_lightColours[MAX_NUM_LIGHTS];
	int g_numLights;
	float4x4 g_InvXposeW;
	float4x4 g_W;
};


// When you define your own cbuffer you can use a matching structure in your app but you must be careful to match data alignment.
// Alternatively, you may use shader reflection to find offsets into buffers based on variable names.
// The compiler may optimise away the entire cbuffer if it is not used but it shouldn't remove indivdual variables within it.
// Any 'global' variables that are outside an explicit cbuffer go
// into a special cbuffer called "$Globals". This is more difficult to work with
// because you must use reflection to find them.
// Also, the compiler may optimise individual globals away if they are not used.
cbuffer MyApp
{
	float	g_frameCount;
	float3	g_waveOrigin;
}


// VSInput structure defines the vertex format expected by the input assembler when this shader is bound.
// You can find a matching structure in the C++ code.
struct VSInput
{
	float4 pos:POSITION;
	float4 colour:COLOUR0;
	float3 normal:NORMAL;
	float2 tex:TEXCOORD;
};

// PSInput structure is defining the output of the vertex shader and the input of the pixel shader.
// The variables are interpolated smoothly across triangles by the rasteriser.
struct PSInput
{
	float4 pos:SV_Position;
	float4 colour:COLOUR0;
	float3 normal:NORMAL;
	float2 tex:TEXCOORD;
	float4 mat:COLOUR1;
};

// PSOutput structure is defining the output of the pixel shader, just a colour value.
struct PSOutput
{
	float4 colour:SV_Target;
};

// Define several Texture 'slots'
Texture2D g_materialMap;
Texture2D g_texture0;
Texture2D g_texture1;
Texture2D g_texture2;


// Define a state setting 'slot' for the sampler e.g. wrap/clamp modes, filtering etc.
SamplerState g_sampler;

// The vertex shader entry point. This function takes a single vertex and transforms it for the rasteriser.
void VSMain(const VSInput input, out PSInput output){

//need to use the sin and cos to create a wave like movement
float newY = input.pos.y +(sin(input.pos.y + g_frameCount/8));
float newX = input.pos.x + (sin(input.pos.x + g_frameCount/8));


float4 newPosition = { newX, newY, input.pos.z, input.pos.w };

	output.pos = mul(newPosition, g_WVP);
	//output.colour = input.colour;
	output.normal = input.normal;   // added as it was not being output befoer
	output.tex = input.tex;

	float matMapX = input.pos.x / 1024 + 0.5; // to clamp the position between 0-1  Map ranges in -512 to +512
	float matMapZ = 1-(input.pos.z / 1024 + 0.5) ; // flipping the Z to match the map with the terrain
	float2 newXZ = { matMapX, matMapZ };


	output.mat = g_materialMap.SampleLevel(g_sampler, newXZ, 0);
	output.colour = g_materialMap.SampleLevel(g_sampler, newXZ , 0);

}

// The pixel shader entry point. This function writes out the fragment/pixel colour.
void PSMain(const PSInput input, out PSOutput output)
{

	float3 finalColour;
	 
	 for (int i = 0; i < g_numLights; i++) {
		 float4 dir =  g_lightDirections[i];
		 float3 colour = g_lightColours[i];
		 float intensity = cos(dot(input.normal, dir)); 

		 finalColour += colour * intensity;

	}
		
	 float4 texture0 = g_texture0.Sample(g_sampler, input.tex);
	 float4 texture1 = g_texture1.Sample(g_sampler, input.tex);
	 float4 texture2 = g_texture2.Sample(g_sampler, input.tex);

	 float4 finalTextureColour = { 0,0,0,1 }; // paint it black

	 finalTextureColour = lerp(finalTextureColour, texture0, input.mat.r); // the percentage of red 
	 finalTextureColour = lerp(finalTextureColour, texture1, input.mat.g); // green
	 finalTextureColour = lerp(finalTextureColour, texture2, input.mat.b); // blue




		

	// output.colour = float4(finalColour.r, finalColour.g, finalColour.b,1);	// don't need to specify rbg but, have done so to make it more 
	//output.colour = input.colour;	// 'return' the colour value for this fragment.

	 output.colour = finalTextureColour;
}