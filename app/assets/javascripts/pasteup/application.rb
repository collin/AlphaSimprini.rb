AS = AlphaSimprini

module Pasteup
  module Views
    class TaskLists < AS::View
      def content      
        h1 "Task Lists"
        button("Add List").onclick { @model.push Models::TaskList.new  }
        ol { bind TaskList }
      end
    end

    class TaskList < AS::View
      def tag_name; :li end
      def content
        text "THIS IS A TASK LIST! #{@model.object_id.to_s.split(//).last(5) * ''}"
        button("X").onclick { @model.destroy! }
      end
    end

    class Tasks < AS::View
      def content
        h1 "Tasks"
        ol do
          bind :selection, :tasks, Task
        end
      end
    end

    class Task < AS::View
      def tag_name; :li end

      def content
        input type:'checkbox'
        text "THIS IS A TASK"
      end
    end
  end
  
  module Models
    class RadioSelection
      attr_accessor :selection
    end

    class Task < AS::Model
    end

    class TaskList < AS::Model
      attr_accessor :tasks
      def initialize
        @tasks = []
      end
    end
  end

  class Application < AS::Application
    def build_state
      state :task_lists, Array
    end

    def content
      append @task_lists_view = view(Views::TaskLists, model: @task_lists)
      append @tasks = view(Views::Tasks)
      50.times do      
        @task_lists.push Models::TaskList.new
      end
      45.times do
        @task_lists.pop
      end
    end
  end
end

window.onload do
  AS.boot Pasteup, $window.document.body
end