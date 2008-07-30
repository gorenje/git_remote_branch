require File.join( File.dirname(__FILE__), '..', 'test_helper')

REGULAR_BRANCH_LISTING = <<-STR
  other_user/master
* stubbed_current_branch
  rubyforge
STR

BRANCH_LISTING_WHEN_NOT_ON_BRANCH = <<-STR
* (no branch)
  other_user/master
  master
  rubyforge
STR

class ParamReaderTest < Test::Unit::TestCase
  include ShouldaUnitHelpers

  context 'read_params' do
    context "when on a valid branch" do
      setup do
        grb.stubs(:`).returns(REGULAR_BRANCH_LISTING)
      end
      
      context "on a normal valid command without an origin" do
        setup do
          @p = grb.read_params %w{create the_branch}
        end
        
        should_set_action_to :create
        should_set_branch_to 'the_branch'
        should_set_origin_to 'origin'
        should_set_current_branch_to 'stubbed_current_branch'
        should_set_explain_to false
      end

      context "on a normal valid command" do
        setup do
          @p = grb.read_params %w{create the_branch the_origin}
        end
        
        should_set_action_to :create
        should_set_branch_to 'the_branch'
        should_set_origin_to 'the_origin'
        should_set_current_branch_to 'stubbed_current_branch'
        should_set_explain_to false
      end

      should_explain_with_current_branch 'stubbed_current_branch', "use real current branch"
      
      should_return_help_for_parameters %w(help), "on a 'help' command"
      should_return_help_for_parameters %w(create), "on an incomplete command"
      should_return_help_for_parameters %w(decombobulate something), "on an invalid command"
    end
    
    context "when on an invalid branch" do
      setup do
        grb.stubs(:`).returns(BRANCH_LISTING_WHEN_NOT_ON_BRANCH)
      end
      
      GitRemoteBranch::COMMANDS.each_key do |action|
        context "running the '#{action}' command" do
          setup do
            @command = [action.to_s, 'branch_name']
          end
          
          should "raise an InvalidBranchError" do
            assert_raise(GitRemoteBranch::InvalidBranchError) do
              grb.read_params(@command)
            end
          end

          context "raising an exception" do
            setup do
              begin
                grb.read_params(@command)
              rescue => @ex
              end
            end
            
            should "give a clear error message" do
              assert_match %r{identify.*branch}, @ex.message
            end
            
            should "display git's branch listing" do
              assert_match %r{\(no branch\)}, @ex.message
            end
          end
        end
      end
     
      should_explain_with_current_branch 'current_branch', "use a dummy value for the current branch"
      
      should_return_help_for_parameters %w(help), "on a 'help' command"
      should_return_help_for_parameters %w(create), "on an incomplete command"
      should_return_help_for_parameters %w(decombobulate something), "on an invalid command"
    end
  end
  
  context 'explain_mode!' do
    context "when it receives an array beginning with 'explain'" do
      setup do
        @array  = ['explain', 'create', 'some_branch']
      end

      should "return true" do
        assert grb.explain_mode!(@array)
      end

      should 'accept symbol arrays as well' do
        assert grb.explain_mode!( @array.map{|e| e.to_sym} )
      end

      should "remove 'explain' from the argument array" do
        grb.explain_mode!(@array)
        assert_equal ['create', 'some_branch'], @array
      end
    end

    context "when it receives an array that doesn't begin with 'explain'" do
      setup do
        @array  = ['create', 'some_branch']
      end

      should "return false" do
        assert_false grb.explain_mode!(@array)
      end

      should "not modify the argument array" do
        grb.explain_mode!(@array)
        assert_equal ['create', 'some_branch'], @array
      end
    end
  end
  
  context 'get_action' do
    GitRemoteBranch::COMMANDS.each_pair do |cmd, params|
      should "recognize all #{cmd} aliases" do
        params[:aliases].each do |alias_|
          assert cmd, grb.get_action(alias_) 
        end
      end
    end
    should 'return nil on unknown aliases' do
      assert_nil grb.get_action('please_dont_create_an_alias_named_like_this')
    end  
  end

  context 'get_origin' do
    should "default to 'origin' when the param is nil" do
      assert_equal 'origin', grb.get_origin(nil)
    end
    should "return the unchanged param if it's not nil" do
      assert_equal 'someword', grb.get_origin('someword')
    end
  end

end
