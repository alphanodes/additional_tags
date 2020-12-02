class AdditionalTagsController < ApplicationController
  before_action :require_admin
  before_action :find_tag, only: %i[edit update]
  before_action :bulk_find_tags, only: %i[context_menu merge destroy]
  before_action :set_tag_list_path

  helper :additional_tags_issues

  def edit; end

  def destroy
    @tags.each do |tag|
      begin
        tag.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
        Rails.logger.warn "Tag #{tag} could not be deleted"
      end
    end
    redirect_back_or_default @tag_list_path
  end

  def update
    @tag.name = params[:tag][:name] if params[:tag]
    if @tag.save
      flash[:notice] = l :notice_successful_update
      respond_to do |format|
        format.html do
          redirect_to @tag_list_path
        end
        format.xml
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
      end
    end
  end

  def context_menu
    @tag = @tags.first if @tags.size == 1
    @back = back_url
    render layout: false
  end

  def merge
    return unless request.post? && params[:tag].present? && params[:tag][:name].present?

    ActsAsTaggableOn::Tagging.transaction do
      tag = ActsAsTaggableOn::Tag.find_by(name: params[:tag][:name]) || ActsAsTaggableOn::Tag.create(name: params[:tag][:name])
      # Update old tagging with new tag
      ActsAsTaggableOn::Tagging.where(tag_id: @tags.map(&:id)).update_all tag_id: tag.id
      # remove old (merged) tags
      @tags.reject { |t| t.id == tag.id }.each(&:destroy)
      # remove duplicate taggings
      dup_scope = ActsAsTaggableOn::Tagging.where(tag_id: tag.id)
      valid_ids = dup_scope.group(:tag_id, :taggable_id, :taggable_type, :context).pluck(Arel.sql('MIN(id)'))
      dup_scope.where.not(id: valid_ids).destroy_all if valid_ids.any?
      # recalc count for new tag
      ActsAsTaggableOn::Tag.reset_counters tag.id, :taggings
      redirect_to @tag_list_path
    end
  end

  private

  def set_tag_list_path
    @tag_list_path = plugin_settings_path id: 'additional_tags', tab: 'manage_tags'
  end

  def bulk_find_tags
    @tags = ActsAsTaggableOn::Tag.joins("JOIN #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.taggings_table}" \
                                        " ON #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.taggings_table}.tag_id =" \
                                        " #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.id ")
                                 .select("#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.*," \
                                         " COUNT(DISTINCT #{ActsAsTaggableOn.taggings_table}.taggable_id) AS count")
                                 .where(id: params[:id] ? [params[:id]] : params[:ids])
                                 .group("#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.id" \
                                        ", #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.name")
    raise ActiveRecord::RecordNotFound if @tags.empty?
  end

  def find_tag
    @tag = ActsAsTaggableOn::Tag.find params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
