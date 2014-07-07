module Ragios
  module Database
    class Model
      def initialize(database)
        @database = database
      end
      def save(id, data)
        !!@database.create_doc(id, data)
      end
      def find(id)
        @database.get_doc(id)
      end
      def update(id, data)
        !!@database.edit_doc!(id, data)
      end
      def delete(id)
        !!@database.delete_doc!(id)
      end
      def all_monitors
        @database.where(type: "monitor")
      end
      def active_monitors
        @database.where(type: "monitor", status_: "active")
      end
      def monitors_where(attributes_hash)
        hash_with_type = attributes_hash.merge(type: "monitor")
        @database.where(hash_with_type)
      end
      def get_monitor_state(id)
        design_doc = {
         language: 'javascript',
         views: {
           results: {
             map: 'function(doc){ if(doc.type == "test_result" && doc.time_of_test && doc.monitor_id) emit([doc.monitor_id, doc.time_of_test]); }'
           }
         }
        }
        results = dynamic_view("_design/results", design_doc) do
          @database.view("_design/results", "results",
            endkey: [id, "1913-01-15 05:30:00 -0500"].to_s,
            startkey: [id, "3015-01-15 05:30:00 -0500"].to_s,
            limit: 1,
            include_docs: true,
            descending: true)
        end
        results[:rows].blank? ? nil : results[:rows].first[:doc]
      end
    private
      def dynamic_view(design_doc_name, design_doc)
        yield
      rescue CouchdbException
        @database.create_doc design_doc_name, design_doc
        yield
      end
    end
  end
end
