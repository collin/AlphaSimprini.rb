module ApplicationHelper
  def rubyscript_include(*sources)
    sources.map do |source|
      "<script type='text/ruby' src='/assets/#{source}.rb'></script>"
    end.join.html_safe
  end
end
