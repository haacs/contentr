class AddVisibleAtAndHideAtToContentrParagraphs < ActiveRecord::Migration
  def change
    change_table :contentr_paragraphs do |t|
      t.timestamp :visible_at
      t.timestamp :hide_at
    end
  end
end
