class AlphaSimprini::ArrayBinding < AlphaSimprini::Binding
  def initialize(view, array, view_constructor)
    @view = view
    @array = array
    @view_constructor = view_constructor
    @container = view.current_node

    array.extend(AS::ArrayObserver) unless array.is_a?(AS::ArrayObserver)
    array.add_observer self

    array.each &method(:add_item)

    @item_views = {}
  end

  def update(changes)
    AS::RunLoop.enqueue :render do    
      removed = changes[:removed] and removed.each do |item|
        remove_item(item)
      end
      added = changes[:added] and added.each do |item|
        add_item(item)
      end
    end
  end

  def add_item(item)
    view_constructor = @view_constructor
    item_views = @item_views

    content = @view.dangling_content do
      _view = view view_constructor, model:item
      item_views[item] = _view
    end
    index = @array.index(item)
    return unless index
    
    element = content.element
    case index
    when 0
      if @container.child_nodes.any? # First with siblings
        @container.insert_before element, @container.child_nodes.first
      else
        @container.append_child element
      end
    when @array.length - 1 # Last
      @container.append_child element
    else # Elsewhere
      if sibling = @array[index + 1] && sibling_element = item_views[sibling]
        @container.insert_before element, sibling_element
      else
        @container.append_child element
      end
    end
  end

  def remove_item(item)
    @view.remove_child_view @item_views.delete(item)
  end
end