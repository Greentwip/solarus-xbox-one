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
#include "solarus/core/Debug.h"
#include "solarus/core/Random.h"
#include "solarus/graphics/Surface.h"
#include <algorithm>
#include <iterator>
#include <random>
#include <set>

namespace Solarus {

/**
 * \brief Creates a quadtree with a default space size.
 *
 * Call initialize() later to specify the size.
 */
template<typename T, typename Comparator>
Quadtree<T, Comparator>::Quadtree() :
    Quadtree(Rectangle(0, 0, 256, 256)) {

}

/**
 * \brief Creates a quadtree and initializes with the given size.
 * \param space Rectangle representing the space to create partitions of.
 */
template<typename T, typename Comparator>
Quadtree<T, Comparator>::Quadtree(const Rectangle& space) :
  space(space)
{
    initialize(space);
}

/**
 * \brief Removes all elements of the quadtree.
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::clear() {
  elements_nodes_storage.clear();
  nodes.clear();

  free_node = -1;
}

/**
 * \brief Clears the quadtree and initializes it with a new size.
 * \param space Rectangle representing the space to create partitions of.
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::initialize(const Rectangle& space) {

  clear();

  // Expand the space so that it is square.
  Rectangle square = space;
  if (space.get_width() > space.get_height()) {
    square.set_y(square.get_center().y - square.get_width() / 2);
    square.set_height(square.get_width());
  }
  else {
    square.set_x(square.get_center().x - square.get_height() / 2);
    square.set_width(square.get_height());
  }

  this->space = square;

  //Allocate root node
  nodes.resize(1);
}

/**
 * \brief Returns the space partitioned by this quadtree.
 * \return The partitioned space.
 */
template<typename T, typename Comparator>
Rectangle Quadtree<T, Comparator>::get_space() const {
    return space;
}

/**
 * \brief Adds an element to the quadtree.
 *
 * It is allowed to add it outside the space delimited by the quadtree,
 * for example if it can move inside later.
 *
 * \param element The element to add.
 * \param bounding_box Bounding box of the element.
 * \return \c true in case of success.
 */
template<typename T, typename Comparator>
bool Quadtree<T, Comparator>::add(const T& element, const Rectangle& bounding_box) {
  SOL_PBLOCK("Solarus::Quadtree::add");

  auto it = elements_infos.find(element);

  if(it != elements_infos.end()) {
    move(element, bounding_box);
    return false;
  }

  int id = elements_nodes_storage.insert({0, bounding_box, element});
  elements_infos.emplace(element, id);

  node_add(0, QuadAxis(get_space()), id);
  return true;
}

/**
 * @brief Adds an element to a node
 * @param nodeid id of the node
 * @param axis axis describing geometry of the node
 * @param element element to add
 * @return
 */
template<typename T, typename Comparator>
bool Quadtree<T, Comparator>::node_add(int nodeid, QuadAxis axis, int element) {
  const auto& elnode = elements_nodes_storage[element];
  auto rect = elnode.rect;
  auto center = rect.get_center();
  auto curr = nodeid;
  for(;;) {
    auto* node = &nodes[curr];
    if (node->is_leaf) {
      // We are the main cell of this element: it counts in the total.
      if (node->count >= max_in_cell &&
          axis.qsize.width > min_cell_size && axis.qsize.height > min_cell_size) {
        node_split(curr, axis);
        node = &nodes[curr]; //Node might have been invalidated
      }
    }

    // Count element in our total
    node->count++;

    if (node->is_leaf) {
      // Add it to the current node.
      if(node->first_child == -1) { //our first element
        node->bounds = rect;
      } else {
        node->bounds |= rect; //extend our bounding box
      }

      element_list_add(node->first_child, element);
      return true;
    }

    node->bounds |= rect; //Augment our quad with new element

    Child dst = axis.where(center);
    curr = node->first_child + static_cast<int>(dst);
    axis = axis.child(dst);
  }
}

/**
 * \brief Removes an element from the quadtree.
 * \param element The element to remove.
 * \return \c true in case of success.
 */
template<typename T, typename Comparator>
bool Quadtree<T, Comparator>::remove(const T& element) {
  SOL_PBLOCK("Solarus::Quadtree::remove");

  auto it = elements_infos.find(element);
  // Normal case.
  if(it == elements_infos.end()) {
    return false;
  }

  int id = it->second;
  elements_infos.erase(element);
  bool res = node_remove(0, QuadAxis(get_space()), id);
  elements_nodes_storage.erase(id);
  return res;
}

/**
 * @brief Removes an element from a node
 * @param nodeid the node id
 * @param axis the axis describing the node geometry
 * @param element the element to remove
 * @return true if the element was removed
 */
template<typename T, typename Comparator>
bool Quadtree<T, Comparator>::node_remove(int nodeid, QuadAxis axis, int element) {
  const auto& elnode = elements_nodes_storage[element];
  auto rect = elnode.rect;
  auto center = rect.get_center();
  auto curr = nodeid; //Root node is always at 0
  for(;;) {
    auto& node = nodes[curr];
    node.count--;
    if(node.is_leaf) {
      return element_list_remove(node.first_child, element);
    }

    Child dst = axis.where(center);
    curr = node.first_child + static_cast<int>(dst);
    axis = axis.child(dst);
  }
}

/**
 * \brief Moves the element in the quadtree.
 *
 * This function should be called when the position or size or the element
 * is changed.
 *
 * It is allowed for an element to go to or come from outside the space of the
 * quadtree.
 *
 * \param element The element to move. If the element is not in the quadtree,
 * does nothing and returns \c false.
 * \param bounding_box New bounding box of the element.
 * \return \c true in case of success.
 */
template<typename T, typename Comparator>
bool Quadtree<T, Comparator>::move(const T& element, const Rectangle& bounding_box) {
  SOL_PBLOCK("Solarus::Quadtree::move");

  auto it = elements_infos.find(element);
  // Normal case.
  if(it == elements_infos.end()) {
    return false;
  }

  node_remove(0, QuadAxis(get_space()), it->second);
  elements_nodes_storage[it->second].rect = bounding_box;
  node_add(0, QuadAxis(get_space()), it->second);
  return true;
}

/**
 * \brief Returns the total number of elements in the quadtree.
 * \return The number of elements, including elements outside the quadtree
 * space.
 */
template<typename T, typename Comparator>
int Quadtree<T, Comparator>::get_num_elements() const {
  return elements_infos.size();
}

/**
 * @brief Does this quadtree contains given element
 * @param element an element
 * @return true if element is contained into this quadtree
 */
template<typename T, typename Comparator>
bool Quadtree<T, Comparator>::contains(const T& element) const {
  return elements_infos.find(element) != elements_infos.end();
}

/**
 * @brief shrinks the quadtree nodes to better fit content, should be called periodically
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::shrink_to_fit() {
  SOL_PFUN("Quadtree::shrink_to_fit");
  node_shrink(0);
}

/**
 * \brief Gets the elements intersecting the given rectangle.
 * \param region The rectangle to check.
 * The rectangle should be entirely contained in the quadtree space.
 * \return A list of elements intersecting the rectangle,
 * in order of the comparator.
 * Elements outside the quadtree space are not added there.
 */
template<typename T, typename Comparator>
std::vector<T> Quadtree<T, Comparator>::get_elements(
    const Rectangle& region
) const {
  QueryResult element_set;
  raw_get_elements(region, std::back_inserter(element_set));
  return element_set;
}

/**
 * @brief Insert element overlaping the given region into the given inserter
 * @param where region to query
 * @param elements inserter
 */
template<typename T, typename Comparator>
template<typename C>
void Quadtree<T, Comparator>::raw_get_elements(
    const Rectangle& where,
    std::back_insert_iterator<C> elements) const {
  std::stack<int, std::vector<int>> nodestack;
  nodestack.push(0); //Begin with rootnode
  while(nodestack.size()) {
    int current = nodestack.top();
    nodestack.pop();
    const Node& node = nodes[current];
    if(!node.bounds.overlaps(where)) {
      continue;
    }

    if(node.is_leaf) {
      foreach_element(node.first_child, [&](int, const ElementNode& node){
        if(node.rect.overlaps(where)) {
          elements = node.data; //Add all element overlapping
        }
      });
    } else {
      foreach_child(node.first_child, [&](int id, const Node&){
        nodestack.push(id);
      });
    }
  }
}

/**
 * \brief Draws the quadtree on a surface for debugging purposes.
 * \param dst_surface The destination surface.
 * \param dst_position Where to draw on that surface.
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::draw(const SurfacePtr& dst_surface, const Point& dst_position) {
  std::mt19937 gen;
  ColorGenerator dist(0,255);

  std::stack<std::pair<int, QuadAxis>, std::vector<std::pair<int, QuadAxis>>> nodestack;
  nodestack.push({0, QuadAxis(get_space())}); //Begin with rootnode
  while(nodestack.size()) {
    auto [current, axis] = nodestack.top();
    nodestack.pop();
    const Node& node = nodes[current];

    Color color(dist(gen), dist(gen), dist(gen));

    draw_rectangle(node.bounds, color, dst_surface, dst_position);
    draw_rectangle(Rectangle(axis.center-Point(axis.qsize), axis.qsize*2), color, dst_surface, dst_position);

    if(node.is_leaf) {
      foreach_element(node.first_child, [&](int, const ElementNode& node){
        draw_rectangle(node.rect, color, dst_surface, dst_position);
      });
    } else {
      for(int i = 0; i < 4; i++)
      {
        nodestack.push({node.first_child+i, axis.child(static_cast<Child>(i))});
      }
    }
  }
}

/**
 * @brief Allocate 4 nodes at once
 * @return id of the first allocated node
 */
template<typename T, typename Comparator>
int Quadtree<T, Comparator>::allocate_4nodes() {
  if(free_node == -1) {
    int first = static_cast<int>(nodes.size());
    nodes.resize(first + 4); //Default construct 4 new nodes
    return first;
  } else {
    int free = free_node;
    free_node = nodes[free_node].first_child;
    for(int i = 0; i < 4; i++) {
      nodes[free+i] = {}; //Default init the four nodes
    }
    return free;
  }
}

/**
 * @brief Free 4 nodes at once
 * @param first id of the first node to
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::free_4nodes(int first) {
  nodes[first].first_child = free_node;
  free_node = first; //Do not de-init nodes more than that
}

/**
 * @brief Add a node to an element list
 * @param head_node ref to the head of the list
 * @param element_node id of the node to add
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::element_list_add(int& head_node, int element_node) {
  elements_nodes_storage[element_node].next = head_node;
  head_node = element_node;
}

/**
 * @brief Remove a node from an element list
 * @param head_node ref to the head of the list
 * @param element_node id of the node to remove
 * @return true if removal happend
 */
template<typename T, typename Comparator>
bool Quadtree<T, Comparator>::element_list_remove(int& head_node, int element_node) {
  int curr = head_node;

  ElementNode& dnode = elements_nodes_storage[element_node];

  //Search for the node that was pointing to our element
  while(curr != -1) {
    ElementNode& cnode = elements_nodes_storage[curr];
    if(cnode.next == element_node) {
      cnode.next = dnode.next;
      return true; //Removed, bail out
    }
    curr = cnode.next;
  }

  //Head fixup
  if(head_node == element_node) {
    head_node = dnode.next;
    return true;
  }

  return false;
}

/**
 * @brief clear an element list
 * @param head_node ref to the head of the list
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::element_list_clear(int& head_node) {
  head_node = -1;
}

/**
 * @brief Constructs an axis from a rectangle
 *
 * Center is the center of the rectangle and the axis are half  of the rectangle size
 *
 * @param rect a rectangle
 */
template<typename T, typename Comparator>
Quadtree<T, Comparator>::QuadAxis::QuadAxis(const Rectangle& rect) : center(rect.get_center()), qsize(rect.get_width() / 2, rect.get_height() / 2) {

}

/**
 * @brief Constructs a quad axis from its center and size
 * @param center the center
 * @param qsize the size
 */
template<typename T, typename Comparator>
Quadtree<T, Comparator>::QuadAxis::QuadAxis(Point center, Size qsize) : center(center), qsize(qsize) {

}

/**
 * @brief tells in which quadrant of those axes the point lie
 * @param point a point
 * @return in which child quadrant the point lie
 */
template<typename T, typename Comparator>
typename Quadtree<T, Comparator>::Child Quadtree<T, Comparator>::QuadAxis::where(Point point) const {
  return static_cast<Child>((point.x > center.x) + 2*(point.y > center.y));
}

/**
 * @brief Creates a child axes in the given quadrant
 * @param c a child
 * @return a new QuadAxis
 */
template<typename T, typename Comparator>
typename Quadtree<T, Comparator>::QuadAxis Quadtree<T, Comparator>::QuadAxis::child(Child c) const {
  Size newsize = qsize / 2;
  int ic = static_cast<int>(c);
  auto yoff = ic & 0b10 ? newsize.height : -newsize.height;
  auto xoff = ic & 0b01 ? newsize.width : -newsize.width;
  Point newcenter = Point(center.x + xoff, center.y + yoff);
  return {newcenter, newsize};
}

/**
 * \brief Creates a node with default coordinates.
 *
 * Call initialize later to set coordinates.
 *
 * \param quadtree The quadtree this node belongs to.
 */
template<typename T, typename Comparator>
Quadtree<T, Comparator>::Node::Node() :
    bounds(0,0,0,0), first_child(-1), is_leaf(true), count(0) {

}

/**
 * @brief Iterates trough each element starting with first
 * @param first the first element
 * @param fun closure to apply
 */
template<typename T, typename Comparator>
template <typename F>
void Quadtree<T, Comparator>::foreach_element(int first, F fun) {
  int curr = first;
  while(curr != -1) {
    ElementNode& node = elements_nodes_storage[curr];
    int next = node.next;
    fun(curr, node);
    curr = next;
  }
}

/**
 * @brief Iterates trough each child starting with first
 * @param first the first child
 * @param fun closure to apply
 */
template<typename T, typename Comparator>
template <typename F>
void Quadtree<T, Comparator>::foreach_child(int first, F fun) {
  for(int32_t child = first; child < first + 4; child++) {
    fun(child, nodes[child]);
  }
}

/**
 * @brief Iterates trough each element starting with first
 * @param first the first element
 * @param fun closure to apply
 */
template<typename T, typename Comparator>
template <typename F>
void Quadtree<T, Comparator>::foreach_element(int first, F fun) const {
  int curr = first;
  while(curr != -1) {
    const ElementNode& node = elements_nodes_storage[curr];
    int next = node.next;
    fun(curr, node);
    curr = next;
  }
}

/**
 * @brief Iterates trough each child starting with first
 * @param first the first child
 * @param fun closure to apply
 */
template<typename T, typename Comparator>
template <typename F>
void Quadtree<T, Comparator>::foreach_child(int first, F fun) const {
  for(int32_t child = first; child < first + 4; child++) {
    fun(child, nodes[child]);
  }
}


/**
 * \brief Splits this cell in four parts and moves its elements to them.
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::node_split(int node, const QuadAxis& axis) {

  auto& node_before = nodes[node];

  //Save pointer to first element
  int32_t element = node_before.first_child;

  //allocate nodes
  int first_child = allocate_4nodes(); //Nodes are correctly initialized

  //node before invalid
  auto& node_after = nodes[node];
  node_after.first_child = first_child;

  node_after.is_leaf = false;

  // Move existing elements into them.
  foreach_element(element, [&](int nodeid, ElementNode& node){
    auto center = node.rect.get_center();
    Child c = axis.where(center);
    //nodes[first_child+static_cast<int32_t>(c)].add(tree, axis.child(c), {center, node.rect, nodeid});
    node_add(first_child+static_cast<int>(c), axis.child(c), nodeid);
  });
}

/**
 * \brief Merges the four children cell into this one and destroys them.
 *
 * The children must already be leaves.
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::node_merge(int nodeid) {
  auto& topnode = nodes[nodeid];

  int32_t first_element = -1;
  for(int32_t i = 0; i < 4; i++) { //For each child node
    auto child = topnode.first_child + i;
    auto& node = nodes[child];

    //First merge bellow if needed
    if(!node.is_leaf) {
      node_merge(child);
    }

    foreach_element(node.first_child, [&](int elnode, ElementNode& /*element*/){
      element_list_add(first_element, elnode);
    });
  }

  free_4nodes(topnode.first_child);
  topnode.first_child = first_element;
  topnode.is_leaf = true;
}

/**
 * @brief Shrinks and/or merge the given node
 * @param node_id the node to shrink
 * @return some Rectangle if there are childs or element, else None
 */
template<typename T, typename Comparator>
std::optional<Rectangle> Quadtree<T, Comparator>::node_shrink(int node_id) {
  Node& node = nodes[node_id];

  if(node.count == 0) {
    return {}; //Do not return a rect if we are empty
  }

  //First merge if necessary
  if(node.count <= min_in_4_cells && !node.is_leaf) {
    node_merge(node_id);
  }

  if(node.is_leaf) {
    int current_id = node.first_child;
    ElementNode& first = elements_nodes_storage[node.first_child];
    node.bounds = first.rect;
    while(current_id != -1) {
      auto& anode = elements_nodes_storage[current_id];
      node.bounds |= anode.rect;
      current_id = anode.next;
    }
  } else {
    int current_id = node.first_child;
    auto res = node_shrink(current_id);
    bool atleast = false;
    if(res) {
      node.bounds = *res;
      atleast = true;
    }
    for(;current_id < node.first_child+4; current_id++){
      auto ares = node_shrink(current_id);
      if(ares) {
        node.bounds |= *ares;
        atleast |= true;
      }
    }
    if(atleast) {
      return node.bounds;
    } else {
      return {};
    }
  }

  return node.bounds;
}

/**
 * \brief Draws the border of a rectangle on a surface for debugging purposes.
 * \param rectangle The rectangle to draw.
 * \param line_color The color to use.
 * \param dst_surface The destination surface.
 * \param dst_position Where to draw on that surface.
 */
template<typename T, typename Comparator>
void Quadtree<T, Comparator>::draw_rectangle(
    const Rectangle& rectangle,
    const Color& line_color,
    const SurfacePtr& dst_surface,
    const Point& dst_position
) const {
  // TODO remove this function when the draw line API is available

  Rectangle where = rectangle;
  where.set_xy(where.get_xy() + dst_position);
  dst_surface->fill_with_color(line_color, Rectangle(
      where.get_top_left(), Size(where.get_width(), 1)
  ));
  dst_surface->fill_with_color(line_color, Rectangle(
      where.get_bottom_left() + Point(0, -1), Size(where.get_width(), 1)
  ));
  dst_surface->fill_with_color(line_color, Rectangle(
      where.get_top_left(), Size(1, where.get_height())
  ));
  dst_surface->fill_with_color(line_color, Rectangle(
      where.get_top_right() + Point(-1, 0), Size(1, where.get_height())
  ));
}

}  // namespace Solarus
