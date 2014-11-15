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
        script = design_doc_script('function(doc){ if(doc.type == "event" && doc.time && doc.monitor_id && doc.event_type) emit([doc.monitor_id, doc.event_type, doc.time]); }')
        results = dynamic_view("_design/events", script) do
          @database.view("_design/events", "events",
            endkey: [id, "monitor.test", "1913-01-15 05:30:00 -0500"].to_s,
            startkey: [id, "monitor.test", "3015-01-15 05:30:00 -0500"].to_s,
            limit: 1,
            include_docs: true,
            descending: true)
        end
        results[:rows].blank? ? {} : results[:rows].first[:doc]
      end

      #def results_by_state(monitor_id, state, start_date, end_date, take = nil, start_from_doc = nil)
      def results_by_state(options)
        script = design_doc_script('function(doc){ if(doc.type == "event" && doc.time && doc.monitor_id && doc.state && doc.event_type) emit([doc.monitor_id, doc.state, doc.event_type, doc.time]); }')

        query_options = {
          endkey: [options[:monitor_id], options[:state], "monitor.test", options[:end_date]].to_s,
          startkey: [options[:monitor_id], options[:state], "monitor.test", options[:start_date], "monitor.test"].to_s
        }

        results = query("_design/results_by_state", script, query_options, options[:take], options[:start_from_doc])
        get_docs(results)
      end

      #def get_all_results(monitor_id, start_date, end_date, take = nil, start_from_doc = nil)
      def get_all_events(options)
        script = design_doc_script('function(doc){ if(doc.type == "event" && doc.time && doc.monitor_id) emit([doc.monitor_id, doc.time]); }')
        #example
        #start_date: "3015-01-15 05:30:00 -0500"
        #end_date: "1913-01-15 05:30:00 -0500"
        query_options = {
          endkey: [options[:monitor_id], options[:end_date]].to_s,
          startkey: [options[:monitor_id], options[:start_date]].to_s
        }

        results = query("_design/get_all_events", script, query_options, options[:take], options[:start_from_doc])
        get_docs(results)
      end

      #def notifications(monitor_id, take = nil, start_from_doc = nil)
      def notifications(options)
        script = design_doc_script('function(doc){ if(doc.type == "event" && doc.time && doc.monitor_id && doc.event_type) emit([doc.monitor_id, doc.event_type, doc.time]); }')

        query_options = {
          endkey: [options[:monitor_id], "monitor.notification", options[:end_date]].to_s,
          startkey: [options[:monitor_id], "monitor.notification", options[:start_date]].to_s
        }

        results = query("_design/notifications", script, query_options, options[:take], options[:start_from_doc])
        get_docs(results)
      end

      def all_monitors(take = nil, start_from_doc = nil)
        script = design_doc_script('function(doc){ if(doc.type == "monitor" && doc.created_at_) emit([doc.created_at_]); }')

        query_options = {
          endkey: ["1913-01-15 05:30:00 -0500"].to_s,
          startkey: ["3015-01-15 05:30:00 -0500"].to_s
        }

         results = query("_design/all_monitors", script, query_options, take, start_from_doc)
         get_docs(results)
      end

    private

      def query(design_doc_name, script, query_options, take, start_from_doc)
        query_options[:descending] = true
        query_options[:include_docs] = true
        query_options[:limit] = take if take
        query_options[:startkey_docid] = start_from_doc if start_from_doc

        results = dynamic_view(design_doc_name, script) do
          @database.view(design_doc_name, "events", query_options)
        end
      end

      def get_docs(result_set)
        result_set[:rows].blank? ? [] : result_set[:rows].map { |e| e[:doc] }
      end

      def design_doc_script(map_fn)
        {
          language: 'javascript',
          views: {
            events: {
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
