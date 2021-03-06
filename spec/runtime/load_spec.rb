require File.expand_path('../../spec_helper', __FILE__)

describe "Bundler.load" do

  before :each do
    system_gems "rack-1.0.0"
    # clear memoized method results
    Bundler.instance_eval do
      @load = nil
      @runtime = nil
    end
  end

  it "provides a list of the env dependencies" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    env = Bundler.load
    env.dependencies.should have_dep("rack", ">= 0")
  end

  it "provides a list of the resolved gems" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    env = Bundler.load
    env.gems.should have_gem("rack-1.0.0")
  end

  it "raises an exception if the default gemfile is not found" do
    lambda {
      Bundler.load
    }.should raise_error(Bundler::GemfileNotFound, /could not locate gemfile/i)
  end

  it "raises an exception if a specified gemfile is not found" do
    lambda {
      ENV['BUNDLE_GEMFILE'] = "omg.rb"
      Bundler.load
    }.should raise_error(Bundler::GemfileNotFound, /omg\.rb/)
  end

  describe "when called twice" do
    it "doesn't try to load the runtime twice" do
      system_gems "rack-1.0.0", "activesupport-2.3.5"
      gemfile <<-G
        gem "rack"
        gem "activesupport", :group => :test
      G

      ruby <<-R
        require "bundler"
        Bundler.setup :default
        Bundler.require :default
        puts RACK
        begin
          require "activesupport"
        rescue LoadError
          puts "no activesupport"
        end
      R

      out.split("\n").should == ["1.0.0", "no activesupport"]
    end
  end

  describe "not hurting brittle rubygems" do
    before :each do
      system_gems "activerecord-2.3.2", "activesupport-2.3.2"
    end

    it "does not inject #source into the generated YAML of the gem specs" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activerecord"
      G

      Bundler.load.specs.each do |spec|
        spec.to_yaml.should_not =~ /^\s+source:/
        spec.to_yaml.should_not =~ /^\s+groups:/
      end
    end
  end
end