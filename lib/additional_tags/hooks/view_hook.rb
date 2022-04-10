# frozen_string_literal: true

module AdditionalTags
  module Hooks
    class ViewHook < Redmine::Hook::ViewListener
      render_on :view_issues_bulk_edit_details_bottom,
                partial: 'issues/tags_form_details',
                locals: { tags_form: 'issues/tags_bulk_edit' }
      render_on :view_issues_context_menu_end, partial: 'context_menus/issues_tags'
      render_on :view_issues_form_details_bottom,
                partial: 'issues/tags_form_details',
                locals: { tags_form: 'issues/tags_form' }
      render_on :view_issues_show_details_bottom, partial: 'issues/tags'
      render_on :view_issues_sidebar_planning_bottom, partial: 'issues/tags_sidebar'
      render_on :view_layouts_base_html_head, partial: 'additional_tags/html_head'
      render_on :view_layouts_base_body_bottom, partial: 'additional_tags/body_bottom'
      render_on :view_wiki_form_bottom, partial: 'tags_form_bottom'
      render_on :view_wiki_show_bottom, partial: 'tags_show'
      render_on :view_wiki_show_sidebar_bottom, partial: 'wiki/tags_sidebar'

      def controller_issues_edit_before_save(context = {})
        tags_journal context[:issue], context[:params]
      end

      def controller_issues_bulk_edit_before_save(context = {})
        issue = context[:issue]
        params = context[:params]

        issues_bulk_tags_fix issue, params
        tags_journal issue, params
      end

      # this hook is missing in redmine core at the moment
      def view_issue_pdf_fields(context = {})
        issue = context[:issue]
        right = context[:right]

        if AdditionalTags.setting?(:active_issue_tags) &&
           User.current.allowed_to?(:view_issue_tags, issue.project)
          right << [l(:field_tag_list), issue.tag_list]
        end
      end

      # this hook is missing in redmine core at the moment
      def view_wiki_pdf_buttom(context = {})
        page = context[:page]
        pdf = context[:pdf]

        return if page.tag_list.blank?

        pdf.ln 5
        pdf.SetFontStyle 'B', 9
        pdf.RDMCell 190, 5, l(:field_tag_list), 'B'

        pdf.ln
        pdf.SetFontStyle '', 8
        pdf.RDMCell 190, 5, page.tag_list.join(', ')
        pdf.ln
      end

      private

      def issues_bulk_tags_fix(issue, params)
        return unless params && params[:issue]

        old_tags = issue.tags.map(&:name)
        new_tags = Array(params[:issue][:tag_list]).reject(&:empty?)
        issue.tag_list = (old_tags + new_tags).uniq
      end

      def tags_journal(issue, params)
        return unless params && params[:issue] && params[:issue][:tag_list]

        issue.tags_to_journal Issue.find_by(id: issue.id)&.tag_list&.to_s,
                              issue.tag_list.to_s
      end
    end
  end
end
