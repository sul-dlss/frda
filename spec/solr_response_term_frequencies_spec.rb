require "spec_helper"

class TestTermFrequency < HashWithIndifferentAccess
  include SolrResponseTermFrequencies
end

describe SolrResponseTermFrequencies do
  before(:all) do
    @single = { :debug => {
                  :explain => {
                    "1234" => "(MATCH) weight(text_tiv:paris^1.0) score(maxDocs=1234 termFreq=5.0)"
                  }
                }
              }
    @phrase = { :debug => {
                  :explain => {
                    "1234" => "(MATCH) weight(text_tiv:paris^1.0) score(maxDocs=1234 phraseFreq=5.0)"
                  }
                }
              }
    @multi_doc = { :debug => {
                     :explain => {
                       "1234" => "(MATCH) weight(text_tiv:paris^1.0) score(maxDocs=1234 termFreq=5.0)",
                       "4321" => "(MATCH) weight(text_tiv:paris^1.0) score(maxDocs=1234 termFreq=6.0)"
                     }
                   }
                 }
    @multi_freq = { :debug => {
                      :explain => {
                        "1234" => 'SomeText (MATCH) weight(text_tiv:paris^1.0) score(maxDocs=1234 termFreq=5.0)  Some Other Text (MATCH) weight(text_tiv:france^1.0) score(maxDocs=1234 termFreq=6.0)  Even More Text (MATCH) weight(text_tiv:"paris france"^1.0) score(maxDocs=1234 termFreq=5.0)'
                      }
                    }
                  }
    @several_words = { :debug => {
                         :explain => {
                           "1234" => 'SomeText (MATCH) weight(text_tiv:this^1.0) score(maxDocs=1234 termFreq=5.0)  
                                      Some Other Text (MATCH) weight(text_tiv:is^1.0) score(maxDocs=1234 termFreq=6.0)  
                                      Even More Text (MATCH) weight(text_tiv:a^1.0) score(maxDocs=1234 termFreq=5.0)
                                      More Text (MATCH) weight(text_tiv:several^1.0) score(maxDocs=1234 termFreq=5.0)
                                      Some More Text (MATCH) weight(text_tiv:word^1.0) score(maxDocs=1234 termFreq=5.0)
                                      Even More TextAgain (MATCH) weight(text_tiv:query^1.0) score(maxDocs=1234 termFreq=5.0)
                                      More Text (MATCH) weight(text_tiv:"this is a several word query"^1.0) score(maxDocs=1234 termFreq=1.0)'
                         }
                       }
                     }
  end
  it "should return a hash of term frequencies" do
    expect(TestTermFrequency.new(@single).term_frequencies).to be_a Hash
  end
  it "should have a key for every document in the explain section" do
    expect(TestTermFrequency.new(@single).term_frequencies.keys).to eq(["1234"])
    expect(TestTermFrequency.new(@multi_doc).term_frequencies.keys).to eq(["1234", "4321"])
  end
  it "should handle multi-word frequency responses" do
    freq = TestTermFrequency.new(@multi_freq).term_frequencies
    expect(freq).to be_a Hash
    expect(freq["1234"]).to be_a Array
    expect(freq["1234"].length).to eq(3)
    [{:word => "paris", :frequency => "5"}, {:word=>"france", :frequency=>"6"}, {:word=>'"paris france"', :frequency=>"5"}].each do |word|
      expect(freq["1234"]).to include word
    end
  end
  it "should handle phrase frequency when it is available" do
    freq = TestTermFrequency.new(@phrase).term_frequencies
    expect(freq).to be_a Hash
    expect(freq["1234"]).to be_a Array
    expect(freq["1234"].length).to eq(1)
    expect(freq["1234"].first).to eq({:word => "paris", :frequency => "5"})
  end
  it "should handle several word queries correctly" do
    freq = TestTermFrequency.new(@several_words).term_frequencies
    expect(freq["1234"].length).to eq(7)
    expect(freq["1234"]).to include({ :word => '"this is a several word query"', :frequency => "1"})
  end
end
