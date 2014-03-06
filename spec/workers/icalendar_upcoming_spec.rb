require 'spec_helper'

describe IcalendarUpcoming do
  subject { IcalendarUpcoming.new }
  let(:ics_data) { File.read(File.join(Rails.root, "spec", "fixtures", "recurring.ics")) }

  let(:now) { Time.parse("2014-03-06 10:02:33 -0800") }
  before do
    Timecop.freeze(now)
  end
  after do
    Timecop.return
  end

  describe "#initialize" do
    it "returns a new IcalendarUpcoming" do
      expect(IcalendarUpcoming.new).to be_kind_of(IcalendarUpcoming)
    end
  end

  describe "#intake" do

    class FakeResponse
      def initialize(code, body)
        @code = code
        @body = body
      end
      def code
        @code
      end
      def body
        @body
      end
    end
    
    let(:response) { FakeResponse.new("200", ics_data) }
    before { Net::HTTP.stub(:start).and_return(response) }
    let(:returns) { subject.intake }

    it "returns events" do
      expect( returns.all? {|ev| RiCal::Component::Event === ev } ).to be_true
    end
  end

  describe "#parse_calendar" do
    it "returns a calendar" do
      expect(subject.parse_calendar(ics_data)).to be_kind_of(RiCal::Component::Calendar)
    end
  end

  describe "#upcoming_events" do
    let(:calendar) { subject.parse_calendar(ics_data) }
    let(:events) { subject.upcoming_events(calendar) }

    it "returns events" do
      expect( events.all? {|ev| RiCal::Component::Event === ev } ).to be_true
    end
    
    it "filters out past events" do
      expect( events.all? {|ev| ev.dtstart > now } ).to be_true
    end
    
    it "sorts chronologically" do
      is_chronological = true
      events.each_with_index do |event, i|
        next if i==0
        previous = events[i-1]
        if previous.dtstart > event.dtstart
          is_chronological= false
          break
        end
      end
      expect(is_chronological).to be_true
    end

    it "limits number of recurrences" do
      happy_hours = events.select {|event| event.summary == "Substantial SF Weekly Happy Hour!"}
      expect(happy_hours.size).to equal(IcalendarUpcoming::EVENT_COUNT_LIMIT)
    end

    it "ignores pre-generated recurrences" do
      stand_ups = events.select {|event| event.summary == "SF Standup"}
      expect(stand_ups.size).to equal(IcalendarUpcoming::EVENT_COUNT_LIMIT)
    end
  end

end
