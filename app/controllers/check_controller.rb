class LinksController < ApplicationController
  def check
    link = Link.find_or_create_by!(uri: uri)

  end
end
