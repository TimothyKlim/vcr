# Borrowed from:
# https://github.com/carlhuda/bundler/blob/v1.1.rc.7/spec/quality_spec.rb
require "spec_helper"

describe "The library itself" do
  #http://stackoverflow.com/questions/2982677/ruby-1-9-invalid-byte-sequence-in-utf-8
  def encode str
    if String.method_defined?(:encode)
      str.encode!('UTF-8', 'UTF-8', :invalid => :replace)
    else
      ic = Iconv.new('UTF-8', 'UTF-8//IGNORE')
      ic.iconv(str)
    end
  end

  def check_for_tab_characters(filename)
    failing_lines = []
    File.readlines(filename).each_with_index do |line,number|
      failing_lines << number + 1 if encode(line) =~ /\t/
    end

    unless failing_lines.empty?
      "#{filename} has tab characters on lines #{failing_lines.join(', ')}"
    end
  end

  def check_for_extra_spaces(filename)
    failing_lines = []
    File.readlines(filename).each_with_index do |line,number|
      next if encode(line) =~ /^\s+#.*\s+\n$/
      failing_lines << number + 1 if encode(line) =~ /\s+\n$/
    end

    unless failing_lines.empty?
      "#{filename} has spaces on the EOL on lines #{failing_lines.join(', ')}"
    end
  end

  RSpec::Matchers.define :be_well_formed do
    failure_message_for_should do |actual|
      actual.join("\n")
    end

    match do |actual|
      actual.empty?
    end
  end

  it "has no malformed whitespace" do
    error_messages = []
    Dir.chdir(File.expand_path("../..", __FILE__)) do
      `git ls-files`.split("\n").each do |filename|
        next if filename =~ /vendor|.feature|.yml|.gitmodules/
        error_messages << check_for_tab_characters(filename)
        error_messages << check_for_extra_spaces(filename)
      end
    end
    expect(error_messages.compact).to be_well_formed
  end
end

