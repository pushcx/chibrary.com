require_relative '../rspec'
require_relative '../../web/helper/thread_helper'
require_relative '../../web/helper/application_helper'

describe 'Thread Helper' do
  describe "#message_body" do
    # it is untested because it just calls all the others
  end

  describe "#html_caps" do
    it "marks up abbreviations as caps" do
      expect(html_caps("IBM")).to eq('<span class="caps">IBM</span>')
    end

    it "does not mark up caps in the middle of words" do
      expect(html_caps("fooIBMbar")).to eq('fooIBMbar')
    end
  end

  describe "#remove_footer" do
    it "strips a list's footer off the str" do
      body   = "body text\n"
      footer = "\n---\nmailing list footer"

      str = remove_footer(body + footer, double('list', footer: footer))
      expect(str).to eq(body.strip)
    end
  end

  describe "#compress_quotes" do
    it "marks up a variety of quoting styles" do
      YAML::load_file('spec/fixture/quoting.yaml').each do |name, quote|
        expect(compress_quotes(f(quote['input']))).to eq(quote['expect']), "Testcase: #{name}"
      end
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
