require "spec_helper"

describe SolrDocument do
  it "should behave like a SolrDocument" do
    doc = SolrDocument.new(:id => "12345")
    doc.should be_a SolrDocument
    doc[:id].should == "12345"
    doc.should respond_to :export_formats
  end
  
  describe "catalog_heading" do
    it "should get the correct field based on the locale passed in" do
      doc = SolrDocument.new(:id => "12345", :catalog_heading_etsimv => ["Something -- Something English"], :catalog_heading_ftsimv => ["Something -- Something French"])
      en_heading = doc.catalog_heading(:en)
      fr_heading = doc.catalog_heading(:fr)
      en_heading.length.should == 1 
      fr_heading.length.should == 1
      en_heading.first.should include "Something English" and en_heading.first.should_not include "Something French"
      fr_heading.first.should include "Something French" and fr_heading.first.should_not include "Something English"
    end
    it "should split the catalog heading field on double dashes" do
      doc = SolrDocument.new(:id => "12345", :catalog_heading_etsimv => ["Something -- Something Else -- Yet Another thing"])
      heading = doc.catalog_heading(:en)
      heading.length.should == 1
      heading.first.length.should == 3
      ["Something", "Something Else", "Yet Another thing"].each do |phrase|
        heading.first.should include phrase
      end
    end
  end
  
  describe "images" do
    before(:all) do
      @images = SolrDocument.new({:image_id_ssm => ["abc123", "cba321"]}).images
    end
    it "should point to the test URL" do
      @images.each do |image|
        image.should include Frda::Application.config.stacks_url
      end
    end
    it "should link to the image identifier field " do
      @images.each do |image|
        image.should =~ /abc123|cba321/
      end
    end
    it "should have the proper default image dimension when no size is specified" do
      @images.each do |image|
        image.should =~ /#{SolrDocument.image_dimensions[:default]}/
      end
    end
    it "should return the requested dimension when one is specified" do
      SolrDocument.new({:image_id_ssm => ["abc123", "cba321"]}).images(:size=>:large).each do |image|
        image.should =~ /#{SolrDocument.image_dimensions[:large]}/
      end
    end
    it "should return [] when the document does not have an image identifier field" do
      SolrDocument.new(:id => "12345").images.should eq([])
    end
    describe "image dimensions" do
      it "should be a hash of configurations" do
        SolrDocument.image_dimensions.should be_a Hash
        SolrDocument.image_dimensions.should have_key :default
      end
    end
  end
  
  describe "spoken_text" do
    before(:all) do
      @speech = "1234-|-M. Dorizy-|-This is a speech by a person."
      @speech_bad = "M. Dorizy This is a speech by a person."
    end
    it "should parse the speech split on the appropriate delimiter" do
      speeches = SolrDocument.new({:spoken_text_ftsimv => [@speech]}, {}).spoken_text
      speeches.should be_a Array
      speeches.length.should == 1
      speeches.first.speaker.should == "M. Dorizy"
      speeches.first.text.should == "This is a speech by a person."
    end
    it "should be blank if the speech is unparsable" do
      speeches = SolrDocument.new({:spoken_text_ftsimv => [@speech_bad]}, {}).spoken_text
      speeches.should be_blank
    end
    it "should inform us if a speech has been highlighted" do
      hl_response = {'highlighting' => {'1234'=>{'spoken_text_ftsimv'=>["1234-|-M. Dorizy-|-This is a <em>speech</em> by a person."]}}}
      speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech]}, hl_response).spoken_text
      speeches.should be_a(Array)
      speeches.length.should == 1
      speeches.first.should be_highlighted
      speeches.first.text.should =~ /<em>/

      speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech]}, {}).spoken_text
      speeches.first.should_not be_highlighted
    end
    describe "highlighted_speeches" do
      it "should return only the highlighed speeches" do
        hl_response = {'highlighting' => {'1234'=>{'spoken_text_ftsimv'=>["1234-|-M. Dorizy-|-This is a <em>speech</em> by a person."]}}}
        speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech, @speech_bad]}, hl_response).highlighted_spoken_text
        speeches.should be_a Array
        speeches.length.should == 1
        speeches.first.should be_highlighted
        speeches.first.text.should =~ /<em>/
      end
      it "should return nil if no highlighting is available" do
        speeches = SolrDocument.new({:id => "1234", :spoken_text_ftsimv => [@speech, @speech_bad]}, {}).highlighted_spoken_text
        speeches.should be_nil
      end
    end
  end
  
  
  describe "mods" do
    before(:all) do
      @mods_doc = SolrDocument.new({:id => "12345", :mods_xml => "<?xml version='1.0'?><mods><note>This is the first note.</note><note>This is the second note.</note></mods>"})
      @no_mods_doc = SolrDocument.new({:id => "54321"})
    end
    it "should return a Nokogiri::XML::Document when mods_xml is available" do
      @mods_doc.mods.should be_a Nokogiri::XML::Document
    end
    it "should provide an easy API to the elements in the XML" do
      @mods_doc.mods.note.length.should == 2
      @mods_doc.mods.note.first.text.should == "This is the first note."
      @mods_doc.mods.note.last.text.should == "This is the second note."
    end
    it "should return nil in the absence of mods_xml" do
      @no_mods_doc.mods.should be_nil
    end
  end
  
end