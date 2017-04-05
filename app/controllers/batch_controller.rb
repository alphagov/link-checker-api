class BatchController < ApplicationController
  def create
    link = Link.find_or_create_by!(uri: uri)

  end

  def show

  end
end
