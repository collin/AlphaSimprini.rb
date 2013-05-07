module AlphaSimprini::ArrayObserver

  ADD_METHODS      =       :<<, :push, :concat, :insert, :unshift
  MODIFIER_METHODS =  :collect!, :map!, :flatten!, :replace, :reverse!, :sort!, :fill
  REMOVE_METHODS   =    :clear, :compact!, :delete, :delete_at, :delete_if, :pop, :reject!, :shift, :slice!, :uniq!

  def self.extended(klass)
    klass.extend(AlphaSimprini::Observable)
  end

  #[]= can either be an add method or a modifier method depending on
  #if the previous key exists
  def []=(*args)
    change_type = args[0] >= length ? :added : :modified
    changes = changes_for(change_type,:"[]=",*args)
    changing(change_type,:trigger=>:"[]=", :changes=>changes) {super}
  end

  def self.override_mutators(change_groups)
    change_groups.each_pair do |change_type,methods|
      methods.each do |method|
        class_eval <<-EOS
          def #{method}(*args,&block)
            changes = changes_for(:#{change_type},:#{method},*args,&block)
            changing(:#{change_type},:trigger=>:#{method}, :changes=>changes){super}
         end
        EOS
      end
    end
  end

  override_mutators added:    ADD_METHODS,
                    modified: MODIFIER_METHODS,
                    removed:  REMOVE_METHODS

  def changing(change_type, opts={})
    args = create_event_args(change_type,opts)
    yield.tap do
      changes = args.changes
      changes.any? and changed and notify_observers(changes)
      added = changes[:added] and added.each do |item|
        item.add_observer(self)
      end
    end
  end

  def update(event, item)
    AS::RunLoop.enqueue :sync do    
      case event
      when :destroy
        delete(item)
      end
    end
  end

  def create_event_args(change_type,opts={})
    args = {:change_type=>change_type, :current_values=>self}.merge(opts)
    class << args
      def changes
        chgs, cur_values = self[:changes], self[:current_values]
        chgs && chgs.respond_to?(:call) ? chgs.call(cur_values) : chgs
      end

      def method_missing(method)
        self.keys.include?(method) ? self[method] : super
      end
    end
    args.delete(:current)
    args
  end

  def changes_for(change_type, trigger_method, *args, &block)
    prev = self.dup.to_a
    if change_type == :added
      case trigger_method
        when :"[]=" then lambda {|cur| {:added=>args[-1]}}
        when :<<, :push, :unshift then lambda {|cur| {:added=>args}}
        when :concat then lambda {|cur| {:added=>args[0]}}
        when :insert then lambda {|cur| {:added=>args[1..-1]}}
        else lambda { |cur| {:added=>(cur - prev).uniq }}
      end
    elsif change_type == :removed
      case trigger_method
        when :delete then lambda {|cur| {:removed=>args}}
        when :delete_at then lambda {|cur| {:removed=>[prev[args[0]]]}}
        when :delete_if, :reject! then lambda {|cur| {:removed=>prev.select(&block)}}
        when :pop then lambda {|cur| {:removed=>[prev[-1]]}}
        when :shift then lambda {|cur| {:removed=>[prev[0]]}}
        else lambda { |cur| {:removed=>(prev - cur).uniq }}
      end
    else
      case trigger_method
        when :replace then lambda {|cur| {:removed=>prev, :added=>args[0]}}
        when :"[]=" then lambda {|cur| {:removed=>[prev[*args[0..-2]]].flatten, :added=>[args[-1]].flatten}}
        else lambda {|cur|{:removed=>prev.uniq, :added=>cur}}
      end
    end
  end

end