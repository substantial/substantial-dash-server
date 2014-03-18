require 'spec_helper'
require 'pipedrive_deals'
require 'fake_http_response'

describe PipedriveDeals do
  subject { PipedriveDeals.new }
  let(:filter_data) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'pipedrive', 'filter.json')) }
  let(:filters_data) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'pipedrive', 'filters.json')) }
  let(:pipelines_data) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'pipedrive', 'pipelines.json')) }
  let(:deals_data) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'pipedrive', 'deals.json')) }
  let(:stages_data) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'pipedrive', 'stages.json')) }
  let(:deals) { JSON.parse(deals_data)['data'] }
  let(:filters) { JSON.parse(filters_data)['data'] }
  let(:filter) { JSON.parse(filter_data)['data'] }
  let(:stages) { JSON.parse(stages_data)['data'] }
  let(:pipelines) { JSON.parse(pipelines_data)['data'] }
  let(:filter_names) { 'SF'.split(',')[0] }

  before do
    ENV.stub(:[]).with('INTAKE_PIPEDRIVE_API_URL').and_return('http://www.meow.com')
    ENV.stub(:[]).with('INTAKE_PIPEDRIVE_API_TOKEN').and_return('woof')
    ENV.stub(:[]).with('INTAKE_PIPEDRIVE_FILTER_NAMES').and_return(filter_names)
    ENV.stub(:[]).with('INTAKE_PIPEDRIVE_PIPELINE_NAME').and_return('Sales Pipeline')
  end

  describe '#initialize' do
    it 'returns a new PipedriveDeals' do
      expect(PipedriveDeals.new).to be_kind_of(PipedriveDeals)
    end
  end

  describe '#find person conditions in valid input' do
    let(:returns) { subject.find_conditions_by_object_type(filter, 'person') }

    it 'returns an array' do
      expect(returns).to be_kind_of(Array)
    end

    it 'returns 2 conditions' do
      expect(returns.size).to eq(2)
    end
  end

  describe '#find no conditions when none in input' do
    let(:returns) { subject.find_conditions_by_object_type(filter, 'meowmeow') }

    it 'returns an empty array' do
      expect(returns).to be_kind_of(Array)
      expect(returns.size).to eq(0)
    end
  end

  describe '#find pipeline by name' do
    let(:response) { FakeHttpResponse.new('200', pipelines_data) }
    before { Net::HTTP.stub(:start).and_return(response) }
    let(:pipeline_name) { 'Sales Pipeline' }
    let(:returns) { subject.get_pipeline(pipeline_name) }

    it 'should return a the right pipeline' do
      expect(returns).to be_kind_of(Hash)
      expect(returns['name']).to eq(pipeline_name)
    end

    it 'passes proper URL fragment' do
      subject.should_receive(:data_from_uri).with('pipelines')
      subject.get_pipeline('blah')
    end

    it 'handles invalid input well' do
      expect{ subject.get_pipeline(nil) }.to_not raise_error
    end
  end

  describe '#get deals in pipeline' do
    let(:response) { FakeHttpResponse.new('200', deals_data) }
    before { Net::HTTP.stub(:start).and_return(response) }
    let(:pipeline_id) { 1 }

    it 'passes proper URL fragment' do
      subject.should_receive(:data_from_uri).with("pipelines/#{pipeline_id}/deals")
      subject.get_pipeline_deals(pipeline_id)
    end
  end

  describe '#get stages for pipeline' do
    let(:response) { FakeHttpResponse.new('200', stages_data) }
    before { Net::HTTP.stub(:start).and_return(response) }
    let(:pipeline_id) { 1 }

    it 'passes proper URL fragment' do
      subject.should_receive(:data_from_uri).with('stages')
      subject.pipeline_stages(pipeline_id)
    end

    it 'handles bad response without error' do
      PipedriveDeals.any_instance.stub(:data_from_uri).with('stages').and_return(nil)
      expect{subject.pipeline_stages(pipeline_id)}.to_not raise_error
    end

    it 'only selects stages for given pipeline' do
      # 5 stages in the pipeline; set active_flag of one of them to false,
      # to make sure that stage is  skipped
      stages[0]['active_flag'] = false
      PipedriveDeals.any_instance.stub(:data_from_uri).with('stages').and_return(stages)
      stages = subject.pipeline_stages(pipeline_id)
      expect(stages.size).to eq(4)
    end
  end

  describe '#filter pipeline deals' do
    before do
      PipedriveDeals.any_instance.stub(:data_from_uri).with('filters').and_return(filters)
      PipedriveDeals.any_instance.stub(:data_from_uri).with('filters/14').and_return(filter)
    end

    it 'should filter deals according to the filter' do
      returns = subject.filter_pipeline_deals(deals, filter_names)
      expect(returns.size).to eq(3)
    end

    it 'should return all deals if filter name is empty' do
      empty_filter_names = ''
      filtered_deals = subject.filter_pipeline_deals(deals, empty_filter_names )
      expect(filtered_deals.size).to eq(5)
    end

    it 'should return all deals if pipedrive API returns no filters' do
      PipedriveDeals.any_instance.stub(:data_from_uri).with('filters').and_return([])
      filtered_deals = subject.filter_pipeline_deals(deals, filter_names)
      expect(filtered_deals.size).to eq(5)
    end
  end

  describe '#export' do
    let(:unfiltered_deals) { deals.reject { |deal| deal['status'] != 'open' } }
    let(:filtered_deals) { deals.reject { |deal| (deal['status'] != 'open' || (deal['user_id'] != 158906 && deal['user_id'] != 161873)) } }
    before do
      PipedriveDeals.any_instance.stub(:data_from_uri).with('stages').and_return(stages)
    end
    let(:pipeline_stages) { subject.pipeline_stages(1).reverse! }
    let(:returns) { subject.export(pipeline_stages, 'Substantial', filter_names[0], unfiltered_deals, filtered_deals) }

    it 'returns an array' do
      expect(:returns).is_a?(Array)
    end

    it 'sorts output as per stages` order_nr property' do
      pipeline_stages.sort! { |x,y| x['order_nr'] <=> y['order_nr'] }
      pipeline_stages.each_with_index do |val, i|
        expect(returns[i][:name]).to eq(val['name'])
      end
    end

    it 'adds up dollar values properly for filtered data' do
      expect(returns.detect{ |v| v[:name] == 'Opportunity' }[:datasets][0][:dollar_value]).to eq(10000)
      expect(returns.detect{ |v| v[:name] == 'Qualified' }[:datasets][0][:dollar_value]).to eq(150000)
      expect(returns.detect{ |v| v[:name] == 'Pursuing' }[:datasets][0][:dollar_value]).to eq(0)
      expect(returns.detect{ |v| v[:name] == 'Proposed' }[:datasets][0][:dollar_value]).to eq(0)
      expect(returns.detect{ |v| v[:name] == 'In Negotiation' }[:datasets][0][:dollar_value]).to eq(0)
    end

    it 'adds up dollar values properly for unfiltered data' do
      expect(returns.detect{ |v| v[:name] == 'Opportunity' }[:datasets][1][:dollar_value]).to eq(10000)
      expect(returns.detect{ |v| v[:name] == 'Qualified' }[:datasets][1][:dollar_value]).to eq(150000)
      expect(returns.detect{ |v| v[:name] == 'Pursuing' }[:datasets][1][:dollar_value]).to eq(0)
      expect(returns.detect{ |v| v[:name] == 'Proposed' }[:datasets][1][:dollar_value]).to eq(551250)
      expect(returns.detect{ |v| v[:name] == 'In Negotiation' }[:datasets][1][:dollar_value]).to eq(0)
    end

    it 'adds up deal count properly for filtered data' do
      expect(returns.detect{ |v| v[:name] == 'Opportunity' }[:datasets][0][:deal_count]).to eq(1)
      expect(returns.detect{ |v| v[:name] == 'Qualified' }[:datasets][0][:deal_count]).to eq(2)
      expect(returns.detect{ |v| v[:name] == 'Pursuing' }[:datasets][0][:deal_count]).to eq(0)
      expect(returns.detect{ |v| v[:name] == 'Proposed' }[:datasets][0][:deal_count]).to eq(0)
      expect(returns.detect{ |v| v[:name] == 'In Negotiation' }[:datasets][0][:deal_count]).to eq(0)
    end

    it 'adds up deal count properly for unfiltered data' do
      expect(returns.detect{ |v| v[:name] == 'Opportunity' }[:datasets][1][:deal_count]).to eq(1)
      expect(returns.detect{ |v| v[:name] == 'Qualified' }[:datasets][1][:deal_count]).to eq(2)
      expect(returns.detect{ |v| v[:name] == 'Pursuing' }[:datasets][1][:deal_count]).to eq(0)
      expect(returns.detect{ |v| v[:name] == 'Proposed' }[:datasets][1][:deal_count]).to eq(1)
      expect(returns.detect{ |v| v[:name] == 'In Negotiation' }[:datasets][1][:deal_count]).to eq(0)
    end

    it 'exports two datasets for each stage' do
      returns.each { |stage| expect(stage[:datasets].size).to eq(2) }
    end
  end

  describe '#intake' do
    before do
      PipedriveDeals.any_instance.stub(:data_from_uri).with('stages').and_return(stages)
      PipedriveDeals.any_instance.stub(:data_from_uri).with('filters').and_return(filters)
      PipedriveDeals.any_instance.stub(:data_from_uri).with('filters/14').and_return(filter)
      PipedriveDeals.any_instance.stub(:data_from_uri).with('pipelines').and_return(pipelines)
      PipedriveDeals.any_instance.stub(:data_from_uri).with('pipelines/1/deals').and_return(deals)
    end
    let(:returns) { subject.intake }

    it 'returns correct amount of items' do
      expect(returns.size).to eq(5)
    end
  end
end
