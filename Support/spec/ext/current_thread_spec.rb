require File.dirname(__FILE__) + "/../spec_helper.rb"
require File.dirname(__FILE__) + "/../../ext/current_thread.rb"

describe CurrentThread do
  before(:all) do
    Thread.extend(CurrentThread)
  end
  
  after(:each) do
    Thread.mappings.clear
  end
  
  describe ".current=" do
    it "creates a mapping so Thread.current returns the specified thread" do
      x = Thread.new { sleep 1 }
      Thread.current = x
      Thread.current.should == x
    end
    
    it "garbage collects dead threads upon assignment" do
      x = Thread.new { sleep 1 }
      y = Thread.new { Thread.current = x }
      Thread.mappings[y].should == x
      y.join
      Thread.current = nil
      Thread.mappings[y].should be_nil
    end
    
    it "clears the mapping upon assigning nil" do
      x = Thread.new { sleep 1 }
      my_original_thread = Thread.current
      Thread.current = x
      Thread.current = nil
      Thread.current.should == my_original_thread
    end
  end
end
