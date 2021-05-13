#pragma once

#ifdef SOLARUS_PROFILING
#include <easy/profiler.h>

#define SOL_PFUN(...) EASY_BLOCK(__PRETTY_FUNCTION__, __VA_ARGS__)
#define SOL_PBLOCK(...) EASY_BLOCK(__VA_ARGS__)
#define SOL_MAIN_THREAD EASY_MAIN_THREAD

#else
#define SOL_PFUN(...)
#define SOL_PBLOCK(...)
#define SOL_MAIN_THREAD
#endif
