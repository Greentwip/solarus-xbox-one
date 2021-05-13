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
#ifndef SOLARUS_QUADTREE_H
#define SOLARUS_QUADTREE_H

#include "solarus/core/Common.h"
#include "solarus/core/Rectangle.h"
#include "solarus/core/Size.h"
#include "solarus/core/Profiler.h"
#include "solarus/graphics/Color.h"
#include "solarus/graphics/SurfacePtr.h"
#include "FreeList.h"
#include <array>
#include <unordered_map>
#include <memory>
#include <stack>
#include <vector>
#include <random>
#include <optional>


namespace Solarus {

class Color;

/**
 * \brief A collection of objects spatially located in an adaptable 2D grid.
 *
 * The main goal of this container is to get objects in a given rectangle as
 * quickly as possible.
 *
 * \param T Type of objects.
 */
template <typename T, typename Comparator = std::less<T>>
class Quadtree {

  public:

    using QueryResult = std::vector<T>;

    Quadtree();
    explicit Quadtree(const Rectangle& space);

    void clear();
    void initialize(const Rectangle& space);

    Rectangle get_space() const;

    bool add(const T& element, const Rectangle& bounding_box);
    bool remove(const T& element);
    bool move(const T& element, const Rectangle& bounding_box);

    std::vector<T> get_elements(
        const Rectangle& where
    ) const;


    template<typename C>
    void raw_get_elements(
        const Rectangle& where,
        std::back_insert_iterator<C> elements
    ) const;

    int get_num_elements() const;
    bool contains(const T& element) const;

    void shrink_to_fit();

    void draw(const SurfacePtr& dst_surface, const Point& dst_position);

    static constexpr int
        min_cell_size = 32;  /**< Don't split more if a cell is smaller than
                              * this size. */
    static constexpr int
        max_in_cell = 8;     /**< A cell is split if it exceeds this number
                              * when adding an element, unless the cell is
                              * too small. */
    static constexpr int
        min_in_4_cells = 4;  /**< 4 sibling cells are merged if their total
                              * is below this number when removing an element. */

    static constexpr bool debug_quadtrees = false;

  private:

    //Enum class representing position (and indexes) of the children nodes
    enum class Child {
      TL, TR,
      BL, BR
    };

    /**
     * @brief Helper struct easing the spliting of the space in quadrants
     */
    struct QuadAxis{
        Point center;   /**< center point spliting the tree quad */
        Size  qsize;    /**< size of a quadrant */

        QuadAxis(const Rectangle& rect);
        QuadAxis(Point center, Size qsize);
        Child where(Point point) const;
        QuadAxis child(Child c) const;
    };

    /**
     * @brief Container for all necessary information when inserting elements
     * down the tree.
     */
    struct InsertInfo{
        Point center;        /**< center of the element */
        Rectangle bbox;      /**< bounding box of the element */
        int element_node;    /**< id of the element being inserted */
    };

    using ColorGenerator = std::uniform_int_distribution<>;

    /**
     * @brief Struct holding node geometry and links to element and other nodes
     */
    struct Node {
        Node();
        Rectangle bounds;         /**< bounding box of all node children (elements or nodes) */
        int32_t first_child = -1; /**< first child of the node, or first element if it is a leaf */
        bool is_leaf : 1;         /**< is this a leaf */
        uint32_t count : 31;      /**< count of elements bellow this leaf */
    };

    static_assert (sizeof(Node) <= sizeof(int)*8, "Size of node should not be more than 8 ints");



    // Node management
    bool node_add(int node, QuadAxis axis, int element);
    bool node_remove(int node, QuadAxis axis, int element);
    void node_split(int node, const QuadAxis& axis);
    void node_merge(int node);
    std::optional<Rectangle> node_shrink(int node);

    template <typename F>
    void foreach_element(int first, F fun);

    template <typename F>
    void foreach_child(int first, F fun);

    template <typename F>
    void foreach_element(int first, F fun) const;

    template <typename F>
    void foreach_child(int first, F fun) const;


    int allocate_4nodes();
    void free_4nodes(int first);

    // Elements management
    void element_list_add(int& head_node, int element_node);
    bool element_list_remove(int& head_node, int element_node);
    void element_list_clear(int& head_node);


    void draw_rectangle(
        const Rectangle& rectangle,
        const Color& line_color,
        const SurfacePtr& dst_surface,
        const Point& dst_position
    ) const;

    //Node& root();
    //const Node& root() const;

    /**
    * @brief Holds the data at the same time as the linked list impl
    */
    struct ElementNode {
      int next;          /**< next element in the linked list */
      Rectangle rect;    /**< bounding box of this element */
      T data;            /**< Data stored into the quadtree */
    };

    FreeList<ElementNode>
      elements_nodes_storage;     /**< contiguous storage for element nodes */

    std::vector<Node> nodes;      /**< contiguous storage for quadtree nodes */


    int free_node = -1;           /**< first free group of four node or -1 if no free nodes */
    Rectangle space;              /**< rectangle covered by this quadtree */


    std::unordered_map<T, int>
      elements_infos;             /**< mapping of element to element node id */
};

template<typename T>
using QuadtreeNode = typename Quadtree<T>::Node;

}

#include "solarus/containers/Quadtree.inl"

#endif

