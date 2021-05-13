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
#include "solarus/core/CurrentQuest.h"
#include "solarus/core/ResourceProvider.h"
#include "solarus/core/QuestDatabase.h"

namespace Solarus {

/**
 * \brief Creates a resource provider.
 */
ResourceProvider::ResourceProvider() {
}

/**
 * \brief Preloads resources in background in a separate thread.
 */
void ResourceProvider::start_preloading_resources() {

  // Put all resources in the cache, without loading them yet.
  const QuestDatabase& database = CurrentQuest::get_database();
  const QuestDatabase::ResourceMap& tileset_ids = database.get_resource_elements(ResourceType::TILESET);
  std::vector<std::shared_ptr<Tileset>> tilesets_to_preload;
  for (const auto& pair : tileset_ids) {
    const std::string& tileset_id = pair.first;
    std::shared_ptr<Tileset> tileset = std::make_shared<Tileset>(tileset_id);
    tileset_cache.emplace(tileset_id, tileset);
    tilesets_to_preload.emplace_back(tileset);
  }

  const QuestDatabase::ResourceMap& sound_ids = database.get_resource_elements(ResourceType::SOUND);
  std::vector<std::shared_ptr<SoundBuffer>> sounds_to_preload;
  for (const auto& pair : sound_ids) {
    const std::string& sound_id = pair.first;
    std::shared_ptr<SoundBuffer> sound = std::make_shared<SoundBuffer>(sound_id);
    sound_cache.emplace(sound_id, sound);
    sounds_to_preload.emplace_back(sound);
  }

  // Start loading them in a separate thread.
  preloader_thread = std::thread([this, tilesets_to_preload, sounds_to_preload]() {

    for (const std::shared_ptr<SoundBuffer>& sound : sounds_to_preload) {
      if (sound_cache.empty()) {
        // clear() was probably called in the meantime.
        // No reason to continue.
        return;
      }
      sound->load();
      std::this_thread::yield();
    }

    for (const std::shared_ptr<Tileset>& tileset : tilesets_to_preload) {
      if (tileset_cache.empty()) {
        return;
      }
      tileset->load();
      std::this_thread::yield();
    }
  });
}

/**
 * \brief Clears all stored resources.
 */
void ResourceProvider::clear() {

  tileset_cache.clear();
  sound_cache.clear();
  preloader_thread.join();
}

/**
 * \brief Provides the tileset with the given id.
 * \param tileset_id A tileset id.
 * \return The corresponding tileset.
 */
Tileset& ResourceProvider::get_tileset(const std::string& tileset_id) {

  std::shared_ptr<Tileset> tileset;
  const auto it = tileset_cache.find(tileset_id);
  if (it != tileset_cache.end()) {
    tileset = it->second;
  }
  else {
    tileset = std::make_shared<Tileset>(tileset_id);
    tileset_cache.emplace(tileset_id, tileset);
  }

  tileset->load();

  return *tileset;
}

/**
 * \brief Returns all tilesets currently in cache.
 * \return The loaded tilesets.
 */
const std::map<std::string, std::shared_ptr<Tileset>>& ResourceProvider::get_loaded_tilesets() {
  return tileset_cache;
}

/**
 * \brief Provides the sound with the given id.
 * \param sound_id A sound id.
 * \param language_specific \c true to load the sound from the
 * language-specific sound directory.
 * \return The corresponding sound buffer.
 */
SoundBuffer& ResourceProvider::get_sound(const std::string& sound_id, bool /* language_specific */) {

  // TODO handle language

  std::shared_ptr<SoundBuffer> sound;
  const auto it = sound_cache.find(sound_id);
  if (it != sound_cache.end()) {
    sound = it->second;
  }
  else {
    sound = std::make_shared<SoundBuffer>(sound_id);
    sound_cache.emplace(sound_id, sound);
  }

  sound->load();

  return *sound;
}

/**
 * \brief Notifies the resource provider that cached data (if any) is no longer valid.
 *
 * This function must be called when a resource element has changed on disk.
 *
 * \param resource_type Type of resource that has changed.
 * \param element_id Resource element that has changed.
 */
void ResourceProvider::invalidate_resource_element(
    ResourceType resource_type,
    const std::string& element_id) {

  switch (resource_type) {

  case ResourceType::TILESET:
  {
    tileset_cache.erase(element_id);
  }
    break;

  case ResourceType::SOUND:
  {
    sound_cache.erase(element_id);
  }
    break;

  default:
    break;
  }
}

}
