# frozen_string_literal: true

Rails.application.routes.draw do
  resources :auto_completes, only: [] do
    collection do
      get :wiki_tags
      get :issue_tags
      get :all_tags
    end
  end

  resources :additional_tags, only: %i[index edit update] do
    collection do
      post :merge
      get :context_menu, :merge
      delete :destroy
    end
  end

  resource :issue_tags, only: %i[edit] do
    collection do
      post :update
    end
  end

  resources :projects, only: [] do
    resources :wiki, only: [], as: 'wiki_page' do
      member do
        put :update_tags
      end
    end
  end
end
