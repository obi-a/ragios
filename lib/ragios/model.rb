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
        query_options = {}
        query_options[:endkey] = [id, "monitor.test", "1913-01-15 05:30:00 -0500"].to_s
        query_options[:startkey] = [id, "monitor.test", "3015-01-15 05:30:00 -0500"].to_s
        query_options[:limit] = 1
        results = query("_design/events", script, query_options)
        results[:rows].blank? ? {} : results[:rows].first[:doc]
      end

      Contract Doc_id, String, Hash => Array
      def get_monitor_events_by_state(monitor_id, state, options)
        script = design_doc_script('function(doc){ if(doc.type == "event" && doc.time && doc.monitor_id && doc.state) emit([doc.monitor_id, doc.state, doc.time]); }')
        query_options = {}
        query_options[:endkey] = [monitor_id, state, options[:end_date]].to_s
        query_options[:startkey] = [monitor_id, state, options[:start_date]].to_s
        query_options[:limit] = options[:take] if options[:take]
        results = query("_design/events_by_state", script, query_options)
        get_docs(results)
      end

      Contract Doc_id, Hash => Array
      def get_monitor_events(monitor_id, options)
        script = design_doc_script('function(doc){ if(doc.type == "event" && doc.time && doc.monitor_id) emit([doc.monitor_id, doc.time]); }')
        query_options = {}
        query_options[:endkey] = [monitor_id, options[:end_date]].to_s
        query_options[:startkey] = [monitor_id, options[:start_date]].to_s
        query_options[:limit] = options[:take] if options[:take]
        results = query("_design/get_all_events", script, query_options)
        get_docs(results)
      end

      Contract Doc_id, Hash => Array
      def get_monitor_notifications(monitor_id, options)
        script = design_doc_script('function(doc){ if(doc.type == "event" && doc.time && doc.monitor_id && doc.event_type) emit([doc.monitor_id, doc.event_type, doc.time]); }')
        query_options = {}
        query_options[:endkey] = [monitor_id, "monitor.notification", options[:end_date]].to_s
        query_options[:startkey] = [monitor_id, "monitor.notification", options[:start_date]].to_s
        query_options[:limit] = options[:take] if options[:take]
        results = query("_design/notifications", script, query_options)
        get_docs(results)
      end

      Contract Any => Array
      def all_monitors(options = {})
        script = design_doc_script('function(doc){ if(doc.type == "monitor" && doc.created_at_) emit([doc.created_at_]); }')
        query_options = {}
        query_options[:endkey] = ["1913-01-15 05:30:00 -0500"].to_s
        query_options[:startkey] = ["3015-01-15 05:30:00 -0500"].to_s
        query_options[:limit] = options[:take] if options[:take]
        results = query("_design/all_monitors", script, query_options)
        get_docs(results)
      end

    private

      def query(design_doc_name, script, query_options)
        query_options[:descending] = true
        query_options[:include_docs] = true
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
