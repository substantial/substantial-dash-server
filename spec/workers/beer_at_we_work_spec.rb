require 'spec_helper'
require 'pipedrive_deals'
require 'fake_http_response'

describe BeerAtWeWork do
  subject { BeerAtWeWork.new }
  let(:beer_data) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'beers.json')) }
  let(:beers) { JSON.parse(beer_data) }

  describe '#initialize' do
    it 'returns a new BeetAtWeWork' do
      expect(subject).to be_kind_of(BeerAtWeWork)
    end
  end

  describe '#intake' do
    before { BeerAtWeWork.any_instance.stub(:get_beer_data).and_return(beers) }

    it 'sorts beers by floor in descending order' do
      output = subject.intake
      expect(output[2]['floor']).to be > output[3]['floor']
    end
  end
end