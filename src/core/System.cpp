/*
 * Copyright (C) 2006-2019 Christopho, Solarus - http://www.solarus-games.org
 *
 * Solarus is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Solarus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#include "solarus/audio/Sound.h"
#include "solarus/core/FontResource.h"
#include "solarus/core/InputEvent.h"
#include "solarus/core/QuestFiles.h"
#include "solarus/core/Random.h"
#include "solarus/core/System.h"
#include "solarus/graphics/Color.h"
#include "solarus/graphics/Sprite.h"
#include "solarus/graphics/Video.h"
#if _POSIX_C_SOURCE >= 200112L
#  include <stdlib.h>
#  include <string.h>
#endif
#include <SDL.h>
#ifdef SOLARUS_USE_APPLE_POOL
#  include "lowlevel/apple/AppleInterface.h"
#endif

namespace Solarus {

uint32_t System::initial_time = 0;
uint32_t System::ticks = 0;

/**
 * \brief Initializes the basic low-level system.
 *
 * Initializes the audio system, the video system,
 * the data file system, etc.
 *
 * \param args Command-line arguments.
 */
void System::initialize(const Arguments& args) {

#if _POSIX_C_SOURCE >= 200112L
  // Back up state of environment variables about to be modified.
  char* sdl_video_x11_wmclass = getenv("SDL_VIDEO_X11_WMCLASS");
  if(sdl_video_x11_wmclass != NULL) {
    sdl_video_x11_wmclass = strdup(sdl_video_x11_wmclass);
  }

  char* sdl_video_wayland_wmclass = getenv("SDL_VIDEO_WAYLAND_WMCLASS");
  if(sdl_video_wayland_wmclass != NULL) {
    sdl_video_wayland_wmclass = strdup(sdl_video_wayland_wmclass);
  }

  // Set AppID that SDL should report on Wayland and X11.
  setenv("SDL_VIDEO_X11_WMCLASS", SOLARUS_APP_ID ".Runner", 1);
  setenv("SDL_VIDEO_WAYLAND_WMCLASS", SOLARUS_APP_ID ".Runner", 1);
#endif

  // initialize SDL
  SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK);
  initial_time = get_real_time();
  ticks = 0;

#if _POSIX_C_SOURCE >= 200112L
  // Restore environment variable state.
  if(sdl_video_wayland_wmclass != NULL) {
    setenv("SDL_VIDEO_WAYLAND_WMCLASS", sdl_video_wayland_wmclass, 1);
    free(sdl_video_wayland_wmclass);
    sdl_video_wayland_wmclass = NULL;
  } else {
    unsetenv("SDL_VIDEO_WAYLAND_WMCLASS");
  }

  if(sdl_video_x11_wmclass != NULL) {
    setenv("SDL_VIDEO_X11_WMCLASS", sdl_video_x11_wmclass, 1);
    free(sdl_video_x11_wmclass);
    sdl_video_x11_wmclass = NULL;
  } else {
    unsetenv("SDL_VIDEO_X11_WMCLASS");
  }
#endif

  // audio
  Sound::initialize(args);

  // input
  InputEvent::initialize(args);

  // random number generator
  Random::initialize();

  // video
  Video::initialize(args);
  FontResource::initialize();
  Sprite::initialize();
}

/**
 * \brief Closes the low-level system.
 *
 * This closes all initializations made in initialize().
 */
void System::quit() {

  Random::quit();
  InputEvent::quit();
  Sound::quit();
  Sprite::quit();
  FontResource::quit();
  Video::quit();

  SDL_Quit();
}

/**
 * \brief This function is called repeatedly by the main loop.
 *
 * It calls the update function of low-level systems that need it.
 */
void System::update() {

  // Use a constant timestep here to have deterministic updates.
  ticks += timestep;
  Sound::update();
}

/**
 * \brief Returns the name of the running OS.
 *
 * Possible values are "Windows", "Mac OS X", "Linux", "iOS" and "Android".
 *
 * If the correct OS name is not available, returns a string
 * beginning with the text "Unknown".
 *
 * \return the name of the running OS.
 */
std::string System::get_os() {
  return SDL_GetPlatform();
}

/**
 * \brief Returns the number of simulated milliseconds elapsed since the
 * main loop started.
 *
 * Follows to the real time unless the system is too slow to play at
 * normal speed.
 *
 * \return The number of simulated milliseconds elapsed since the
 * initialization.
 */
uint32_t System::now() {
  return ticks;
}

/**
 * \brief Returns the number of real milliseconds elapsed since the
 * initialization of the Solarus library.
 *
 * This function is not deterministic, so use it at your own risks.
 *
 * \return The number of milliseconds elapsed since the initialization.
 */
uint32_t System::get_real_time() {
  return SDL_GetTicks() - initial_time;
}

/**
 * \brief Makes the program sleep during some time.
 *
 * Due to the OS scheduling, the real delay may be longer.
 *
 * \param duration duration of the sleep in milliseconds
 */
void System::sleep(uint32_t duration) {
  SDL_Delay(duration);
}

}

