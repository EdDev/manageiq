class ContainerGroupController < ApplicationController
  include ContainersCommonMixin

  before_filter :check_privileges
  before_filter :get_session_data
  after_filter :cleanup_action
  after_filter :set_session_data

  def show_list
    process_show_list
  end

  private ############################

  def controller_name
    "container_group"
  end

  def display_name
    "Pods"
  end
end
