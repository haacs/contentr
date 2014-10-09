module Contentr
  module ParagraphPublishing
    extend ActiveSupport::Concern

    included do
      class_attribute :be_auto_published
      store :unpublished_data
      after_find :save_old_data
      before_save :copy_unpublished
      after_validation do
        @_for_edit = false
      end
    end

    def save_old_data
      @_data_was = self.data.clone
    end

    def copy_unpublished()
      self.unpublished_data = data.clone
      if @_publish_now
        @_data_was = data.clone
      else
        self.data = @_data_was
      end
      @_publish_now = false
      if self.class.be_auto_published
        self.data = self.unpublished_data
      end
      true
    end

    def publish!
      self.data = self.unpublished_data.clone
      @_publish_now = true
      save!
    end

    def revert!
      self.unpublished_data = self.data.clone
      save!
    end

    def show!
      self.update_column(:visible, true)
      reload
    end

    def hide!
      self.update_column(:visible, false)
      reload
    end

    def reload
      super
      save_old_data
      self
    end

    def unpublished_changes?
      @_data_was != unpublished_data_was
    end

    def for_edit
      @_for_edit = true
      self.data = self.unpublished_data.clone unless self.unpublished_data.empty?
      self
    end

    alias_method :for_edit!, :for_edit

    module ClassMethods
      def auto_publish
        self.be_auto_published = true
      end
    end
  end
end