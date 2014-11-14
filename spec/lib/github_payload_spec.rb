require 'spec_helper'

describe Vx::ServiceConnector::Github::Payload do

  include GithubWebMocks

  let(:content) { read_json_fixture("github/payload/push") }
  let(:github)  { Vx::ServiceConnector::Github.new 'login', 'token' }
  let(:repo)    { create :repo }
  let(:payload) { github.payload repo, content }
  subject { payload }

  context "ping" do
    let(:content) { read_json_fixture 'github/payload/ping'  }
    it { should be_ignore }
  end

  context "push" do
    let(:url) { "https://github.com/evrone/ci-worker-test-repo/commit/687753389908e70801dd4ff5448be908642055c6"  }

    it { should_not be_ignore }

    its(:pull_request?)       { should be_falsey }
    its(:pull_request_number) { should be_nil }
    its(:sha)                 { should eq '84158c732ff1af3db9775a37a74ddc39f5c4078f' }
    its(:branch)              { should eq 'master' }
    its(:branch_label)        { should eq 'master' }
    its(:message)             { should eq 'test commit #3' }
    its(:author)              { should eq 'Dmitry Galinsky' }
    its(:author_email)        { should eq 'dima.exe@gmail.com' }
    its(:web_url)             { should eq url }
    its(:tag)                 { should be_nil }
  end

  context "internal pull_request" do
    let(:content) { read_json_fixture("github/payload/pull_request") }
    let(:url)     { "https://github.com/evrone/cybergifts/pull/177" }
    let(:sha)     { '84158c732ff1af3db9775a37a74ddc39f5c4078f' }

    before do
      mock_get_commit 'evrone/cybergifts', sha
    end

    its(:pull_request?)         { should be_truthy }
    its(:foreign_pull_request?) { should be_falsey }
    its(:internal_pull_request?){ should be_truthy }
    its(:pull_request_number)   { should eq 177 }
    its(:sha)                   { should eq sha }
    its(:branch)                { should eq 'test' }
    its(:branch_label)          { should eq 'dima-exe:test' }
    its(:message)               { should eq 'Fix all the bugs' }
    its(:author)                { should eq 'Monalisa Octocat' }
    its(:author_email)          { should eq 'support@github.com' }
    its(:web_url)               { should eq url }
    its(:ignore?)               { should be_falsey }
  end

  context "push tag" do
    let(:content) { read_json_fixture("github/payload/push_tag") }
    it { should_not be_pull_request }
    it { should_not be_ignore }
    it { should be_tag }
    its(:tag) { should eq 'v0.0.1' }
  end

  context "closed pull request" do
    let(:content) { read_json_fixture("github/payload/closed_pull_request") }

    before do
      mock_get_commit 'evrone/cybergifts', '84158c732ff1af3db9775a37a74ddc39f5c4078f'
    end

    it { should be_pull_request }
    its(:ignore?) { should be_truthy }
  end

  context "foreign pull request" do
    let(:content) { read_json_fixture("github/payload/foreign_pull_request") }

    before do
      mock_get_commit 'evrone/serverist-email-provider', 'f57c385116139082811442ad48cb6127c29eb351'
    end

    it { should be_pull_request }
    it { should_not be_internal_pull_request }
    it { should be_foreign_pull_request }
    it { should_not be_ignore }
  end

  context "[skip ci] on all pushed commits" do
    let(:content) { read_json_fixture("github/payload/push_ci_skip") }
    its(:ignore?) { should be_truthy }
  end

  context "missing commits on pushed parameters" do
    let(:content) { read_json_fixture("github/payload/push").tap{ |hash| hash.delete('commits') }}
    its(:ignore?) { should be_falsey }
  end

  context "empty commits on pushed parameters" do
    let(:content) { read_json_fixture("github/payload/push").tap{ |hash| hash['commits'] = [] }}
    its(:ignore?) { should be_falsey }
  end

end
