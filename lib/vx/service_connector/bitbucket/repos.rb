module Vx
  module ServiceConnector
    class Bitbucket
      Repos = Struct.new(:session) do

        def to_a
          @repos ||= user_repositories
        end

        private

          def user_repositories
            res = session.get("api/1.0/user/repositories")
            res.select do |repo|
              git?(repo) && repo_access?(repo['owner'])
            end.map do |repo|
              repo_to_model repo
            end
          end

          def repo_to_model(repo)
            name = repo['owner'] + "/" + repo['slug']
            Model::Repo.new(
              '-1',
              name,
              repo['is_private'],
              "git@#{session.endpoint.host}/#{name}.git",
              "#{session.endpoint}/#{name}",
              repo['description']
            )
          end

          def team_admin
            @team_admin ||= begin
              values = session.get("api/1.0/user/privileges")['teams']
              values.select{|k,v| v == 'admin' }.keys
            end
          end

          def login
            session.login
          end

          def git?(repo)
            repo['scm'] == 'git'
          end

          def repo_access?(repo_owner)
            repo_owner == login ||
              team_admin.include?(repo_owner)
          end

      end
    end
  end
end
