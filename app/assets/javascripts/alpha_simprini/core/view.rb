class AlphaSimprini::View < AlphaSimprini::Dom
  attr_reader :element

  def initialize(config=nil)
    @observed_objects = []
    @child_views = []
    ensure_element_exists
    config and write_configuration(config)
    content
  end

  def content; end

  def observe_object(object)
    object.add_observer(self)
  end

  def cleanup
    @observed_objects.each do |object|
      object.delete_observer(self)
    end
    @observed_objects = []
  end

  def remove
    cleanup
    @child_views.each(&:cleanup)
    parent = @element.parent_element and parent.remove_child(@element)
  end

  def view(constructor, config=nil)
    constructor.new(config).tap do |view|
      @child_views << view
      append view.element
    end
  end

  def remove_child_view(view)
    @child_views.delete(view)
    view.remove
  end

  def bind(*args)
    view_constructor = args.last
    binding_path = args[0, args.length - 1]

    $window.console.log(@model)
    if @model.is_a?(Array)
      binding @model, view_constructor, AlphaSimprini::ArrayBinding
    else
      binding @model, view_constructor, AlphaSimprini::Binding
    end
  end

  def binding(model, view_constructor, binding_constructor)
    binding_constructor.new(self, model, view_constructor)
  end

  def write_configuration(config)
    config.each do |key, value|
      ivar = :"@#{key}"
      raise "Overwriting instance variable #{ivar} on #{inspect}." if instance_variable_get(ivar)
      instance_variable_set ivar, value
    end
  end

  def ensure_element_exists
    @current_node = @element ||= build_element.tap do |node|
      base_attributes.each do |key, value|
        next if key == 'class' && node.class_list.any?
        next if key == 'id' && node.id.empty?
        value = value * ' ' if value.is_a? Array
        node.set_attribute key.to_s, value.to_s
      end
    end
  end

  def tag_name
    :section
  end

  def build_element
    send(tag_name)
  end

  def base_attributes
    {
      class: css_classes,
      id: object_id
    }
  end

  def css_classes
    names = self.class.ancestors.map(&:name).map{|name| name.split('::').last }
    (names - %w(Object Kernel BasicObject Dom)) * ' '
  end

  def append_to(node)
    node.append_child @element
  end

end