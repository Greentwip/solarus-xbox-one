#ifndef SDL_render_d3d11_h_
#define SDL_render_d3d11_h_

#ifdef __WINRT__

#include "../src/core/windows/SDL_windows.h"
#include "SDL_hints.h"
#include "SDL_loadso.h"
#include "SDL_syswm.h"
#include "../src/render/SDL_sysrender.h"
#include "../src/render/SDL_d3dmath.h"

#include <d3d11_1.h>

#include "../src/render/direct3d11/SDL_shaders_d3d11.h"


#if NTDDI_VERSION > NTDDI_WIN8
#include <DXGI1_3.h>
#endif


/* !!! FIXME: vertex buffer bandwidth could be significantly lower; move color to a uniform, only use UV coords
   !!! FIXME:  when textures are needed, and don't ever pass Z, since it's always zero. */

   /* Vertex shader, common values */
typedef struct
{
	Float4X4 model;
	Float4X4 projectionAndView;
} VertexShaderConstants;

/* Per-vertex data */
typedef struct
{
	Float3 pos;
	Float2 tex;
	Float4 color;
} VertexPositionColor;

/* Per-texture data */
typedef struct
{
	ID3D11Texture2D *mainTexture;
	ID3D11ShaderResourceView *mainTextureResourceView;
	ID3D11RenderTargetView *mainTextureRenderTargetView;
	ID3D11Texture2D *stagingTexture;
	int lockedTexturePositionX;
	int lockedTexturePositionY;
	D3D11_FILTER scaleMode;

	/* YV12 texture support */
	SDL_bool yuv;
	ID3D11Texture2D *mainTextureU;
	ID3D11ShaderResourceView *mainTextureResourceViewU;
	ID3D11Texture2D *mainTextureV;
	ID3D11ShaderResourceView *mainTextureResourceViewV;

	/* NV12 texture support */
	SDL_bool nv12;
	ID3D11Texture2D *mainTextureNV;
	ID3D11ShaderResourceView *mainTextureResourceViewNV;

	Uint8 *pixels;
	int pitch;
	SDL_Rect locked_rect;
} D3D11_TextureData;

/* Blend mode data */
typedef struct
{
	SDL_BlendMode blendMode;
	ID3D11BlendState *blendState;
} D3D11_BlendMode;


/* Private renderer data */
typedef struct
{
    void *hDXGIMod;
    void *hD3D11Mod;
    IDXGIFactory2 *dxgiFactory;
    IDXGIAdapter *dxgiAdapter;
    ID3D11Device1 *d3dDevice;
    ID3D11DeviceContext1 *d3dContext;
    IDXGISwapChain1 *swapChain;
    DXGI_SWAP_EFFECT swapEffect;
    ID3D11RenderTargetView *mainRenderTargetView;
    ID3D11RenderTargetView *currentOffscreenRenderTargetView;
    ID3D11InputLayout *inputLayout;
    ID3D11Buffer *vertexBuffers[8];
    size_t vertexBufferSizes[8];
    ID3D11VertexShader *vertexShader;
    ID3D11PixelShader *pixelShaders[NUM_SHADERS];
    int blendModesCount;
    D3D11_BlendMode *blendModes;
    ID3D11SamplerState *nearestPixelSampler;
    ID3D11SamplerState *linearSampler;
    D3D_FEATURE_LEVEL featureLevel;

    /* Rasterizers */
    ID3D11RasterizerState *mainRasterizer;
    ID3D11RasterizerState *clippedRasterizer;

    /* Vertex buffer constants */
    VertexShaderConstants vertexShaderConstantsData;
    ID3D11Buffer *vertexShaderConstants;

    /* Cached renderer properties */
    DXGI_MODE_ROTATION rotation;
    ID3D11RenderTargetView *currentRenderTargetView;
    ID3D11RasterizerState *currentRasterizerState;
    ID3D11BlendState *currentBlendState;
    ID3D11PixelShader *currentShader;
    ID3D11ShaderResourceView *currentShaderResource;
    ID3D11SamplerState *currentSampler;
    SDL_bool cliprectDirty;
    SDL_bool currentCliprectEnabled;
    SDL_Rect currentCliprect;
    SDL_Rect currentViewport;
    int currentViewportRotation;
    SDL_bool viewportDirty;
    Float4X4 identity;
    int currentVertexBuffer;
} D3D11_RenderData;

#endif
#endif