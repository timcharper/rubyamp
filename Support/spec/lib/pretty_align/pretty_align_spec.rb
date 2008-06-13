require File.dirname(__FILE__) + "/../../spec_helper.rb"

describe RubyAMP::PrettyAlign do
  it "should align at a given text sequence" do
    input = <<EOF
when "this string" then value
when "other string" then value
EOF
    expected = <<EOF
when "this string"  then value
when "other string" then value
EOF
    pretty_align("then", input).should == expected
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
    pretty_align("=>", input).should == expected
  end
  
  it "should align only at the first occurrence of each match" do
    input = <<EOF
:name => "Billy bob thorton",
:options => {:backflip => true}
EOF
    expected = <<EOF
:name    => "Billy bob thorton",
:options => {:backflip => true}
EOF
    pretty_align("=>", input).should == expected
  end
end