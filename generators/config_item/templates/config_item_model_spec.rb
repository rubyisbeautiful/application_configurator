describe "the base ConfigItem model" do
  it "should be a loaded" do
    lambda do
      "ConfigItem".constantize
    end.should_not raise_error    
  end

  it "should be an ancestor of ActiveRecord::Base" do
    ConfigItem.ancestors.include?(ActiveRecord::Base).should be_true
  end
end

describe "a ConfigItem loading values into the db" do
  
  it "should read the yaml file without error" do
    lambda do
      ConfigItem.read_from_yaml
    end.should_not raise_error
  end
  
  it "should load the values into the db" do
    ConfigItem.delete_all
    ConfigItem.count.should == 0
    ConfigItem.read_from_yaml
    ConfigItem.count.should > 0
  end
end

describe "a ConfigItem instantiating rows" do
  
  # this assumes rows already loaded from application.yml
  xit "should instantiate db rows without error" do
    ConfigItem.load.should_not raise_error
  end
  
  xit "should return an array" do
    ConfigItem.load.should be_an_array
  end
end