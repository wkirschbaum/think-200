# == Schema Information
#
# Table name: apps
#
#  created_at :datetime
#  id         :integer          not null, primary key
#  name       :string(255)
#  notes      :text
#  project_id :integer
#  updated_at :datetime
#

class App < ActiveRecord::Base
  belongs_to :project
  has_many   :requirements

  default_scope { order('name') }

  def to_rspec
    result = "context '#{name}' do\n"
    requirements.each { |e| result += e.to_rspec.indent(2) }
    result += "end\n"
  end
end
