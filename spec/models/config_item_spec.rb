require File.dirname(__FILE__) + '/../spec_helper'

describe "a ConfigItem loading values" do
  
  it "should instantiate db rows into its class" do
    ConfigItem.inspect.should_not raise_error
  end
end