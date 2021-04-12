# frozen_string_literal: true

class IssueTagsController < ApplicationController
  before_action :find_issues, only: %i[edit update]

  def edit
    return unless AdditionalTags.setting?(:active_issue_tags) &&
                  User.current.allowed_to?(:edit_issue_tags, @projects.first)

    @issue_ids = params[:ids]
    @is_bulk_editing = @issue_ids.size > 1
    @issue_tags = if @is_bulk_editing
                    issues = @issues.map(&:tag_list)
                    issues.flatten!
                    issues.uniq
                  else
                    @issues.first.tag_list
                  end

    @issue_tags.sort!
    @most_used_tags = Issue.available_tags.most_used 10
  end

  def update
    if AdditionalTags.setting?(:active_issue_tags) &&
       User.current.allowed_to?(:edit_issue_tags, @projects.first)
      tags = params[:issue] && params[:issue][:tag_list] ? params[:issue][:tag_list].reject(&:empty?) : []

      unless User.current.allowed_to?(:create_issue_tags, @projects.first) || Issue.allowed_tags?(tags)
        flash[:error] = t :notice_failed_to_add_tags
        return
      end

      Issue.transaction do
        @issues.each do |issue|
          issue.tag_list = tags
          issue.save!
        end
      end
      flash[:notice] = t :notice_tags_added
    else
      flash[:error] = t :notice_failed_to_add_tags
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to add tags: #{e.inspect}"
    flash[:error] = t :notice_failed_to_add_tags
  ensure
    redirect_to_referer_or { render text: 'Tags updated.', layout: true }
  end
end
