require_relative '../rspec'
require_relative '../../web/helper/thread_helper'
require_relative '../../web/helper/application_helper'

describe 'Thread Helper' do
  it "#message_body" do
    # This is kind of a dumb brittle test
    self.should_receive(:remove_footer).and_return("body text")
    self.should_receive(:f).and_return("body text")
    self.should_receive(:compress_quotes).and_return("body text")
    message_body(double(slug: 'example', body: "body text", list: 'list'))
  end

  it "#remove_footer" do
    body   = "body text\n"
    footer = "\n---\nmailing list footer"

    str = remove_footer(body + footer, double('list', footer: footer))
    expect(str).to eq(body.strip)
  end

  it "#compress_quotes" do
    YAML::load_file('spec/fixture/quoting.yaml').each do |name, quote|
      expect(compress_quotes(f(quote['input']))).to eq(quote['expect']), "Testcase: #{name}"
    end
  end

  describe "#container_partial" do
    it "renders messages" do
      mock_message = double('message', no_archive: false )

      container = double("container", message: mock_message, empty?: false, root?: true, children: [])

      self.should_receive(:partial).with('thread/_message.html', locals: { message: mock_message, parent: nil, children: [] })
      container_partial(container)
    end

    it "renders missing messages" do
      empty_container = double('empty_container', empty?: true)
      self.should_receive(:partial).with('thread/_message_missing.html')
      container_partial(empty_container)
    end

    it "renders no_archive messages" do
      no_archive_container = double('no_archive container', empty?: false, message: double(no_archive: true))
      self.should_receive(:partial).with('thread/_message_no_archive.html')
      container_partial(no_archive_container)
    end
  end
end
