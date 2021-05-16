#include "pch.h"
#include "DeviceResources.h"
#include <windows.ui.xaml.media.dxinterop.h>

using namespace D2D1;
using namespace DirectX;
using namespace Microsoft::WRL;
using namespace Windows::Foundation;
using namespace Windows::Graphics::Display;
using namespace Windows::UI::Core;
using namespace Windows::UI::Xaml::Controls;
using namespace Platform;

// Constructor for DeviceResources.
DX::DeviceResources::DeviceResources() 
{

}

// This method is called when the XAML control is created (or re-created).
void DX::DeviceResources::SetSwapChainPanel(SwapChainPanel^ panel)
{
	m_swapChainPanel = panel;
}