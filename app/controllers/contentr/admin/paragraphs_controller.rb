# encoding: utf-8
class Contentr::Admin::ParagraphsController < Contentr::Admin::ApplicationController
  before_filter :find_page_or_site

  def index
    @paragraphs = @page.paragraphs.order_by(:area_name, :asc).order_by(:position, :asc)
  end

  def new
    @area_name = params[:area_name]

    if params[:type].present?
      @paragraph = paragraph_type_class.new(area_name: @area_name)
      render 'new'
    else
      render 'new_select'
    end
  end

  def create
    @paragraph = paragraph_type_class.new(params[:paragraph].merge(:area_name => params[:area_name]))
    @page_or_site.paragraphs << @paragraph
    if @page_or_site.save
      flash[:notice] = 'Paragraph created'
      redirect_to contentr_admin_pages_path(root: @page.id)
    else
      render :action => :new
    end
  end

  def edit
    @paragraph = @page_or_site.paragraphs.find(params[:id])
    @paragraph.for_edit
  end

  def update
    @paragraph = @page_or_site.paragraphs.select { |p| p.id.to_s == params[:id] }.first
    if @paragraph.update_attributes(params[:paragraph])
      flash[:notice] = 'Paragraph saved'
      redirect_to contentr_admin_edit_paragraph_path(page_id: @page, id: @paragraph, site: params[:site])
    else
      render :action => :edit
    end
  end

  def publish
    @paragraph = @page_or_site.paragraphs.find(params[:id])
    @paragraph.publish!
    flash[:notice] = "Published this paragraph"
    redirect_to contentr_admin_pages_path(root: @page.id)
  end

  def show_version
    @paragraph = @page_or_site.paragraphs.find(params[:id])
    if params[:current] == "1" && contentr_publisher?
      s = ""
      s += @paragraph.unpublished_data[:body].html_safe
      s += view_context.image_tag(@paragraph.image_unpublished_url) if @paragraph.unpublished_data.has_key?("image_unpublished")
    else
      s = ""
      s += @paragraph.data[:body].html_safe
      s += view_context.image_tag(@paragraph.image_url) if @paragraph.data.has_key?("image")
    end
    render text: s
  end

  def destroy
    paragraph = @page_or_site.paragraphs.find(params[:id])
    paragraph.destroy
    flash[:error] = "Paragraph was destroyed"
    redirect_to :back
  end

  def reorder
    paragraphs_ids = params[:paragraph]
    paragraphs = @page_or_site.paragraphs_for_area(params[:area_name]).sort { |x,y| paragraphs_ids.index(x.id.to_s) <=> paragraphs_ids.index(y.id.to_s) }
    paragraphs.each_with_index { |p, i| p.update_attribute(:position, i) }
    head :ok
  end

  protected

  def paragraph_type_class
    paragraph_type_string = params[:type] # e.g. Contentr::HtmlParagraph
    paragraph_type_class = paragraph_type_string.classify.constantize # just to be sure
    paragraph_type_class if paragraph_type_class < Contentr::Paragraph
  end

  def find_page_or_site
    if (params[:site] == 'true')
      @page_or_site = Contentr::Site.default
      @page = Contentr::Page.find(params[:page_id])
    else
      @page_or_site = Contentr::Page.find(params[:page_id])
      @page = @page_or_site
    end
  end

end
