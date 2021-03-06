module Contentr
  class NavPoint < ActiveRecord::Base
    include FormTranslation::ForModel

    belongs_to :site, class_name: 'Contentr::Site'
    belongs_to :page, class_name: 'Contentr::Page'
    belongs_to :parent_page, class_name: 'Contentr::Page'
    has_many :alternative_links, class_name: 'Contentr::AlternativeLink', dependent: :destroy

    after_create :set_actual_position!

    belongs_to :menu

    validate :url_xor_page
    validate :site_or_page_or_url_if_title_present

    translate_me :title, :url

    default_scope -> { order('position asc') }
    scope :visible, ->() { where(visible: true).order('position asc') }

    acts_as_tree

    accepts_nested_attributes_for :alternative_links, allow_destroy: true, reject_if: ->(attributes){
      attributes[:page_id].blank? && !attributes[:id].present?
    }

    def only_link?
      self.page.nil?
    end

    def self.navigation_tree
      self.where(parent_page_id: nil, nav_point_type: [nil, 'nav_point']).includes(page: :page_in_default_language).arrange(order: :position)
    end

    def set_actual_position!
      if self.ancestry.present?
        last_position = self.siblings.where.not(id: self.id).reorder('position DESC').limit(1)
      else
        last_position = self.class.where(parent_page_id: self.parent_page_id).where.not(id: self.id).reorder('position DESC').limit(1)
      end
      if last_position.any?
        self.update_columns(position: last_position.first.position + 1)
      end
    end

    def link
      if I18n.locale == I18n.default_locale
        url_xor_page_link
      else
        alternative = self.alternative_links.find_by(language: I18n.locale.to_s)
        if alternative.present?
          alternative.page.try(:url) || url_xor_page_link
        else
          url_xor_page_link
        end
      end
    end

    def self.navigation_roots
      roots.where(parent_page_id: nil, nav_point_type: [nil, 'nav_point']).order(position: :asc)
    end

    private

    def url_xor_page_link
      if self.page.present?
        self.page.url
      elsif self.url.present?
        self.url
      end
    end

    def url_xor_page
      if [page, url].compact.select(&:present?).count > 1
        errors.add(:url, :page_and_url_are_mutual_exclusive)
      end
    end

    def site_or_page_or_url_if_title_present
      if title.present? && [site, page, url].compact.select(&:present?).count == 0
        errors.add(:page, :site_or_page_or_url_must_be_present)
      end
    end
  end
end
