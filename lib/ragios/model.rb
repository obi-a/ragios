module Ragios
  module Database
    class Model
      include Contracts

      Doc_id = String

      def initialize(database)
        @database = database
      end

      Contract Doc_id, Hash => Bool
      def save(id, data)
        !!@database.create_doc(id, data)
      end

      Contract Doc_id => Hash
      def find(id)
        @database.get_doc(id)
      end

      Contract Doc_id, Hash => Bool
      def update(id, data)
        !!@database.edit_doc!(id, data)
      end

      Contract Doc_id => Bool
      def delete(id)
        !!@database.delete_doc!(id)
      end

      Contract None => ArrayOf[Hash]
      def all_monitors
        @database.where(type: "monitor")
      end

      Contract None => ArrayOf[Hash]
      def active_monitors
        @database.where(type: "monitor", status_: "active")
      end

      Contract Hash => ArrayOf[Hash]
      def monitors_where(attributes_hash)
        hash_with_type = attributes_hash.merge(type: "monitor")
        @database.where(hash_with_type)
      end

      Contract Doc_id => Or[nil, Hash]
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
        results[:rows].blank? ? {} : results[:rows].first[:doc]
      end
    private
      def dynamic_view(design_doc_name, design_doc)
        yield
      rescue Leanback::CouchdbException
        @database.create_doc design_doc_name, design_doc
        yield
      end
    end
  end
end
