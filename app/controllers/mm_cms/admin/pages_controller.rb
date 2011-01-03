# coding: utf-8

class MmCms::Admin::PagesController < MmCms::Admin::ApplicationController

  respond_to :html
  respond_to :json, :only => :update

  before_filter :setup

  def index

  end

  def edit
    @page = MmCms::Page.find(params[:id])
    populate_data_fields
  end

  def populate_data_fields(data_params = {})
    # build the data array based on the page model for editing
    if @page.model.present?
      @page.model.data_descriptions.each do |dd|
        name = dd.name

        existing_data = @page.data.get(name)
        unless existing_data
          if dd.type == 'text'
            @page.data << MmCms::Data::TextData.new(:name => dd.name)
          end

          if dd.type == 'string'
            @page.data << MmCms::Data::StringData.new(:name => dd.name)
          end
        end
      end
    end
    # populate with data
    if data_params.present?
      @page.data.each do |data|
        value = data_params[data.name]
        data.value = value
      end
    end
  end

  def set_model_validation_options
    @page.data.each do |data|
      # TODO: Read options from model
      data.model_validation_options = {:required => true}
    end
  end

  def update
    @page = MmCms::Page.find(params[:id])

    data_params = params[:page][:data_attributes]
    if data_params.present? and data_params.values.present?
      data_params = data_params.values.inject({}){ |m, v| m[v['name']] = v['value']; m }
      populate_data_fields(data_params)
    end

    set_model_validation_options

    # create/update page data
    #model = MmCms.page_model(@page.template)
    #if (model.present?)
    #  data = params[:page][:data]
    #  if data.present?
    #    @page.data.delete_all
    #    @page.reload
    #    data.each do |name, data|
    #      dd = model.get_description(name)
    #      if dd.present?
    #        case dd.type
    #        when 'text'
    #          @page.data << MmCms::Data::TextData.new(:name => name, :value => data['value'])
    #        when 'string'
    #          @page.data << MmCms::Data::StringData.new(:name => name, :value => data['value'])
    #        end
    #        @page.save
    #      end
    #    end
    #  end
    #end

    # update page
    if @page.update_attributes(params[:page])
      redirect_to :action => :edit
    else
      render :edit
    end
  end

  def reorder
    @page = MmCms::Page.find(params[:id])

    sibling_id = params[:sibling_id]
    @sibling = sibling_id ? MmCms::Page.find(sibling_id) : nil
    parent_id = params[:parent_id]
    @new_parent = parent_id ? MmCms::Page.find(parent_id) : nil

    @page.update_attributes(:parent => @new_parent)
    @sibling.present? ? @page.move_above(@sibling) : @page.move_to_bottom

    render :nothing => true, :status => 200
  end

  def navigation
    parent_id = params[:parent_id]
    @parent_page = parent_id.present? ? MmCms::Page.find(parent_id) : nil

    @pages = @parent_page.present? ? @parent_page.children.asc(:position) : MmCms::Page.roots.asc(:position)
  end

  protected

  def setup
    @mainmenu_id = 'pages'
  end

end