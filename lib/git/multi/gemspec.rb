module Git
  module Multi
    PIM = <<~"PIM".freeze # gem post_install_message, used in git-multi.gemspec

      The only required setting for \033[1mgit multi\33[0m is:

      \tgit config --global --add \033[1mgithub.token\033[0m <your_github_oauth_token>

      The following settings for \033[1mgit multi\33[0m are
      optional, and take 0, 1 or more values:

      \tgit config --global --add \033[1mgithub.users\033[0m <list_of_github_users>
      \tgit config --global --add \033[1mgithub.organizations\033[0m <list_of_github_orgs>

      Unless your top-level workarea is `${HOME}/Workarea` you should also set:

      \tgit config --global --add \033[1mgit.multi.workarea\033[0m <your_root_workarea>

      Thanks for using \033[1mgit multi\033[0m ... the ultimate multi-repo utility for git!

    PIM
  end
end
