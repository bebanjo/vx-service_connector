module Vx
  module ServiceConnector
    class Bitbucket
      Payload = Struct.new(:session, :params) do

        def build
          binding.pry
          ServiceConnector::Model::Payload.new(
            !!ignore?,
            pull_request?,
            pull_request_number,
            branch,
            branch_label,
            sha,
            message,
            author,
            author_email,
            web_url
          )
        end

            # Model::Payload.from_hash(
            #   skip:          false,
            #   pull_request?: false,
            #   branch:        branch,
            #   branch_label:  branch,
            #   sha:           commit.hash,
            #   message:       commit.message,
            #   author:        author.strip,
            #   author_email:  email.tr('>',''),
            #   web_url:       commit.links.html.href
            # )

        private
       
        def pull_request?
          !key? "repository"
        end

        def tag?
          !pull_request? && self['ref'] =~ /^#{Regexp.escape 'refs/tags/'}/
        end

        def pull_request_number
          if pull_request? && key?("id")
            pull_request["number"]
          end
        end

        def sha
          if pull_request?
            pull_request["head"]["sha"]
          else
            self["after"]
          end
        end

        def branch
          if pull_request?
            pull_request["head"]["ref"]
          else
            self.params['commits'].last['branch']
          end
        end

        def branch_label
          branch
        end

        def web_url
          if pull_request?
            pull_request["html_url"]
          else
            head_commit["url"]
          end
        end

        def message
          if pull_request?
            commit_for_pull_request.message
          else
            head_commit["message"]
          end
        end

        def author
          if pull_request?
            commit_for_pull_request.author.name
          else
            head_commit? && head_commit["author"]["name"]
          end
        end

        def author_email
          if pull_request?
            commit_for_pull_request.author.email
          else
            head_commit? && head_commit["author"]["email"]
          end
        end

        def pull_request_head_repo_id
          if pull_request?
            pull_request['head']['repo']['id']
          end
        end

        def pull_request_base_repo_id
          if pull_request?
            pull_request['base']['repo']['id']
          end
        end

        def closed_pull_request?
          pull_request? && (pull_request["state"] == 'closed')
        end

        def foreign_pull_request?
          pull_request? && (pull_request_head_repo_id != pull_request_base_repo_id)
        end

        def ping_request?
          self["zen"].to_s.size > 0
        end

        def ignore?
          if pull_request?
            closed_pull_request? || !foreign_pull_request?
          elsif ping_request?
            true
          else
            sha == '0000000000000000000000000000000000000000' || tag?
          end
        end

        def commit_for_pull_request
          @commit_for_pull_request ||=
            begin
              data = session.commit pull_request["base"]["repo"]["full_name"], sha
              data.commit
            rescue ::Octokit::NotFound => e
              $stderr.puts "ERROR: #{e.inspect}"
              OpenStruct.new
            end
        end

        def head_commit?
          self["head_commit"]
        end

        def head_commit
          self["head_commit"] || {}
        end

        def pull_request
        	binding.pry
          self["pull_request"]
        end

        def key?(name)
          params.key? name
        end

        def [](val)
          params[val]
        end

      end
    end
  end
end
