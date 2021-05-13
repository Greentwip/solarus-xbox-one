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
#ifndef SOLARUS_SOUND_H
#define SOLARUS_SOUND_H

#include "solarus/audio/SoundPtr.h"
#include "solarus/core/Common.h"
#include "solarus/lua/ExportableToLua.h"
#include <string>
#include <list>
#include <map>
#include <al.h>
#include <alc.h>
#include <vorbis/vorbisfile.h>

namespace Solarus {

class Arguments;
class ResourceProvider;
class SoundBuffer;

/**
 * \brief Represents a sound effect that can be played in the program.
 *
 * Represents the state of plyaing the sound effect.
 * This class also handles the initialization of the whole audio system.
 */
class SOLARUS_API Sound: public ExportableToLua {

  public:

    static SoundPtr create(const SoundBuffer& data);
    ~Sound();

    const std::string& get_id() const;
    bool start();
    void stop();
    bool is_paused() const;
    void set_paused(bool paused);
    bool is_paused_by_script() const;
    void set_paused_by_script(bool paused_by_script);
    void update_paused();

    static bool exists(const std::string& sound_id);
    static void play(const std::string& sound_id, ResourceProvider& resource_provider);
    static void pause_all();
    static void resume_all();

    static void initialize(const Arguments& args);
    static void quit();
    static bool is_initialized();
    static void update();
    static bool check_openal_clean_state(const std::string& function_name);

    static int get_volume();
    static void set_volume(int volume);

    const std::string& get_lua_type_name() const override;

  private:

    explicit Sound(const SoundBuffer& data);
    bool update_playing();
    void stop_source();

    const SoundBuffer& data;                     /**< The loaded sound data. */
    ALuint source;                               /**< The source currently playing this sound. */
    bool paused_by_script;                       /**< Whether the sound is paused by a Lua script. */
    static bool paused_by_system;                /**< Whether sounds are currently paused by the main loop,
                                                  * e.g. when losing focus */

    static void update_device_connection();

    static bool audio_enabled;                   /**< \c true unless -no-audio was passed. */
    static ALCdevice* device;                    /**< OpenAL device, nullptr if disconnected. */
    static ALCcontext* context;                  /**< OpenAL context. */
    static std::list<SoundPtr>
        current_sounds;                          /**< The sounds currently playing. */

    static float volume;                         /**< the volume of sound effects (0.0 to 1.0) */
    static uint32_t next_device_detection_date;  /**< Date of the next attempt to detect an audio device. */
    static bool pc_play;                         /**< Whether playing performance counter is used. */
};

}

#endif
