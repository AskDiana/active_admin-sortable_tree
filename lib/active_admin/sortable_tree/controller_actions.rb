module ActiveAdmin::SortableTree
  module ControllerActions
    attr_accessor :sortable_options

    def sortable(options = {})
      options.reverse_merge! :sorting_attribute => :position,
                             :parent_method => :parent,
                             :children_method => :children,
                             :roots_method => :roots,
                             :tree => false,
                             :max_levels => 0,
                             :protect_root => false,
                             :collapsible => false, #hides +/- buttons
                             :start_collapsed => false,
                             :sortable => true

      # BAD BAD BAD FIXME: don't pollute original class
      @sortable_options = options

      # disable pagination
      config.paginate = false

      collection_action :sort, :method => :post do
        resource_name = ActiveAdmin::SortableTree::Compatibility.normalized_resource_name(active_admin_config.resource_name)

        records = params[resource_name].each_pair.map do |resource, parent_resource|
          record        = resource_class.find(resource)
          parent_record = resource_class.find(parent_resource) rescue nil

          [record, parent_record]
        end

        success = nil

        ActiveRecord::Base.transaction do
          begin
            resource_class.resort(records)

            success = true
          rescue => err
            Rails.logger.error err

            success = false
          end
        end

        if success
          head 200
        else
          head 422
        end
      end
    end
  end

  ::ActiveAdmin::ResourceDSL.send(:include, ControllerActions)
end
