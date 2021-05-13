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
#include "solarus/audio/SoundBuffer.h"
#include "solarus/core/Debug.h"
#include "solarus/core/QuestFiles.h"
#include <cstring>  // memcpy
#include <sstream>

namespace Solarus {

namespace {

/**
 * \brief Loads an encoded sound from memory.
 *
 * This function respects the prototype specified by libvorbisfile.
 *
 * \param ptr pointer to a buffer to load
 * \param size size
 * \param nb_bytes number of bytes to load
 * \param datasource source of the data to read
 * \return number of bytes loaded
 */
size_t cb_read(void* ptr, size_t /* size */, size_t nb_bytes, void* datasource) {

  SoundBuffer::SoundFromMemory* mem = static_cast<SoundBuffer::SoundFromMemory*>(datasource);

  const size_t total_size = mem->data.size();
  if (mem->position >= total_size) {
    if (mem->loop) {
      mem->position = 0;
    }
    else {
      return 0;
    }
  }
  else if (mem->position + nb_bytes >= total_size) {
    nb_bytes = total_size - mem->position;
  }

  std::memcpy(ptr, mem->data.data() + mem->position, nb_bytes);
  mem->position += nb_bytes;

  return nb_bytes;
}

/**
 * \brief Seeks the sound stream to the specified offset.
 *
 * This function respects the prototype specified by libvorbisfile.
 *
 * \param datasource Source of the data to read.
 * \param offset Where to seek.
 * \param whence How to seek: SEEK_SET, SEEK_CUR or SEEK_END.
 * \return 0 in case of success, -1 in case of error.
 */
int cb_seek(void* datasource, ogg_int64_t offset, int whence) {

  SoundBuffer::SoundFromMemory* mem = static_cast<SoundBuffer::SoundFromMemory*>(datasource);

  switch (whence) {

  case SEEK_SET:
    mem->position = offset;
    break;

  case SEEK_CUR:
    mem->position += offset;
    break;

  case SEEK_END:
    mem->position = mem->data.size() - offset;
    break;
  }

  if (mem->position >= mem->data.size()) {
    mem->position = mem->data.size();
  }

  return 0;
}

/**
 * \brief Returns the current position in a sound stream.
 *
 * This function respects the prototype specified by libvorbisfile.
 *
 * \param datasource Source of the data to read.
 * \return The current position.
 */
long cb_tell(void* datasource) {

  SoundBuffer::SoundFromMemory* mem = static_cast<SoundBuffer::SoundFromMemory*>(datasource);
  return mem->position;
}

}  // Anonymous namespace.

ov_callbacks SoundBuffer::ogg_callbacks = {
    cb_read,
    cb_seek,
    nullptr,  // close
    cb_tell,
};

/**
 * \brief Creates a new sound buffer.
 */
SoundBuffer::SoundBuffer(const std::string& sound_id):
  id(sound_id),
  buffer(AL_NONE),
  loaded(false) {
}

/**
 * \brief Destroys the sound buffer.
 */
SoundBuffer::~SoundBuffer() {

  if (buffer != AL_NONE) {
    alDeleteBuffers(1, &buffer);
  }
}

/**
 * \brief Returns the id of this sound.
 * \return The sound id.
 */
const std::string& SoundBuffer::get_id() const {
  return id;
}

/**
 * \brief Returns whether this sound data is loaded.
 * \return \c true if this sound is loaded.
 */
bool SoundBuffer::is_loaded() const {
  return loaded;
}

/**
 * \brief Loads and decodes the sound into memory.
 */
void SoundBuffer::load() {

  if (!Sound::is_initialized()) {
    // Sound might be disabled.
    return;
  }

  if (is_loaded()) {
    return;
  }

  std::lock_guard<std::mutex> lock(load_mutex);

  if (is_loaded()) {
    return;
  }

  if (alGetError() != AL_NONE) {
    std::ostringstream oss;
    oss << std::hex << alGetError();
    Debug::error("Previous audio error not cleaned in SoundBuffer::load(): " + oss.str());
  }

  std::string file_name = std::string("sounds/" + id);
  if (id.find(".") == std::string::npos) {
    file_name += ".ogg";
  }

  // Create an OpenAL buffer with the sound decoded by the library.
  buffer = decode_file(file_name);

  // buffer is now AL_NONE if there was an error.
  loaded = true;
}

/**
 * \brief Returns the OpenAL buffer where this sound data is loaded.
 * \return The OpenAL buffer, or AL_NONE if the sound could not be loaded.
 */
ALuint SoundBuffer::get_buffer() const {
  return buffer;
}

/**
 * \brief Loads the specified sound file and decodes its content into an OpenAL buffer.
 * \param file_name name of the file to open
 * \return the buffer created, or AL_NONE if the sound could not be loaded
 */
ALuint SoundBuffer::decode_file(const std::string& file_name) {

  ALuint buffer = AL_NONE;

  if (!QuestFiles::data_file_exists(file_name)) {
    Debug::error(std::string("Cannot find sound file '") + file_name + "'");
    return AL_NONE;
  }

  // load the sound file
  SoundFromMemory mem;
  mem.loop = false;
  mem.position = 0;
  mem.data = QuestFiles::data_file_read(file_name);

  OggVorbis_File file;
  int error = ov_open_callbacks(&mem, &file, nullptr, 0, ogg_callbacks);

  if (error) {
    std::ostringstream oss;
    oss << "Cannot load sound file '" << file_name
        << "' from memory: error " << error;
    Debug::error(oss.str());
  }
  else {

    // read the encoded sound properties
    vorbis_info* info = ov_info(&file, -1);
    ALsizei sample_rate = ALsizei(info->rate);

    ALenum format = AL_NONE;
    if (info->channels == 1) {
      format = AL_FORMAT_MONO16;
    }
    else if (info->channels == 2) {
      format = AL_FORMAT_STEREO16;
    }

    if (format == AL_NONE) {
      Debug::error(std::string("Invalid audio format for sound file '")
          + file_name + "'");
    }
    else {
      // decode the sound with vorbisfile
      std::vector<char> samples;
      int bitstream;
      long bytes_read;
      long total_bytes_read = 0;
      const int buffer_size = 16384;
      char samples_buffer[buffer_size];
      do {
        bytes_read = ov_read(&file, samples_buffer, buffer_size, 0, 2, 1, &bitstream);
        if (bytes_read < 0) {
          std::ostringstream oss;
          oss << "Error while decoding ogg chunk in sound file '"
              << file_name << "': " << bytes_read;
          Debug::error(oss.str());
        }
        else {
          total_bytes_read += bytes_read;
          if (format == AL_FORMAT_STEREO16) {
            samples.insert(samples.end(), samples_buffer, samples_buffer + bytes_read);
          }
          else {
            // mono sound files make no sound on some machines
            // workaround: convert them on-the-fly into stereo sounds
            // TODO find a better solution
            for (int i = 0; i < bytes_read; i += 2) {
              samples.insert(samples.end(), samples_buffer + i, samples_buffer + i + 2);
              samples.insert(samples.end(), samples_buffer + i, samples_buffer + i + 2);
            }
            total_bytes_read += bytes_read;
          }
        }
      }
      while (bytes_read > 0);

      // copy the samples into an OpenAL buffer
      alGenBuffers(1, &buffer);
      ALenum error = alGetError();
      if (error != AL_NO_ERROR) {
        std::ostringstream oss;
        oss << "Failed to generate audio buffer for sound file '" << file_name << "': error " << std::hex << error;
        Debug::error(oss.str());
      }
      alBufferData(buffer,
          AL_FORMAT_STEREO16,
          reinterpret_cast<ALshort*>(samples.data()),
          ALsizei(total_bytes_read),
          sample_rate);
      if (error != AL_NO_ERROR) {
        std::ostringstream oss;
        oss << "Cannot copy the sound samples of '"
            << file_name << "' into buffer " << buffer
            << ": error " << std::hex << error;
        Debug::error(oss.str());
        buffer = AL_NONE;
      }
    }
    ov_clear(&file);
  }

  mem.data.clear();

  return buffer;
}

}  // namespace Solarus
