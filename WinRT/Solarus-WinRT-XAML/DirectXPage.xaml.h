//
//
// DirectXPage.xaml.h
// Declaration of the DirectXPage class.
//

#pragma once

#include "DirectXPage.g.h"

#include "Common\DeviceResources.h"
#include "Solarus_WinRT_XAMLMain.h"

namespace Solarus_WinRT_XAML
{
	/// <summary>
	/// A page that hosts a DirectX SwapChainPanel.
	/// </summary>
	public ref class DirectXPage sealed 
	{
	public:
		DirectXPage();
		virtual ~DirectXPage();

		void PageLoaded(Object^ sender, Windows::UI::Xaml::RoutedEventArgs^ e);

	private:

		// Resources used to render the DirectX content in the XAML page background.
		std::shared_ptr<DX::DeviceResources> m_deviceResources;
		std::unique_ptr<Solarus_WinRT_XAMLMain> m_main;
		void LoadQuestButtonClick(Platform::Object^ sender, Windows::UI::Xaml::RoutedEventArgs^ e);
	};
}
