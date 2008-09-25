require File.dirname(__FILE__) + "/../spec_helper.rb"

describe RubyAMP::Config do
  before(:each) do
    RubyAMP.unload("Config")
  end
  
  it "should return a global config path relative to RubyAMP::LIB_ROOT" do
    RubyAMP::Config::CONFIG_PATHS[:global].should == RubyAMP::LIB_ROOT + "/../../config.yml"
  end

  it "should return a local config path relative to RubyAMP.project_path" do
    RubyAMP::Config::CONFIG_PATHS[:local].should == RubyAMP.project_path + "/.rubyamp-config.yml"
  end
  
  it "should convert lambda procs to values" do
    RubyAMP::Config.config(:default)[:rspec_story_bundle_path].should_not be_kind_of(Proc)
  end
  
  it "should treat cascade default values appropriately" do
    RubyAMP::Config[:server_port].should == 3000
    
    RubyAMP::Config[:server_port, :global] = 3005
    RubyAMP::Config[:server_port].should == 3005
    
    RubyAMP::Config[:server_port, :local] = 3001
    RubyAMP::Config[:server_port].should == 3001
  end
  
  it "should create a default config file" do
    RubyAMP::Config.should_receive(:store_config).with(:local)
    RubyAMP::Config.create_config(:local)
  end
  
  it "should store a config file" do
    RubyAMP::Config.config(:local).should_receive(:to_yaml)
    File.should_receive(:open).with(RubyAMP::Config::CONFIG_PATHS[:local], "wb")
    RubyAMP::Config.store_config(:local)
  end
    
  describe "default procs" do
    it "should detect the default rspec story bundle with out regard for case" do
      Dir.stub!(:entries).and_return(%w[rspeC-stOry-runner.tmBundle])
      RubyAMP::Config::DEFAULTS["rspec_story_bundle_path"].call.should == "rspeC-stOry-runner.tmBundle"
    end
  end
end