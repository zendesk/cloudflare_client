module FactoryHelper
  def self.initializer
    -> { attributes.deep_symbolize_keys }
  end
end

RSpec.configure { FactoryGirl::SyntaxRunner.send(:include, FactoryHelper) }
