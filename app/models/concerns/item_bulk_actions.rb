module ItemBulkActions
  extend ActiveSupport::Concern

  module ClassMethods
    def subaction(selection)
      ba = selection[:subaction]
      raise ArgumentError, "Unknown subaction '#{ba}'" unless methods.grep(/bulk_#{ba}/).any?
      ba
    end

    def bulk(selection)
      self
        .where(id: selection[:ids])
        .send(:"bulk_#{subaction(selection)}", selection)
    end

    def bulk_move(selection)
      self.update_all(folder_id: selection[:folder_id])
      true
    end

    def bulk_tags(selection)
      output = true

      self.transaction do
        all.each do |item|
          item.instance_variable_set("@readonly", false)
          item.tags_list << (Tag.from_list(selection[:tags]) - item.tags_list)
        end
      end
      output
    end
  end
end
