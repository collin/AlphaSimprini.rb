class AlphaSimprini::Dom
  attr_reader :current_node

  SVG = {
    ns: "http://www.w3.org/2000/svg"
  }

  HTML_TAGS = %w(
    a abbr address article aside audio b bdi bdo blockquote body button
    canvas caption cite code colgroup datalist dd del details dfn div dl dt em
    fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup
    html i iframe ins kbd label legend li map mark menu meter nav noscript object
    ol optgroup option output p pre progress q rp rt ruby s samp script section
    select small span strong style sub summary sup table tbody td textarea tfoot
    th thead time title tr u ul video area base br col command embed hr img input
    keygen link meta paramsource track wbr
  )

  SVG_TAGS = %w(
    svg g defs desc title metadata symbol use switch image style path rect circle
    line ellipse polyline polygon text tspan tref textPath altGlyph altGlyphDef
    altGlyphItem glyphRef marker color-profile linearGradient radialGradient stop
    pattern clipPath mask filter feBlend feColorMatrix feComponentTransfer feComposite
    feConvolveMatrix feDiffuseLighting feDisplacementMap feFlood feGaussianBlur feImage
    feMerge feMergeNode feMorphology feOffset feSpecularLighting feTile feTurbulence
    feDistantLight fePointLight feSpotLight feFuncR feFuncG feFuncB feFuncA cursor a view
    script animate set animateMotion animateColor animateTransform mpath font font-face
    glyph missing-glyph hkern vkern font-face-src font-face-uri font-face-format
    font-face-name definition-src foreignObject
  )

  def document
    $window.document
  end

  def append(node)
    return unless node && @current_node
    @current_node.append_child node    
  end

  def text(content)
    document.create_text_node(content).tap do |text_node|
      append text_node
    end
  end

  def raw(html)
    span.inner_html = html
  end

  def tag(name, attrs={}, content=nil, &block)
    _tag document.create_element(name), attrs, content, &block
  end

  def svg_tag(name, attrs, content=nil, &block)
    _tag document.create_element_ns(SVG[:ns], name), attrs, content, &block
  end

  def dangling_content(&block)
    within_node(nil, &block)  
  end

  def within_node(node, &block)
    stash = @current_node
    @current_node = node
    instance_eval(&block)
  ensure
    @current_node = stash
  end

  private
  def _tag(node, attrs={}, content=nil, &block)
    @current_node ||= document.create_document_fragment

    if attrs.is_a? String
      content = attrs
      attrs = {}
    end

    attrs and attrs.each do |key, value|
      node.set_attribute key.to_s, value
    end 

    if block_given?
      within_node node do
        last = instance_eval(&block)
        text last if last.is_a? String
      end

    else
      within_node node do
        text content if content        
      end
    end

    append(node)

    return node
  end

  HTML_TAGS.each(&:chomp!)
  HTML_TAGS.each do |name|
    class_eval <<RUBY, __FILE__, __LINE__ + 1
      def #{name}(attrs=nil, content=nil, &block)
        tag('#{name}', attrs, content, &block)
      end
RUBY
  end

#   SVG_TAGS.each(&:chomp!)
#   SVG_TAGS.each do |name|
#     conflict = HTML_TAGS.include?(name)
#     name.gsub!('-', '_')
#     safe_name = "svg_#{name}" if conflict
#     class_eval <<RUBY, __FILE__, __LINE__ + 1
#       def #{safe_name}(attrs=nil, content=nil, &block)
#         svg_tag('#{safe_name}', attrs, content, &block)
#       end
# RUBY
#   end
end