require File.expand_path('../../../spec_helper', __FILE__)

describe "bundle flex_install" do
  it "installs the gems as expected" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack'
    G

    should_be_installed "rack 1.0.0"
    should_be_locked
  end

  it "installs even when the lockfile is invalid" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack'
    G

    should_be_installed "rack 1.0.0"
    should_be_locked

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rack', '1.0'
    G

    bundle :flex_install
    should_be_installed "rack 1.0.0"
    should_be_locked
  end

  it "keeps child dependencies at the same version" do
    build_repo2

    flex_install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "rack-obama"
    G

    should_be_installed "rack 1.0.0", "rack-obama 1.0.0"

    update_repo2
    flex_install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "rack-obama", "1.0"
    G

    should_be_installed "rack 1.0.0", "rack-obama 1.0.0"
  end

  describe "adding new gems" do
    it "installs added gems without updating previously installed gems" do
      build_repo2

      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
      G

      update_repo2

      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
        gem 'activesupport', '2.3.5'
      G

      should_be_installed "rack 1.0.0", 'activesupport 2.3.5'
    end

    it "keeps child dependencies pinned" do
      build_repo2

      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack-obama"
      G

      update_repo2

      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack-obama"
        gem "thin"
      G

      should_be_installed "rack 1.0.0", 'rack-obama 1.0', 'thin 1.0'
    end
  end

  describe "removing gems" do
    it "removes gems without changing the versions of remaining gems" do
      build_repo2
      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
        gem 'activesupport', '2.3.5'
      G

      update_repo2

      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
      G

      should_be_installed "rack 1.0.0"
      should_not_be_installed "activesupport 2.3.5"

      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
        gem 'activesupport', '2.3.2'
      G

      should_be_installed "rack 1.0.0", 'activesupport 2.3.2'
    end

    it "doesn't fuck up" do
      build_repo2
      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
        gem 'activesupport', '2.3.5'
      G

      update_repo2

      flex_install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem 'rack'
      G

      bundled_app(".bundle/environment.rb").delete
      should_not_be_installed "activesupport 2.3.5"
    end
  end

end