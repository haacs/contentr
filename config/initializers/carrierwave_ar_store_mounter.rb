# # encoding: utf-8
# require 'carrierwave'
# require 'active_record'
# require 'carrierwave/validations/active_model'

# module CarrierWave
#   module ActiveRecord

#     include CarrierWave::Mount

#     def mount_store_uploader(store, column, uploader=nil, options={}, &block)
#       mount_uploader(column, uploader, options, &block)

#       self.send :define_method, :read_uploader do |nam| self.send(store)[nam.to_s] end
#       self.send :define_method, :write_uploader do |nam, val| self.send(store)[nam.to_s]=val end
#       public :read_uploader
#       public :write_uploader

#       include CarrierWave::Validations::ActiveModel

#       validates_integrity_of column if uploader_option(column.to_sym, :validate_integrity)
#       validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

#       after_save :"store_#{column}!"
#       before_save :"write_#{column}_identifier"
#       after_commit :"remove_#{column}!", :on => :destroy
#       before_update :"store_previous_model_for_#{column}"
#       after_save :"remove_previously_stored_#{column}"

#       class_eval <<-RUBY, __FILE__, __LINE__+1
#         def #{column}=(new_file)
#           column = _mounter(:#{column}).serialization_column
#           send(:"\#{column}_will_change!")
#           super
#         end

#         def remote_#{column}_url=(url)
#           column = _mounter(:#{column}).serialization_column
#           send(:"\#{column}_will_change!")
#           super
#         end

#         def remove_#{column}!
#           super
#           _mounter(:#{column}).remove = true
#           _mounter(:#{column}).write_identifier
#         end

#         def serializable_hash(options=nil)
#           hash = {}

#           except = options && options[:except] && Array.wrap(options[:except]).map(&:to_s)
#           only   = options && options[:only]   && Array.wrap(options[:only]).map(&:to_s)

#           self.class.uploaders.each do |column, uploader|
#             if (!only && !except) || (only && only.include?(column.to_s)) || (except && !except.include?(column.to_s))
#               hash[column.to_s] = _mounter(column).uploader.serializable_hash
#             end
#           end
#           super(options).merge(hash)
#         end
#       RUBY

#     end

#   end # ActiveRecord
# end # CarrierWave

# ActiveRecord::Base.extend CarrierWave::ActiveRecord
