# frozen_string_literal: true

class AdditionalTagsController < ApplicationController
  before_action :require_admin
  before_action :find_tag, only: %i[edit update]
  before_action :bulk_find_tags, only: %i[context_menu merge destroy]
  before_action :set_tag_list_path

  helper :additional_tags_issues

  def edit; end

  def destroy
    @tags.each do |tag|
      tag.reload.destroy
    rescue ::ActiveRecord::RecordNotFound
      Rails.logger.warn "Tag #{tag} could not be deleted"
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
    return unless request.post? &&
                  params[:tag].present? &&
                  params[:tag][:name].present?

    AdditionalTags::Tags.merge params[:tag][:name], @tags
    redirect_to @tag_list_path
  end

  private

  def set_tag_list_path
    @tag_list_path = plugin_settings_path id: 'additional_tags', tab: 'manage_tags'
  end

  def bulk_find_tags
    @tags = ActsAsTaggableOn::Tag.joins("LEFT JOIN #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.taggings_table}" \
                                        " ON #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.taggings_table}.tag_id =" \
                                        " #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.id ")
                                 .select("#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.id," \
                                         "#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.name," \
                                         "#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.taggings_count," \
                                         " COUNT(DISTINCT #{ActsAsTaggableOn.taggings_table}.taggable_id) AS count")
                                 .where(id: params[:id] ? [params[:id]] : params[:ids])
                                 .group("#{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.id" \
                                        ", #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.name" \
                                        ", #{ActiveRecord::Base.connection.quote_table_name ActsAsTaggableOn.tags_table}.taggings_count")

    raise ActiveRecord::RecordNotFound if @tags.empty?
  end

  def find_tag
    @tag = ActsAsTaggableOn::Tag.find params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
