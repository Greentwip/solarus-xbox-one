#include "pch.h"
#include "Solarus_WinRT_XAMLMain.h"

using namespace Solarus_WinRT_XAML;
using namespace Windows::Foundation;
using namespace Windows::System::Threading;
using namespace Concurrency;

#include <iostream>

#include <SDL.h>
#include <SDL_opengl.h> 
#include <SDL_main.h>
#include "solarus/core/Arguments.h"
#include "solarus/core/Debug.h"
#include "solarus/core/MainLoop.h"


#include <iostream>
#include <string>
#include <memory>



#include <thread>
#include <chrono>
#include <mutex>
#include <functional>
#include <iostream>
#include <cmath>
#include <tuple>
#include <type_traits>
#include <utility>

#include<tuple>
#include<type_traits>
#include<utility>

#include "FunctionHelper.h"


bool XAMLWasEnabled = true;


// Loads and initializes application assets when the application is loaded.
Solarus_WinRT_XAMLMain::Solarus_WinRT_XAMLMain(const std::shared_ptr<DX::DeviceResources>& deviceResources) :
	m_deviceResources(deviceResources){

}

Solarus_WinRT_XAMLMain::~Solarus_WinRT_XAMLMain()
{

}


int Solarus_WinRT_XAMLMain::SolarusMainInit(int argc, char* argv[]) {

	// Store the command-line arguments.
	const Solarus::Arguments args(argc, argv);

	game = std::make_shared<Solarus::MainLoop>(args);

	return 1;
}

int Solarus_WinRT_XAMLMain::SolarusMainRun()
{
	game->run();

	return 1;
}

void Solarus_WinRT_XAMLMain::StartGame(std::string quest_path)
{

	std::function<int(int, char**)> mainInit = [this, quest_path](int argc, char** argv) {
		using namespace Solarus;

		Debug::set_abort_on_die(true);  // Better for debugging (get a callstack).

		std::vector<std::string> arguments = { "Solarus Game", "-force-software-rendering" };
		arguments.push_back("-suspend-unfocused=no");

		arguments.push_back(quest_path);

		std::vector<char*> argvV;
		for (const auto& arg : arguments)
			argvV.push_back((char*)arg.data());

		argvV.push_back(nullptr);


		return SolarusMainInit(argvV.size() - 1, argvV.data());
	};

	std::function<int()> mainRun = [this]() {
		return SolarusMainRun();
	};

	SDL_WinRTRunApp(fnptr<>::get(mainInit), 
					fnptr<>::get(mainRun), 
					reinterpret_cast<IInspectable*>(m_deviceResources->GetSwapChain()));
}

void Solarus_WinRT_XAMLMain::ReloadGame(std::string quest_path) {

	std::vector<std::string> arguments = { "Solarus Game", "-force-software-rendering" };

	arguments.push_back("-suspend-unfocused=no");

	arguments.push_back(quest_path);

	std::vector<char*> argvV;
	for (const auto& arg : arguments)
		argvV.push_back((char*)arg.data());
	argvV.push_back(nullptr);

	// Store the command-line arguments.
	const Solarus::Arguments args(argvV.size() - 1, argvV.data());
	game->reload_quest(args);
}