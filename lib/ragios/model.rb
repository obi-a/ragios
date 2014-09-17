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
      def active_monitors
        @database.where(type: "monitor", status_: "active")
      end

      Contract Hash => ArrayOf[Hash]
      def monitors_where(attributes_hash)
        hash_with_type = attributes_hash.merge(type: "monitor")
        @database.where(hash_with_type)
      end

      Contract Doc_id => Hash
      def get_monitor_state(id)
        script = design_doc_script('function(doc){ if(doc.type == "test_result" && doc.time_of_test && doc.monitor_id) emit([doc.monitor_id, doc.time_of_test]); }')
        results = dynamic_view("_design/results", script) do
          @database.view("_design/results", "results",
            endkey: [id, "1913-01-15 05:30:00 -0500"].to_s,
            startkey: [id, "3015-01-15 05:30:00 -0500"].to_s,
            limit: 1,
            include_docs: true,
            descending: true)
        end
        results[:rows].blank? ? {} : results[:rows].first[:doc]
      end

      def results_by_state(monitor_id, state, take = nil, start_from_doc = nil)
        script = design_doc_script('function(doc){ if(doc.type == "test_result" && doc.time_of_test && doc.monitor_id && doc.state) emit([doc.monitor_id, doc.state, doc.time_of_test]); }')

        query_options = {
          endkey: [monitor_id, state, "1913-01-15 05:30:00 -0500"].to_s,
          startkey: [monitor_id, state, "3015-01-15 05:30:00 -0500"].to_s,
          include_docs: true,
          descending: true
        }

        query("_design/results_by_state", script, query_options, take, start_from_doc)
      end

      def notifications(monitor_id, take = nil, start_from_doc = nil)
        script = design_doc_script('function(doc){ if(doc.type == "notification" && doc.created_at && doc.monitor_id) emit([doc.monitor_id, doc.created_at]); }')

        query_options = {
          endkey: [monitor_id, "1913-01-15 05:30:00 -0500"].to_s,
          startkey: [monitor_id, "3015-01-15 05:30:00 -0500"].to_s,
          include_docs: true,
          descending: true
        }

        query("_design/notifications", script, query_options, take, start_from_doc)
      end

      def all_monitors(take = nil, start_from_doc = nil)
        script = design_doc_script('function(doc){ if(doc.type == "monitor" && doc.created_at_) emit([doc.created_at_]); }')

        query_options = {
          endkey: ["1913-01-15 05:30:00 -0500"].to_s,
          startkey: ["3015-01-15 05:30:00 -0500"].to_s,
          include_docs: true,
          descending: true
        }

        query("_design/all_monitors", script, query_options, take, start_from_doc)
      end

    private

      def query(design_doc_name, script, query_options, take, start_from_doc)
        query_options[:limit] = take if take
        query_options[:startkey_docid] = start_from_doc if start_from_doc

        results = dynamic_view(design_doc_name, script) do
          @database.view(design_doc_name, "results", query_options)
        end
        results[:rows].blank? ? [] : results[:rows].map { |e| e[:doc] }
      end

      def design_doc_script(map_fn)
        {
          language: 'javascript',
          views: {
            results: {
              map: map_fn
            }
         }
        }
      end
      def dynamic_view(design_doc_name, design_doc)
        yield
      rescue Leanback::CouchdbException
        @database.create_doc design_doc_name, design_doc
        yield
      end
    end
  end
end
