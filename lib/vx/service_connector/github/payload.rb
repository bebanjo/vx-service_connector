require 'ostruct'

module Vx
  module ServiceConnector
    class Github
      Payload = Struct.new(:session, :params) do

        def build
          ServiceConnector::Model::Payload.new(
            !!ignore?,
            !!pull_request,
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

        private

        def pull_request?
          key? "pull_request"
        end

        def tag?
          !pull_request? && self['ref'] =~ /^#{Regexp.escape 'refs/tags/'}/
        end

        def pull_request_number
          if pull_request? && key?("number")
            self["number"]
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
            self["ref"].to_s.split("refs/heads/").last
          end
        end

        def branch_label
          if pull_request?
            pull_request["head"]["label"]
          else
            branch
          end
        end

        def web_url
          if pull_request?
            pull_request["html_url"]
          else
            head_commit["url"]
          end
        end

        def commit
          if pull_request?
            commit_for_pull_request
          else
            head_commit
          end
        end

        def message
          commit["message"]
        end

        def author?
          commit && commit["author"]
        end

        def author
          author? && commit["author"]["name"]
        end

        def author_email
          author? && commit["author"]["email"]
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

        def ci_skip?
          commits? && self['commits'].all?{ |commit| CommitCommand.new(commit["message"]).skip? }
        end

        def commits?
          key? 'commits'
        end

        def ignore?
          if pull_request?
            closed_pull_request? || !foreign_pull_request?
          else
            sha == '0000000000000000000000000000000000000000' || tag? || ci_skip?
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
          self["pull_request"]
        end

        def key?(name)
          params.key? name
        end

        def [](val)
          params[val]
        end

        class CommitCommand
          def initialize(message)
            @message = message.to_s
          end

          def skip?
            backwards_skip or command == 'skip'
          end

          private
          attr_reader :message

          def command
            message =~ /\[ci(?: |:)([\w ]*)\]/i && $1.downcase
          end

          def backwards_skip
            message =~ /\[skip\s+ci\]/i && true
          end
        end
      end

    end
  end
end
