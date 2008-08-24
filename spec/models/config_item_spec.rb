 describe "the base ConfigItem model" do
  it "should be a recognized constant" do
    lambda do
      "ConfigItem".constantize
    end.should_not raise_error    
  end

  it "should be an ancestor of ActiveRecord::Base" do
    ConfigItem.ancestors.include?(ActiveRecord::Base).should be_true
  end
end

describe "a ConfigItem loading values" do
  
  before(:all) do
    @config_items = YAML.load_file("fixtures/config_items.yml")
  end
  
  # this assumes rows already loaded from application.yml
  it "should instantiate db rows without error" do
    ConfigItem.load.should_not raise_error
  end
  
  it "should return an array" do
    ConfigItem.load.should be_an_array
  end
end