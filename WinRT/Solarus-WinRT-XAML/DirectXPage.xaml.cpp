//
// DirectXPage.xaml.cpp
// Implementation of the DirectXPage class.
//

#include <ppltasks.h>

#include "pch.h"
#include "DirectXPage.xaml.h"

using namespace Solarus_WinRT_XAML;

using namespace Platform;
using namespace Windows::Foundation;
using namespace Windows::Foundation::Collections;
using namespace Windows::Graphics::Display;
using namespace Windows::System::Threading;
using namespace Windows::UI::Core;
using namespace Windows::UI::Input;
using namespace Windows::UI::Xaml;
using namespace Windows::UI::Xaml::Controls;
using namespace Windows::UI::Xaml::Controls::Primitives;
using namespace Windows::UI::Xaml::Data;
using namespace Windows::UI::Xaml::Input;
using namespace Windows::UI::Xaml::Media;
using namespace Windows::UI::Xaml::Navigation;
using namespace concurrency;

using namespace Windows::Storage;
using namespace Windows::Storage::Pickers;


DirectXPage::DirectXPage()
{
	InitializeComponent();

	// At this point we have access to the device. 
	// We can create the device-dependent resources.
	m_deviceResources = std::make_shared<DX::DeviceResources>();
	m_deviceResources->SetSwapChainPanel(swapChainPanel);

	Loaded += ref new RoutedEventHandler(this, &DirectXPage::PageLoaded);
}

DirectXPage::~DirectXPage()
{

}

void DirectXPage::PageLoaded(Object^ sender, RoutedEventArgs^ e)
{
	m_main = std::unique_ptr<Solarus_WinRT_XAMLMain>(new Solarus_WinRT_XAMLMain(m_deviceResources));
	m_main->StartGame("Assets/data/.");
}


void DirectXPage::LoadQuestButtonClick(Platform::Object^ sender, Windows::UI::Xaml::RoutedEventArgs^ e)
{

	// Use the app bar if it is appropriate for your app. Design the app bar, 
	// then fill in event handlers (like this one).

	FileOpenPicker^ openPicker = ref new FileOpenPicker();
	openPicker->ViewMode = PickerViewMode::Thumbnail;
	openPicker->SuggestedStartLocation = PickerLocationId::DocumentsLibrary;
	openPicker->FileTypeFilter->Append(".solarus");

	create_task(openPicker->PickSingleFileAsync()).then([this](StorageFile^ file)
	{
		if (file)
		{
			
			create_task(file->CopyAsync(ApplicationData::Current->LocalFolder, 
										file->Name, 
										NameCollisionOption::ReplaceExisting))
				.then([this](StorageFile^ copiedFile) {

				auto path = copiedFile->Path;
				std::wstring pathW(path->Begin());
				std::string pathMB(pathW.begin(), pathW.end());

				m_main->ReloadGame(pathMB);
			});

		}
	});
}
