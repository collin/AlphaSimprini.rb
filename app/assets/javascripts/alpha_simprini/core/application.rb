class AlphaSimprini::Application
  def initialize(root)
    @root = root
    build_state
    content
    AlphaSimprini::RunLoop.drain
  end

  def view(constructor, config=nil)
    constructor.new(config)
  end

  def state(name, constructor)
    ivar = :"@#{name}"
    instance_variable_set ivar, constructor.new
  end

  def append(view)
    view.append_to(@root)
  end

  def content; end
  def build_state; end
end