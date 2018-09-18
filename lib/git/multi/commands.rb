module Git
  module Multi
    module Commands

      module_function

      def version
        puts Git::Multi::LONG_VERSION
      end

      def check
        Settings.user_status(Git::Multi::USER)
        Settings.organization_status(Git::Multi::ORGANIZATIONS)
        Settings.token_status(Git::Multi::TOKEN)
        Settings.home_status(Git::Multi::HOME)
        Settings.main_workarea_status(Git::Multi::WORKAREA)
        Settings.user_workarea_status(Git::Multi::USER)
        Settings.organization_workarea_status(Git::Multi::ORGANIZATIONS)
        Settings.file_status(Git::Multi::REPOSITORIES)
      end

      def help
        # instead of maintaining a list of valid query args in the help-
        # file, we determine it at runtime... less is more, and all that
        # TODO remove attributes we 'adorned' the repos with on line 95?
        query_args = Git::Multi.repositories.sample.fields.sort.each_slice(3).map {
          |foo, bar, qux| '%-20s  %-20s %-20s' % [foo, bar, qux]
        }
        puts File.read(Git::Multi::MAN_PAGE) % {
          :version => Git::Multi::VERSION,
          :query_args => query_args.join("\n    "),
        }
      end

      def report
        if (missing_repos = Git::Multi::missing_repositories).any?
          notify(missing_repos.map(&:full_name), :subtitle => "#{missing_repos.count} missing repos")
        end
      end

      def list
        puts Git::Multi.repositories.map(&:full_name)
      end

      def archived
        puts Git::Multi.archived_repositories.map(&:full_name)
      end

      def forked
        puts Git::Multi.forked_repositories.map(&:full_name)
      end

      def private
        puts Git::Multi.private_repositories.map(&:full_name)
      end

      def paths
        puts Git::Multi.repositories.map(&:local_path)
      end

      def missing
        puts Git::Multi.missing_repositories.map(&:full_name)
      end

      def excess
        puts Git::Multi.excess_repositories.map(&:full_name)
      end

      def stale
        puts Git::Multi.stale_repositories.map(&:full_name)
      end

      def spurious
        puts Git::Multi.spurious_repositories.map(&:full_name)
      end

      def count
        # https://developer.github.com/v3/repos/#list-user-repositories
        user = Git::Multi::USER
        %w{ all owner member }.each { |type|
          puts ["#{user}/#{type}", Git::Hub.user_repositories(user, type).count].join("\t")
        }
        # https://developer.github.com/v3/repos/#list-organization-repositories
        for org in Git::Multi::ORGANIZATIONS
          %w{ all public private forks sources member }.each { |type|
            puts ["#{org}/#{type}", Git::Hub.org_repositories(org, type).count].join("\t")
          }
        end
      end

      def refresh
        Git::Multi.refresh_repositories
      end

      def json
        puts Git::Multi.repositories.to_json
      end

      def clone
        Git::Multi.missing_repositories.each do |repo|
          FileUtils.mkdir_p repo.parent_dir
          repo.just_do_it(
            ->(project) {
              notify "Cloning '#{repo.full_name}' repo into #{repo.parent_dir.parent}"
              Kernel.system "git clone -q #{project.rels[:ssh].href.shellescape}"
            },
            ->(project) {
              Kernel.system "git clone -q #{project.rels[:ssh].href.shellescape}"
            },
            :in_dir => :parent_dir
          )
        end
      end

      def query args = []
        Git::Multi.repositories.each do |repo|
          repo.just_do_it(
            ->(project) {
              args.each do |attribute|
                puts "#{attribute}: #{project[attribute]}"
              end
            },
            ->(project) {
              print "#{project.full_name}: "
              puts args.map { |attribute| project[attribute] }.join(' ')
            },
          )
        end
      end

      def system args = []
        args.map!(&:shellescape)
        Git::Multi.cloned_repositories.each do |repo|
          repo.just_do_it(
            ->(project) {
              Kernel.system "#{args.join(' ')}"
            },
            ->(project) {
              Kernel.system "#{args.join(' ')} 2>&1 | sed -e 's#^##{project.full_name.shellescape}: #'"
            },
            :in_dir => :local_path
          )
        end
      end

      def raw args
        args.unshift ['sh', '-c']
        system args.flatten
      end

      def exec command, args = []
        args.unshift ['git', '--no-pager', command]
        system args.flatten
      end

      def find commands
        Git::Multi.cloned_repositories.each do |repo|
          Dir.chdir(repo.local_path) do
            begin
              if repo.instance_eval(commands.join(' && '))
                repo.just_do_it(
                  ->(project) { nil ; },
                  ->(project) { puts project.full_name ; },
                )
              end
            rescue Octokit::NotFound
              # project no longer exists on github.com
              # consider running "git multi --stale"...
            end
          end
        end
      end

      def eval commands
        Git::Multi.cloned_repositories.each do |repo|
          Dir.chdir(repo.local_path) do
            begin
              repo.instance_eval(commands.join(' ; '))
            rescue Octokit::NotFound
              # project no longer exists on github.com
              # consider running "git multi --stale"...
            end
          end
        end
      end

    end
  end
end