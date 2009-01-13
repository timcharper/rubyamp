require File.dirname(__FILE__) + "/../spec_helper.rb"

ENV['RUBYAMP_TESTING'] = 'true'

describe RubyAMP::PrettyAlign do
  include RubyAMP::PrettyAlign
  
  
  it "should align at a given text sequence" do
    input = <<EOF
when "this string" then value
when "other string" then value
EOF
    expected = <<EOF
when "this string"  then value
when "other string" then value
EOF
    pretty_align(input, "then").should == expected
  end
  
  it "should align at a given operator" do
    input = <<EOF
:apples => "A delicious fruit",
:cats => "A wonderful speed bump"
EOF
    expected = <<EOF
:apples => "A delicious fruit",
:cats   => "A wonderful speed bump"
EOF
    pretty_align(input, "=>").should == expected
  end
  
  it "should align at each occurrence of the match" do
    input = <<-EOF
      :a => "Apple", :b => "Butterfly", :c => "Creation",
      :d => "Dog", :e => "Eel", :f => "Frog", :g => "Garbage",
      :h => "Hydrogen", :i => "Igloo", :j => "Jack Rabbit"
    EOF
    expected = <<-EOF
      :a => "Apple",    :b => "Butterfly", :c => "Creation",
      :d => "Dog",      :e => "Eel",       :f => "Frog",     :g => "Garbage",
      :h => "Hydrogen", :i => "Igloo",     :j => "Jack Rabbit"
    EOF
    pretty_align(input).should == expected
    pretty_align(input, '/=.?|,/').should == expected
  end
  
  it "should accept strings or regexps" do
    input = %[:name => "Billy bob thorton",
      :options => {:backflip => true}]
    expected = %[:name          => "Billy bob thorton",
      :options => {:backflip => true}]
    pretty_align(input, "=>").should == expected
    pretty_align(input, /=./).should == expected
    pretty_align(input, /=./ixm).should == expected
  end
  
  it "should not modify if a match is not found" do
    input = %[:name => "Me",\n:greeting => "Hi"]
    pretty_align(input, "=.").should == input
    pretty_align(input, /=\./).should == input
  end
  
  it "should align my specs :-)" do
    input = <<-EOF
      pretty_align(input, "=>").should == expected
      pretty_align(input, /=./).should == expected
      pretty_align(input, /=./ixm).should == expected
    EOF
    expected = <<-EOF
      pretty_align(input, "=>").should    == expected
      pretty_align(input, /=./).should    == expected
      pretty_align(input, /=./ixm).should == expected
    EOF
    pretty_align(input, "==").should == expected
    pretty_align(input, /==/).should == expected
  end
  
  it "should not raise if the input is blank" do
pretty_align(nil, '==')
    lambda { pretty_align(nil, '==') }.should_not raise_error
    lambda { pretty_align(nil, nil) }.should_not raise_error
    lambda { pretty_align('', nil) }.should_not raise_error
    lambda { pretty_align('', '') }.should_not raise_error
  end
end
