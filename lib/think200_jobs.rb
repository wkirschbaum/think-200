module Think200

  FREE_QUEUE    = 'free'
  PREMIUM_QUEUE = 'premium'


  # Run a project's specs. Use like this:
  # `Resque.enqueue_to(FREE_QUEUE, ManualTest, project_id: 1, user_id: 2)`
  class ManualTest
    def self.perform(project_id, user_id)
      Think200::run_test(project_id: project_id, user_id: user_id, manual: true)
    end
  end

  # Also run a project's tests, but intended to be done from a cron job.
  class ScheduledTest
    def self.perform(project_id, user_id)
      Think200::run_test(project_id: project_id, user_id: user_id, manual: false)
    end
  end


  private

  def self.run_test(project_id: nil, user_id: nil, manual: nil)
    begin
      user = User.find(user_id)
      proj = user.projects.find(project_id)
    rescue ActiveRecord::RecordNotFound
      raise "#{user} doesn't have a project number #{project_id}"
    end

    collected_results = {}
    proj.expectations.each do |expectation|
      # Create an rspec file
      file = Tempfile.new('rspec')
      file.write(expectation.to_encapsulated_rspec)
      file.close

      # Prepare the rspec runner
      config = RSpec.configuration
      json_formatter = RSpec::Core::Formatters::JsonFormatter.new(config.out)
      reporter =  RSpec::Core::Reporter.new(json_formatter)
      config.instance_variable_set(:@reporter, reporter)

      # Run the rspec
      RSpec::Core::Runner.run([file.path])
      file.unlink
      collected_results[expectation.id] = json_formatter.output_hash
    end
    SpecRun.create!(raw_data: collected_results, project: proj, manual: manual)
  end
end
