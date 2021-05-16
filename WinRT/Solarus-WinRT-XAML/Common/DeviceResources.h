#pragma once

#include "pch.h"


namespace DX
{
	// Controls all the DirectX device resources.
	class DeviceResources
	{
	public:
		DeviceResources();
		void SetSwapChainPanel(Windows::UI::Xaml::Controls::SwapChainPanel^ panel);
		Windows::UI::Xaml::Controls::SwapChainPanel^	GetSwapChain() const { return m_swapChainPanel; }

	private:
		
		Microsoft::WRL::ComPtr<IDXGISwapChain1>         m_swapChain;

		// Cached reference to the XAML panel.
		Windows::UI::Xaml::Controls::SwapChainPanel^	m_swapChainPanel;
	};
}