# frozen_string_literal: true

require "spec_helper"

module Decidim::Meetings
  describe Admin::CreateMeeting do
    subject { described_class.new(form) }

    let(:organization) { create :organization, available_locales: [:en] }
    let(:current_user) { create :user, :admin, :confirmed, organization: organization }
    let(:participatory_process) { create :participatory_process, organization: organization }
    let(:current_component) { create :component, participatory_space: participatory_process, manifest_name: "meetings" }
    let(:scope) { create :scope, organization: organization }
    let(:category) { create :category, participatory_space: participatory_process }
    let(:address) { "address" }
    let(:invalid) { false }
    let(:latitude) { 40.1234 }
    let(:longitude) { 2.1234 }
    let(:start_time) { 1.day.from_now }
    let(:private_meeting) { false }
    let(:transparent) { true }
    let(:transparent_type) { "transparent" }
    let(:type_of_meeting) { "online" }
    let(:online_meeting_url) { "http://decidim.org" }
    let(:registration_url) { "http://decidim.org" }
    let(:registration_type) { "on_this_platform" }
    let(:available_slots) { 0 }
    let(:show_iframe) { true }
    let(:services) do
      [
        {
          "title" => { "en" => "First service" },
          "description" => { "en" => "First description" }
        },
        {
          "title" => { "en" => "Second service" },
          "description" => { "en" => "Second description" }
        }
      ]
    end
    let(:services_to_persist) do
      services.map { |service| Admin::MeetingServiceForm.from_params(service) }
    end
    let(:customize_registration_email) { true }
    let(:registration_email_custom_content) { { "en" => "The registration email custom content." } }

    let(:form) do
      double(
        invalid?: invalid,
        title: { en: "title" },
        description: { en: "description" },
        location: { en: "location" },
        location_hints: { en: "location_hints" },
        start_time: start_time,
        end_time: 1.day.from_now + 1.hour,
        address: address,
        latitude: latitude,
        longitude: longitude,
        scope: scope,
        category: category,
        private_meeting: private_meeting,
        transparent: transparent,
        services_to_persist: services_to_persist,
        current_user: current_user,
        current_component: current_component,
        current_organization: organization,
        registration_type: registration_type,
        available_slots: available_slots,
        registration_url: registration_url,
        clean_type_of_meeting: type_of_meeting,
        online_meeting_url: online_meeting_url,
        customize_registration_email: customize_registration_email,
        registration_email_custom_content: registration_email_custom_content,
        show_iframe: show_iframe
      )
    end

    context "when the form is not valid" do
      let(:invalid) { true }

      it "is not valid" do
        expect { subject.call }.to broadcast(:invalid)
      end
    end

    context "when everything is ok" do
      let(:meeting) { Meeting.last }

      it "creates the meeting" do
        expect { subject.call }.to change(Meeting, :count).by(1)
      end

      it "sets the scope" do
        subject.call
        expect(meeting.scope).to eq scope
      end

      it "sets the category" do
        subject.call
        expect(meeting.category).to eq category
      end

      it "sets the author" do
        subject.call
        expect(meeting.author).to eq organization
      end

      it "sets the component" do
        subject.call
        expect(meeting.component).to eq current_component
      end

      it "sets the longitude and latitude" do
        subject.call
        last_meeting = Meeting.last
        expect(last_meeting.latitude).to eq(latitude)
        expect(last_meeting.longitude).to eq(longitude)
      end

      it "sets the services" do
        subject.call

        meeting.services.each_with_index do |service, index|
          expect(service.title).to eq(services[index]["title"])
          expect(service.description).to eq(services[index]["description"])
        end
      end

      it "sets the questionnaire for registrations" do
        subject.call
        expect(meeting.questionnaire).to be_a(Decidim::Forms::Questionnaire)
      end

      it "sets the registration email related fields" do
        subject.call

        expect(meeting.customize_registration_email).to be true
        expect(meeting.registration_email_custom_content).to eq(registration_email_custom_content)
      end

      it "is created as unpublished" do
        subject.call

        expect(meeting).not_to be_published
      end

      it "sets show_iframe" do
        subject.call

        expect(meeting).to be_show_iframe
      end

      it "traces the action", versioning: true do
        expect(Decidim.traceability)
          .to receive(:create!)
          .with(Meeting, current_user, kind_of(Hash), visibility: "all")
          .and_call_original

        expect { subject.call }.to change(Decidim::ActionLog, :count)
        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
      end
    end
  end
end
