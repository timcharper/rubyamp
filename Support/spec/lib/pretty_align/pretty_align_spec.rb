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
end