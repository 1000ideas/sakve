class TagsController < ApplicationController

  layout "l/layouts/admin"

  # GET /tags
  # GET /tags.xml
  def index
    authorize! :menage, :all
    @tags = Tag

    unless filter(:name).blank?
      @tags = @tags.
        where("`name` LIKE ?", "%#{filter(:name)}%")
    end

    unless params[:q].blank?
      @tags = @tags.
        where('`name` like ?', "#{params[:q]}%").
        order('`items_count` DESC')
    end
    
    @tags = @tags.order(sort_order) if sort_results?
    
    @tags = @tags.all.paginate page: params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render json: @tags.map(&:name) }
    end
  end

  # GET /tags/1
  # GET /tags/1.xml
  def show
    authorize! :menage, :all
    @tag = Tag.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @tag }
    end
  end

  # GET /tags/new
  # GET /tags/new.xml
  def new
    authorize! :menage, :all
    @tag = Tag.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @tag }
    end
  end

  # GET /tags/1/edit
  def edit
    authorize! :menage, :all
    @tag = Tag.find(params[:id])
  end

  # POST /tags
  # POST /tags.xml
  def create
    authorize! :menage, :all
    @tag = Tag.new(params[:tag])

    respond_to do |format|
      if @tag.save
        format.html { redirect_to(tags_path, notice: I18n.t('create.success') ) }
        format.xml  { render xml: @tag, status: :created, location: @tag }
      else
        format.html { render action: "new" }
        format.xml  { render xml: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tags/1
  # PUT /tags/1.xml
  def update
    authorize! :menage, :all
    @tag = Tag.find(params[:id])

    respond_to do |format|
      if @tag.update_attributes(params[:tag])
      format.html { redirect_to(tags_path, notice: I18n.t('update.success') ) }
      format.xml  { head :ok }
      else
      format.html { render action: "edit" }
      format.xml  { render xml: @tag.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tags/1
  # DELETE /tags/1.xml
  def destroy
    authorize! :menage, :all
    @tag = Tag.find(params[:id])
    @tag.destroy

    respond_to do |format|
      format.html { redirect_to :back, notice: I18n.t('delete.success') } 
      format.xml  { head :ok }
    end
  end
end
