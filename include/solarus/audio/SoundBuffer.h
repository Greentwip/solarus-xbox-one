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
#ifndef SOLARUS_SOUND_BUFFER_H
#define SOLARUS_SOUND_BUFFER_H

#include "solarus/core/Common.h"
#include <mutex>
#include <al.h>
#include <vorbis/vorbisfile.h>

namespace Solarus {

/**
 * \brief Stores the PCM data of a sound effect loaded in memory.
 *
 * This only stores the stateless data, it does not handle playing the sound.
 */
class SOLARUS_API SoundBuffer {

public:

  /**
   * \brief Buffer containing an encoded sound file.
   */
  struct SoundFromMemory {
    std::string data;         /**< The OGG encoded data. */
    size_t position;          /**< Current position in the buffer. */
    bool loop;                /**< \c true to restart the sound if it finishes. */
  };

  // functions to load the encoded sound from memory
  static ov_callbacks ogg_callbacks;           /**< vorbisfile object used to load the encoded sound from memory */

  explicit SoundBuffer(const std::string& sound_id);
  ~SoundBuffer();
  const std::string& get_id() const;

  bool is_loaded() const;
  void load();
  ALuint get_buffer() const;

private:

  ALuint decode_file(const std::string& file_name);

  std::string id;                              /**< id of this sound */
  ALuint buffer;                               /**< the OpenAL buffer containing the PCM decoded data of this sound */
  bool loaded;                                 /**< Whether the sound is loaded. */
  std::mutex load_mutex;                       /**< Lock to protect concurrent sound loading. */

};

}

#endif
