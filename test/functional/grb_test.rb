require File.join( File.dirname(__FILE__), '..', 'test_helper')

class GRBTest < Test::Unit::TestCase
  include ShouldaFunctionalHelpers

  on_a_repository do
    context "creating a branch in a local clone" do
      setup do
        in_directory_for :local1
        run_grb_with 'create new_branch'
      end
      
      should_have_branch 'new_branch', :local
      should_have_branch 'new_branch', :remote
      
      context "the remote repository" do
        setup do
          in_directory_for :remote
        end
        
        should_have_branch 'new_branch', :local
      end
      
      context "the other local clone, tracking the new branch" do
        setup do
          in_directory_for :local2
          assert_match(/local2\Z/, execute('pwd').chomp) #Sanity check
          
          run_grb_with 'track new_branch'
        end
        
        should_have_branch 'new_branch', :local
        should_have_branch 'new_branch', :remote
      end
      
      context "then deleting the branch" do
        setup do
          run_grb_with 'delete new_branch'
        end
        
        should_not_have_branch 'new_branch', :local
        should_not_have_branch 'new_branch', :remote
        
        context "the remote repository" do
          setup do
            in_directory_for :remote
          end

          should_not_have_branch 'new_branch', :local
        end
      end
    end
  end

  in_a_non_git_directory do
    context "displaying help" do
      setup do
        @text = run_grb_with 'help'
      end
      
      should "work" do
        words_in_help = %w{create delete explain git_remote_branch}
        words_in_help.each do |word|
          assert_match(/#{word}/, @text)
        end
        
        assert_no_match(/fatal: Not a git repository/, @text)
      end
    end
    
    context "running grb with a generic explain" do
      setup do
        @text = run_grb_with 'explain create'
      end
      
      should "display the commands to run with dummy values filled in" do
        #Not sure if this will turn out to be too precise to my liking...
        generic_words_in_explain_create = %w{
          origin current_branch refs/heads/branch_to_create
          git push fetch checkout}
        generic_words_in_explain_create.each do |word|
          assert_match(/#{word}/, @text)
        end
      end
    end
    
    #context "running grb with a detailed explain" do
    #  setup do
    #    @text = run_grb_with 'explain create'
    #  end
    #end
  end
end