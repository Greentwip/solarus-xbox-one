#pragma once

#include "Common\DeviceResources.h"

namespace Solarus {
	class MainLoop;
}

// Renders Direct2D and 3D content on the screen.
namespace Solarus_WinRT_XAML
{
	class Solarus_WinRT_XAMLMain 
	{
	public:
		Solarus_WinRT_XAMLMain(const std::shared_ptr<DX::DeviceResources>& deviceResources);
		~Solarus_WinRT_XAMLMain();
		
		int SolarusMainInit(int argc, char* argv[]);
		int SolarusMainRun();
		void StartGame(std::string quest_path);
		void ReloadGame(std::string quest_path);


		// Cached pointer to device resources.
		std::shared_ptr<DX::DeviceResources> m_deviceResources;

		std::shared_ptr<Solarus::MainLoop> game;

	};
}