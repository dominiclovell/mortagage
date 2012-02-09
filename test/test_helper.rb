ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  FixturesDir = File.expand_path(File.dirname(__FILE__) + "/fixtures") unless const_defined?('FixturesDir')

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually 
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

  # Add more helper methods to be used by all tests here...
  
  def wrap_with_controller( new_controller = ApplicationController )
    old_controller = @controller
    @controller = new_controller.new
    yield
    @controller = old_controller
  end

  def login_regular
    wrap_with_controller do
      post(
        :home,
        {:user => {:email => 'a@b.c', :password => '1234'}}
      )
    end
  end
  
  #this allows you to do loan(:fixture_name) to return an instance
  #of a fixture in the broker database
  def method_missing(symbol, *args)
    begin
      eval("#{symbol.to_s.camelize}.find(#{Fixtures.identify(args[0])})")
    rescue
      super
    end
  end

  def load_user
    Fixtures.create_fixtures(FixturesDir, "user") {AccountModel.connection}
    Fixtures.create_fixtures(FixturesDir, "account") {AccountModel.connection}
    broker_account = BrokerAccount.new( :name => account(:default).name)
    broker_account.id = account(:default).id
    broker_account.save!
    broker_user = BrokerUser.new( :email => user(:authorized_user).email, :account_id => broker_account.id )
    broker_user.id = user(:authorized_user).id
    broker_user.save!
  end
end
