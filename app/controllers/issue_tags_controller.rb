# frozen_string_literal: true

class IssueTagsController < ApplicationController
  # Title and submit label of the modal per mode, without a mode the given tags replace the existing ones
  TAGS_MODES = { 'append' => %i[label_add_tags button_add],
                 'remove' => %i[label_remove_tags button_remove] }.freeze

  before_action :find_issues, :preload_tags, only: %i[edit update]

  def edit
    # The chosen issues may belong to several projects, every one of them has to allow it
    return deny_access unless AdditionalTags.setting?(:active_issue_tags) &&
                              User.current.allowed_to?(:edit_issue_tags, @projects)

    @issue_ids = params[:ids]
    @mode = tags_mode
    @title, @submit_label = TAGS_MODES.fetch @mode, %i[label_edit_tags button_save]
    @is_bulk_editing = @issue_ids.size > 1
    @issue_tags = if @is_bulk_editing
                    issues = @issues.map(&:tag_list)
                    issues.flatten!
                    issues.uniq
                  else
                    @issues.first.tag_list
                  end

    @issue_tags = AdditionalTag.sort_tags @issue_tags
    @most_used_tags = Issue.available_tags.most_used 10
  end

  def update
    mode = tags_mode
    failed_notice = mode == 'remove' ? :notice_failed_to_remove_tags : :notice_failed_to_add_tags

    if AdditionalTags.setting?(:active_issue_tags) &&
       User.current.allowed_to?(:edit_issue_tags, @projects)
      tags = params[:issue] && params[:issue][:tag_list] ? params[:issue][:tag_list].reject(&:empty?) : []
      # Adding or removing no tag changes nothing, only editing clears the tags with an empty list
      return if mode && tags.empty?

      # Removing creates no tag, so only adding and editing need the permission to create tags
      unless mode == 'remove' || User.current.allowed_to?(:create_issue_tags, @projects) || Issue.allowed_tags?(tags)
        flash[:error] = t failed_notice
        return
      end

      Issue.transaction do
        @issues.each do |issue|
          issue.init_journal User.current
          case mode
          when 'append' then issue.tag_list << tags
          when 'remove' then issue.tag_list.remove tags
          else issue.tag_list = tags
          end

          issue.tags_to_journal issue.tag_list_was&.to_s, issue.tag_list.to_s
          issue.save!
        end
      end
      flash[:notice] = t(mode == 'remove' ? :notice_tags_removed : :notice_tags_added)
    else
      flash[:error] = t failed_notice
    end
  rescue StandardError => e
    Rails.logger.warn "Failed to change tags: #{e.inspect}"
    flash[:error] = t failed_notice
  ensure
    redirect_to_referer_or { render plain: 'Tags updated.', layout: true }
  end

  private

  def tags_mode
    params[:mode] if TAGS_MODES.key? params[:mode]
  end

  # Every chosen issue reads its tag_list, which would be one query per issue otherwise
  def preload_tags
    ActiveRecord::Associations::Preloader.new(records: @issues, associations: :tags).call
  end
end
