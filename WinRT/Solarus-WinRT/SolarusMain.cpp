#if defined(WINRT)
bool XAMLWasEnabled = false;
#endif

#include <SDL.h>

#include "solarus/core/Arguments.h"
#include "solarus/core/Debug.h"
#include "solarus/core/MainLoop.h"
#include <iostream>
#include <string>

int main(int argc, char** argv) {

	using namespace Solarus;

	Debug::set_abort_on_die(true);  // Better for debugging (get a callstack).

	// Store the command-line arguments.
	std::vector<std::string> arguments = { "Solarus Game" };

	arguments.push_back("-suspend-unfocused=no");

	// Set your quest path here, example "Assets/voadi.solarus"

	// std::string quest_path = "Assets/voadi.solarus"
	// arguments.push_back(quest_path);

	std::vector<char*> argvV;
	for (const auto& arg : arguments)
		argvV.push_back((char*)arg.data());
	argvV.push_back(nullptr);

	// Store the command-line arguments.
	const Solarus::Arguments args(argvV.size() - 1, argvV.data());

	MainLoop(args).run();

	return 0;
}


